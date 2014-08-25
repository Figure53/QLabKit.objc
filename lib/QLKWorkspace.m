//
//  QLKWorkspace.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2014 Figure 53 LLC, http://figure53.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#import "QLKWorkspace.h"
#import "QLKCue.h"
#import "QLKServer.h"
#import "QLKClient.h"
#import "F53OSC.h"

#define HEARTBEAT_INTERVAL 5          // seconds
#define HEARTBEAT_FAILURE_INTERVAL 1  // seconds
#define HEARTBEAT_MAX_ATTEMPTS 5

#define DEBUG_OSC 0

NSString * const QLKWorkspaceDidUpdateCuesNotification = @"QLKWorkspaceDidUpdateCuesNotification";
NSString * const QLKWorkspaceDidConnectNotification = @"QLKWorkspaceConnectionDidConnectNotification";
NSString * const QLKWorkspaceDidDisconnectNotification = @"QLKWorkspaceConnectionDidDisconnectNotification";
NSString * const QLKWorkspaceConnectionErrorNotification = @"QLKWorkspaceTimeoutNotification";
NSString * const QLKWorkspaceDidChangePlaybackPositionNotification = @"QLKWorkspaceDidChangePlaybackPositionNotification";

@interface QLKWorkspace ()

@property (strong, readonly) QLKClient *client;
@property (strong) NSTimer *heartbeatTimeout;
@property (assign) NSInteger attempts;

- (void) startHeartbeat;
- (void) stopHeartbeat;
- (void) clearHeartbeatTimeout;
- (void) sendHeartbeat;
- (void) heartbeatTimeout:(NSTimer *)timer;

@end

@implementation QLKWorkspace

- (id) init
{
    self = [super init];
    if ( !self )
        return nil;

    _uniqueId = @"";
    _connected = NO;
    _attempts = 0;

    // Setup root cue - parent of cue lists
    _root = [[QLKCue alloc] initWithWorkspace:self];
    [self.root setProperty:QLKRootCueIdentifier
                    forKey:QLKOSCUIDKey
               tellQLab:NO];
    [self.root setProperty:@"Cue Lists"
                    forKey:QLKOSCNameKey
               tellQLab:NO];
    [self.root setProperty:QLKCueTypeGroup
                    forKey:QLKOSCTypeKey
               tellQLab:NO];

    _hasPasscode = NO;
    _defaultSendUpdatesOSC = NO;

    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict server:(QLKServer *)server
{
    self = [self init];
    if ( !self )
        return nil;

    _name = dict[@"displayName"];
    _serverName = server.name;
    _client = [[QLKClient alloc] initWithHost:server.host port:server.port];
    _client.useTCP = YES;
    _client.delegate = self;
    _uniqueId = dict[QLKOSCUIDKey];
    _hasPasscode = [dict[@"hasPasscode"] boolValue];

    return self;
}

- (void) dealloc
{
    self.client.delegate = nil;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ - %@ : %@", [super description], self.name, self.uniqueId];
}

- (NSString *) fullName
{
    return [NSString stringWithFormat:@"%@ (%@)", self.name, self.serverName];
}

- (NSString *) fullNameWithCueList:(QLKCue *)cueList
{
    return [NSString stringWithFormat:@"%@ - %@ (%@)", self.name, [cueList propertyForKey:QLKOSCNameKey], self.serverName];
}

#pragma mark - Connection/reconnection

- (void) connect
{
    [self connectWithPasscode:nil completion:nil];
}

- (void) connectWithPasscode:(NSString *)passcode completion:(QLKMessageHandlerBlock)block;
{
    if ( !self.connected && ![self.client connect] )
    {
        NSLog(@"[workspace] *** Error: couldn't connect to server");
        // Notify that we are unable to connect to workspace
        [self notifyAboutConnectionError];
        if ( block )
            block(@"error");
        return;
    }
	
    // Save passcode for automatic reconnection
    if ( passcode )
    {
        self.passcode = passcode;
    }
  
    // Tell QLab we're connecting
    [self.client sendMessageWithArgument:passcode toAddress:@"/connect" block:^(id data) {
        if ( !passcode || (passcode && [data isEqualToString:@"ok"]) )
            [self finishConnection];
        else
            [self disconnect];

        if ( block )
            block( data );
    }];
}

// Called when a connection is successfully made
- (void) finishConnection
{
    self.connected = YES;
    [self startReceivingUpdates];
    [self fetchCueLists];
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidConnectNotification object:self];
}

- (void) disconnect
{
    NSLog( @"[workspace] disconnect: %@", self.name );
    [self disconnectFromWorkspace];
    [self stopReceivingUpdates];
    self.connected = NO;
    [self.client disconnect];
    [self.root setProperty:[NSNull null]
                    forKey:QLKOSCCuesKey
               tellQLab:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidDisconnectNotification object:self];
}

// Reconnect when app wakes from sleep
- (void) reconnect
{
    NSLog( @"[workspace] reconnecting..." );

    // Try to use some password as before
    [self connectWithPasscode:self.passcode completion:^(id data) {
        NSLog( @"[workspace] reconnect response: %@", data );
        if ( [data isEqualToString:@"ok"] )
        {
            NSLog( @"[workspace] reconnected successfully: %@", data );
            [self finishConnection];
        }
        else
        {
            NSLog( @"[workspace] error reconnecting" );
            [self notifyAboutConnectionError];
        }
    }];
}

// Temporary disconnect when going to sleep
- (void) temporarilyDisconnect
{
    NSLog(@"[workspace] temp disconnect");
    [self disconnectFromWorkspace];
    [self stopHeartbeat];
    [self stopReceivingUpdates];

    [self.client disconnect];
    self.connected = NO;
}

- (void) notifyAboutConnectionError
{
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceConnectionErrorNotification object:self];
}

#pragma mark - Cues

- (QLKCue *) firstCue
{
    return [[self firstCueList] firstCue];
}

- (QLKCue *) firstCueList
{
    return [self.root firstCue];
}

- (QLKCue *) cueWithId:(NSString *)uid
{
    return [self.root cueWithId:uid];
}

- (QLKCue *)cueWithNumber:(NSString *)number {
    return [self.root cueWithNumber:number];
}

#pragma mark - Workspace Methods

- (void) disconnectFromWorkspace
{
    [self.client sendMessageWithArgument:nil toAddress:@"/disconnect"];
}

- (void) startReceivingUpdates
{
    [self.client sendMessageWithArgument:@YES toAddress:@"/updates"];
}

- (void) stopReceivingUpdates
{
    [self.client sendMessageWithArgument:@NO toAddress:@"/updates"];
}

- (void) enableAlwaysReply
{  
    [self.client sendMessagesWithArguments:@[@YES] toAddress:@"/alwaysReply" workspace:NO block:nil];
}

- (void) disableAlwaysReply
{
    [self.client sendMessagesWithArguments:@[@NO] toAddress:@"/alwaysReply" workspace:NO block:nil];
}

- (void) fetchCueLists
{
    [self fetchCueListsWithCompletion:^(NSArray *cueLists) {
        NSMutableArray *children = [NSMutableArray array];

        for ( NSDictionary *cueList in cueLists )
        {
            QLKCue *cue = [[QLKCue alloc] initWithDictionary:cueList workspace:self];
            [children addObject:cue];
        }

        // Manually add active cues list to root
        QLKCue *activeCues = [[QLKCue alloc] initWithWorkspace:self];
        [activeCues setProperty:QLKActiveCueListIdentifier
                         forKey:QLKOSCUIDKey
                    tellQLab:NO];
        [activeCues setProperty:@"Active Cues"
                         forKey:QLKOSCNameKey
                    tellQLab:NO];
        [activeCues setProperty:QLKCueTypeGroup
                         forKey:QLKOSCTypeKey
                    tellQLab:NO];
        [children addObject:activeCues];

        [self.root setProperty:children
                        forKey:QLKOSCCuesKey
                   tellQLab:NO];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidUpdateCuesNotification object:self];
        });
    }];
}

- (void) fetchCueListsWithCompletion:(QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:nil toAddress:@"/cueLists" block:block];
}

- (void) fetchPlaybackPositionForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:QLKOSCPlaybackPositionIdKey] block:block];
}

- (void) go
{
    [self.client sendMessageWithArgument:nil toAddress:@"/go"];
}

- (void) stopAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/stop"];
}

- (void) save
{
    [self.client sendMessageWithArgument:nil toAddress:@"/save"];
}

#pragma mark - Heartbeat

// Send heartbeat every 5 seconds (HEARTBEAT_INTERVAL)
- (void) startHeartbeat
{
    self.attempts = 0;
    [self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:HEARTBEAT_INTERVAL];
}

- (void) stopHeartbeat
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
    [self clearHeartbeatTimeout];
}

- (void) clearHeartbeatTimeout
{
    self.attempts = 0;
    [self.heartbeatTimeout invalidate];
    self.heartbeatTimeout = nil;
}

- (void) sendHeartbeat
{
    //NSLog( @"sending heartbeat..." );
    [self.client sendMessageWithArgument:nil toAddress:@"/thump" block:^(id data) {
        [self clearHeartbeatTimeout];
        //NSLog( @"heartbeat received" );

        // Ignore if we have manually disconnected while waiting for response
        if ( self.client.isConnected )
        {
            [self performSelector:@selector( sendHeartbeat )
                       withObject:nil
                       afterDelay:HEARTBEAT_INTERVAL];
        }
    }];
  
    // Start timeout for heartbeat response
    self.heartbeatTimeout = [NSTimer scheduledTimerWithTimeInterval:HEARTBEAT_FAILURE_INTERVAL
                                                             target:self
                                                           selector:@selector( heartbeatTimeout: )
                                                           userInfo:nil
                                                            repeats:NO];
}

- (void) heartbeatTimeout:(NSTimer *)timer
{
    // If we didn't receive a heartbeat response, keep trying
    if ( self.attempts < HEARTBEAT_MAX_ATTEMPTS )
    {
        self.attempts++;
        [self sendHeartbeat];
    }
    else
    {
        NSLog( @"Heartbeat failure: workspace may have died" );
        [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceConnectionErrorNotification object:self];
    }
}

#pragma mark - Cue Actions

- (void) startCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"start"]];
}

- (void) stopCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"stop"]];
}

- (void) pauseCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"pause"]];
}

- (void) loadCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"load"]];
}

- (void) resetCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"reset"]];
}

- (void) deleteCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:@"/delete"];
}

- (void) resumeCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"resume"]];
}

- (void) hardStopCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"hardStop"]];
}

- (void) togglePauseCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"togglePause"]];
}

- (void) previewCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"preview"]];
}

- (void) panicCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"panic"]];
}


#pragma mark - Cue Getters

- (void) cue:(QLKCue *)cue valuesForKeys:(NSArray *)keys
{
    NSString *JSONKeys = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:keys options:0 error:nil] encoding:NSUTF8StringEncoding];
    [self.client sendMessageWithArgument:JSONKeys toAddress:[self addressForCue:cue action:@"valuesForKeys"] block:nil];
}

- (void) cue:(QLKCue *)cue valueForKey:(NSString *)key completion:(QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:nil
                   toAddress:[self addressForCue:cue
                                          action:key] block:block];
}

- (void) fetchAudioLevelsForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block
{
    NSString *address = [self addressForCue:cue action:@"sliderLevels"];
    [self.client sendMessageWithArgument:nil toAddress:address block:block];
}

- (void) fetchMainPropertiesForCue:(QLKCue *)cue
{
    NSArray *keys = @[QLKOSCNameKey, QLKOSCNumberKey, QLKOSCColorNameKey, QLKOSCFlaggedKey, QLKOSCNotesKey];
    [self cue:cue valuesForKeys:keys];
}

- (void) fetchBasicPropertiesForCue:(QLKCue *)cue
{
    NSArray *keys = @[QLKOSCNameKey, QLKOSCNumberKey, QLKOSCArmedKey, QLKOSCColorNameKey, QLKOSCContinueModeKey, QLKOSCFlaggedKey, QLKOSCPostWaitKey, QLKOSCPreWaitKey, QLKOSCDurationKey];
    [self cue:cue valuesForKeys:keys];
}

- (void) fetchNotesForCue:(QLKCue *)cue
{
    NSArray *keys = @[QLKOSCNotesKey];
    [self cue:cue valuesForKeys:keys];
}

- (void) fetchDisplayAndGeometryForCue:(QLKCue *)cue
{
    NSArray *keys = @[QLKOSCFullScreenKey, QLKOSCTranslationXKey, QLKOSCTranslationYKey, QLKOSCScaleXKey, QLKOSCScaleYKey, QLKOSCLayerKey, QLKOSCOpacityKey, @"quaternion", QLKOSCPreserveAspectRatioKey, @"surfaceSize", @"cueSize", QLKOSCSurfaceIDKey, @"surfaceList"];
    [self cue:cue valuesForKeys:keys];
}

- (void) fetchChildrenForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block
{
    NSString *address = [self addressForCue:cue action:@"children"];
    [self.client sendMessageWithArgument:nil toAddress:address block:block];
}

- (void) runningOrPausedCuesWithBlock:(QLKMessageHandlerBlock)block
{
    [self.client sendMessagesWithArguments:nil toAddress:@"/runningOrPausedCues" block:block];
}

- (void) updateAllCuePropertiesSendOSC
{
    [self.root sendAllPropertiesToQLab];
}

#pragma mark - Cue Setters

- (void) cue:(QLKCue *)cue updatePropertySend:(id)value forKey:(NSString *)key
{
    [self.client sendMessageWithArgument:value toAddress:[self addressForCue:cue action:key]];
}

//deprecated
- (void) cue:(QLKCue *)cue updateName:(NSString *)name
{
    [self.client sendMessageWithArgument:name toAddress:[self addressForCue:cue action:QLKOSCNameKey]];
}

- (void) cue:(QLKCue *)cue updateNotes:(NSString *)notes
{
    [self.client sendMessageWithArgument:notes toAddress:[self addressForCue:cue action:QLKOSCNotesKey]];
}

- (void) cue:(QLKCue *)cue updateNumber:(NSString *)number
{
    [self.client sendMessageWithArgument:number toAddress:[self addressForCue:cue action:QLKOSCNumberKey]];
}

- (void) cue:(QLKCue *)cue updatePreWait:(float)preWait
{
    [self.client sendMessageWithArgument:@(preWait) toAddress:[self addressForCue:cue action:QLKOSCPreWaitKey]];
}

- (void) cue:(QLKCue *)cue updatePostWait:(float)postWait
{
    [self.client sendMessageWithArgument:@(postWait) toAddress:[self addressForCue:cue action:QLKOSCPostWaitKey]];
}

- (void) cue:(QLKCue *)cue updateDuration:(float)duration
{
    [self.client sendMessageWithArgument:@(duration) toAddress:[self addressForCue:cue action:QLKOSCDurationKey]];
}

- (void) cue:(QLKCue *)cue updateArmed:(BOOL)armed
{
    [self.client sendMessageWithArgument:@(armed) toAddress:[self addressForCue:cue action:QLKOSCArmedKey]];
}

- (void) cue:(QLKCue *)cue updateFlagged:(BOOL)flagged
{
    [self.client sendMessageWithArgument:@(flagged) toAddress:[self addressForCue:cue action:QLKOSCFlaggedKey]];
}

- (void) cue:(QLKCue *)cue updateColor:(NSString *)color
{
    [self.client sendMessageWithArgument:color toAddress:[self addressForCue:cue action:QLKOSCColorNameKey]];
}

- (void) cue:(QLKCue *)cue updateContinueMode:(QLKCueContinueMode)continueMode
{
    [self.client sendMessageWithArgument:@(continueMode) toAddress:[self addressForCue:cue action:QLKOSCContinueModeKey]];
}

- (void) cue:(QLKCue *)cue updateChannel:(NSInteger)channel level:(double)level
{
    NSArray *params = @[@(channel), @(level)];
    [self.client sendMessagesWithArguments:params toAddress:[self addressForCue:cue action:QLKOSCSliderLevelKey]];
}

- (void) cue:(QLKCue *)cue updatePatch:(NSInteger)patch
{
    [self.client sendMessageWithArgument:@(patch) toAddress:[self addressForCue:cue action:QLKOSCPatchKey]];
}

- (void) cue:(QLKCue *)cue updatePlaybackPosition:(QLKCue *)playbackCue
{
    [self.client sendMessageWithArgument:[playbackCue propertyForKey:QLKOSCUIDKey] toAddress:[self addressForCue:cue action:QLKOSCPlaybackPositionIdKey]];
}

- (void) cue:(QLKCue *)cue updateStartNextCueWhenSliceEnds:(BOOL)start
{
    [self.client sendMessageWithArgument:@(start) toAddress:[self addressForCue:cue action:QLKOSCStartNextCueWhenSliceEndsKey]];
}

- (void) cue:(QLKCue *)cue updateStopTargetWhenSliceEnds:(BOOL)stop
{
    [self.client sendMessageWithArgument:@(stop) toAddress:[self addressForCue:cue action:QLKOSCStopTargetWhenSliceEndsKey]];
}

#pragma mark - OSC Video methods

- (void) cue:(QLKCue *)cue updateSurfaceID:(NSInteger)surfaceID
{
    [self.client sendMessageWithArgument:@(surfaceID) toAddress:[self addressForCue:cue action:QLKOSCSurfaceIDKey]];
}

- (void) cue:(QLKCue *)cue updateFullScreen:(BOOL)fullScreen
{
    [self.client sendMessageWithArgument:@(fullScreen) toAddress:[self addressForCue:cue action:QLKOSCFullScreenKey]];
}

- (void) cue:(QLKCue *)cue updateTranslationX:(CGFloat)translationX
{
    [self.client sendMessageWithArgument:@(translationX) toAddress:[self addressForCue:cue action:QLKOSCTranslationXKey]];
}

- (void) cue:(QLKCue *)cue updateTranslationY:(CGFloat)translationY
{
    [self.client sendMessageWithArgument:@(translationY) toAddress:[self addressForCue:cue action:QLKOSCTranslationYKey]];
}

- (void) cue:(QLKCue *)cue updateScaleX:(CGFloat)scaleX
{
    [self.client sendMessageWithArgument:@(scaleX) toAddress:[self addressForCue:cue action:QLKOSCScaleXKey]];
}

- (void) cue:(QLKCue *)cue updateScaleY:(CGFloat)scaleY
{
    [self.client sendMessageWithArgument:@(scaleY) toAddress:[self addressForCue:cue action:QLKOSCScaleYKey]];
}

- (void) cue:(QLKCue *)cue updateRotationX:(CGFloat)rotationX
{
    [self.client sendMessageWithArgument:@(rotationX) toAddress:[self addressForCue:cue action:QLKOSCRotationXKey]];
}

- (void) cue:(QLKCue *)cue updateRotationY:(CGFloat)rotationY
{
    [self.client sendMessageWithArgument:@(rotationY) toAddress:[self addressForCue:cue action:QLKOSCRotationYKey]];
}

- (void) cue:(QLKCue *)cue updateRotationZ:(CGFloat)rotationZ
{
    [self.client sendMessageWithArgument:@(rotationZ) toAddress:[self addressForCue:cue action:QLKOSCRotationZKey]];
}

- (void) cue:(QLKCue *)cue updatePreserveAspectRatio:(BOOL)preserve
{
    [self.client sendMessageWithArgument:@(preserve) toAddress:[self addressForCue:cue action:QLKOSCPreserveAspectRatioKey]];
}

- (void) cue:(QLKCue *)cue updateLayer:(NSInteger)layer
{
    [self.client sendMessageWithArgument:@(layer) toAddress:[self addressForCue:cue action:QLKOSCLayerKey]];
}

- (void) cue:(QLKCue *)cue updateOpacity:(CGFloat)opacity
{
    [self.client sendMessageWithArgument:@(opacity) toAddress:[self addressForCue:cue action:QLKOSCOpacityKey]];
}

#pragma mark - OSC address helpers


- (void) sendMessage:(id)object toAddress:(NSString *)address
{
    [self sendMessage:object toAddress:address block:nil];
}

- (void) sendMessage:(id)object toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:object toAddress:address block:block];
}

- (NSString *) addressForWildcardNumber:(NSString *)number action:(NSString *)action
{
    return [NSString stringWithFormat:@"/cue/%@/%@", number, action];
}

- (NSString *) addressForCue:(QLKCue *)cue action:(NSString *)action
{
    return [NSString stringWithFormat:@"/cue_id/%@/%@", [cue propertyForKey:QLKOSCUIDKey], action];
}

- (NSString *) workspacePrefix
{
    return [NSString stringWithFormat:@"/workspace/%@", self.uniqueId];
}

#pragma mark - QLKClientDelegate

- (NSString *) workspaceID
{
    return self.uniqueId;
}

- (void) workspaceUpdated
{
    [self fetchCueLists];
}

- (void) playbackPositionUpdated:(NSString *)cueID
{
    QLKCue *cue = nil;
    
    if ( cueID )
        cue = [self cueWithId:cueID];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidChangePlaybackPositionNotification object:cue];
    });
}

- (void) cueNeedsUpdate:(NSString *)cueID
{
    QLKCue *cue = [self cueWithId:cueID];
    
    if ( [cue isGroup] )
    {
        [self fetchChildrenForCue:cue completion:^(id data) {
            NSMutableArray *children = [NSMutableArray array];
      
            for ( NSDictionary *dict in data )
            {
                //if child with dict[uid] exist, then updatePropertiesWithDict
                QLKCue *child = [cue cueWithId:dict[QLKOSCUIDKey]];
                if (child) {
                    [child updatePropertiesWithDictionary:dict];
                    [children addObject:child];
                } else {
                    QLKCue *cue = [[QLKCue alloc] initWithDictionary:dict workspace:self];
                    [children addObject:cue];
                }
            }
      
            [cue setProperty:children
                      forKey:QLKOSCCuesKey
                 tellQLab:NO];
      
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueUpdatedNotification object:cue];
                [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidUpdateCuesNotification object:self];
            });
        }];
    }
  
    if ( cue )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueNeedsUpdateNotification object:cue];
    }
}

- (void) cueUpdated:(NSString *)cueID withProperties:(NSDictionary *)properties
{
    QLKCue *cue = [self cueWithId:cueID];
    [cue updatePropertiesWithDictionary:properties];
}

- (void) clientConnectionErrorOccurred
{
    if ( self.connected )
    {
        [self notifyAboutConnectionError];

        // Mark as disconnected so we ignore multiple connection error messages
        self.connected = NO;
    }
}

@end
