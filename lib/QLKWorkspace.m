//
//  QLKWorkspace.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2018 Figure 53 LLC, http://figure53.com
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

#import <pthread.h>

#import "QLKCue.h"
#import "QLKServer.h"
#import "QLKClient.h"
#import "F53OSC.h"


#define HEARTBEAT_INTERVAL 5          // seconds
#define HEARTBEAT_FAILURE_INTERVAL 1  // seconds
#define HEARTBEAT_MAX_ATTEMPTS 5

NSString * const QLKWorkspaceDidUpdateNotification = @"QLKWorkspaceDidUpdateNotification";
NSString * const QLKWorkspaceDidUpdateSettingsNotification = @"QLKWorkspaceDidUpdateSettingsNotification";
NSString * const QLKWorkspaceDidUpdateLightDashboardNotification = @"QLKWorkspaceDidUpdateLightDashboardNotification";
NSString * const QLKWorkspaceDidConnectNotification = @"QLKWorkspaceDidConnectNotification";
NSString * const QLKWorkspaceDidDisconnectNotification = @"QLKWorkspaceDidDisconnectNotification";
NSString * const QLKWorkspaceConnectionErrorNotification = @"QLKWorkspaceConnectionErrorNotification";
NSString * const QLKQLabDidUpdatePreferencesNotification = @"QLKQLabDidUpdatePreferencesNotification";


NS_ASSUME_NONNULL_BEGIN

@implementation QLKQLabWorkspaceVersion

+ (instancetype) versionWithString:(NSString *)versionString
{
    return [[[self class] alloc] initWithString:versionString];
}

- (instancetype) init
{
    return [self initWithString:@""];
}

- (instancetype) initWithString:(NSString *)versionString
{
    self = [super init];
    if ( self )
    {
        _majorVersion = 0;
        _minorVersion = 0;
        _patchVersion = 0;
        
        // parse the string into components and update the struct
        NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];
        for ( NSUInteger i = 0; i < versionComponents.count; i++ )
        {
            NSInteger componentValue = versionComponents[i].integerValue;
            if ( i == 0 )
                _majorVersion = componentValue;
            else if ( i == 1 )
                _minorVersion = componentValue;
            else if ( i == 2 )
                _patchVersion = componentValue;
            else
                break;
        }
    }
    return self;
}

- (BOOL) isEqual:(id)object
{
    if ( [object isKindOfClass:[QLKQLabWorkspaceVersion class]] == NO )
        return NO;
    
    if ( ((QLKQLabWorkspaceVersion *)object).majorVersion != self.majorVersion )
        return NO;
    
    if ( ((QLKQLabWorkspaceVersion *)object).minorVersion != self.minorVersion )
        return NO;
    
    if ( ((QLKQLabWorkspaceVersion *)object).patchVersion != self.patchVersion )
        return NO;
    
    return YES;
}

- (NSString *) debugDescription
{
    return [NSString stringWithFormat:@"%@ \"%@\"", super.debugDescription, [self stringValue]];
}

- (NSString *) description
{
    return [self stringValue];
}

- (NSComparisonResult) compare:(QLKQLabWorkspaceVersion *)otherVersion
{
    // test major versions
    if ( self.majorVersion < otherVersion.majorVersion )
        return NSOrderedAscending;
    
    if ( self.majorVersion > otherVersion.majorVersion )
        return NSOrderedDescending;
    
    // major versions are equal
    
    // test minor versions
    if ( self.minorVersion < otherVersion.minorVersion )
        return NSOrderedAscending;
    
    if ( self.minorVersion > otherVersion.minorVersion )
        return NSOrderedDescending;
    
    // minor versions are equal
    
    // test patch versions
    if ( self.patchVersion < otherVersion.patchVersion )
        return NSOrderedAscending;
    
    if ( self.patchVersion > otherVersion.patchVersion )
        return NSOrderedDescending;
    
    // patch versions are equal
    return NSOrderedSame;
}

- (BOOL) isOlderThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compare:[[self class] versionWithString:version]];
    return ( result == NSOrderedAscending );
}

- (BOOL) isEqualToVersion:(NSString *)version
{
    NSComparisonResult result = [self compare:[[self class] versionWithString:version]];
    return ( result == NSOrderedSame );
}

- (BOOL) isNewerThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compare:[[self class] versionWithString:version]];
    return ( result == NSOrderedDescending );
}

- (NSString *) stringValue
{
    NSString *versionString = [NSString stringWithFormat:@"%ld.%ld.%ld",
                               (long)self.majorVersion,
                               (long)self.minorVersion,
                               (long)self.patchVersion];
    return versionString;
}

@end



@interface QLKWorkspace () {
    pthread_mutex_t _deferredCueUpdatesMutex;
}

@property (atomic, readwrite)                       BOOL connected;

@property (nonatomic, strong, readonly)             QLKClient *client;
@property (nonatomic, strong, nullable)             NSTimer *heartbeatTimeout;
@property (nonatomic)                               NSInteger heartbeatAttempts;

@property (nonatomic, strong, readonly)             dispatch_queue_t replyBlockQueue;

@property (nonatomic, strong, readonly)             NSMapTable<QLKCue *, NSMutableSet *> *deferredCueUpdates;


- (void) notifyAboutDisconnection;
- (void) notifyAboutConnectionError;

- (void) disconnectFromWorkspace;

- (void) clearHeartbeatTimeout;
- (void) sendHeartbeat;
- (void) heartbeatTimeout:(NSTimer *)timer;

@end


@implementation QLKWorkspace

- (instancetype) init
{
    self = [super init];
    if ( self )
    {
        _name = @"";
        _uniqueID = @"";
        _connected = NO;
        _heartbeatAttempts = -1; // not running
        
        _hasPasscode = NO;
        _defaultSendUpdatesOSC = NO;
        _defaultDeferFetchingPropertiesForNewCues = NO;
        
        _cuePropertiesQueue = dispatch_queue_create( "com.figure53.QLabKit.cuePropertiesQueue", DISPATCH_QUEUE_SERIAL );
        _replyBlockQueue = dispatch_queue_create( "com.figure53.QLabKit.replyBlockQueue", DISPATCH_QUEUE_SERIAL );
        
        _deferredCueUpdates = [NSMapTable weakToStrongObjectsMapTable];
        
        // Setup root cue - parent of cue lists
        _root = [[QLKCue alloc] initWithWorkspace:self];
        [self.root setProperty:QLKRootCueIdentifier
                        forKey:QLKOSCUIDKey
                      tellQLab:NO];
        [self.root setProperty:@"Cue Lists"
                        forKey:QLKOSCNameKey
                      tellQLab:NO];
        [self.root setProperty:QLKCueTypeCueList
                        forKey:QLKOSCTypeKey
                      tellQLab:NO];
        
        // init at QLab version "3.0.0" until we are told otherwise
        // NOTE: QLab 4 added the "version" key to the response for `/cueLists`
        // - prior to that, the value was absent from the response
        // - so we assume the absense of a version string (nil or empty) to be a connection to QLab 3
        QLKQLabWorkspaceVersion *defaultVersion = [[QLKQLabWorkspaceVersion alloc] initWithString:@"3.0.0"];
        _workspaceQLabVersion = defaultVersion;
    }
    return self;
}

- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server
{
    QLKClient *client = [[QLKClient alloc] initWithHost:server.host port:server.port];
    client.useTCP = YES;
    return [self initWithDictionary:dict server:server client:client];
}

- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server client:(QLKClient *)client
{
    self = [self init];
    if ( self )
    {
        if ( dict[QLKOSCUIDKey] )
            _uniqueID = (NSString *)dict[QLKOSCUIDKey];
        
        if ( [dict[@"version"] isKindOfClass:[NSString class]] )
            _workspaceQLabVersion = [[QLKQLabWorkspaceVersion alloc] initWithString:(NSString *)dict[@"version"]];
        
        [self updateWithDictionary:dict];
        
        _server = server;
        _client = client;
    }
    return self;
}

- (BOOL) updateWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict
{
    BOOL didUpdate = NO;
    
    if ( dict[@"displayName"] && [_name isEqual:dict[@"displayName"]] == NO )
    {
        _name = (NSString *)dict[@"displayName"];
        didUpdate = YES;
    }
    
    if ( _hasPasscode != [(NSNumber *)dict[@"hasPasscode"] boolValue] )
    {
        _hasPasscode = [(NSNumber *)dict[@"hasPasscode"] boolValue];
        didUpdate = YES;
    }
    
    return didUpdate;
}

- (void) dealloc
{
    self.client.delegate = nil;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ - %@ : %@", super.description, self.name, self.uniqueID];
}

- (NSString *) nameWithoutPathExtension
{
    if ( [self.name.lowercaseString.pathExtension isEqualToString:@"cues"] )
        return self.name.stringByDeletingPathExtension;
    else
        return self.name;
}

- (nullable NSString *) serverName
{
    return self.server.name;
}

- (NSString *) fullName
{
    return [NSString stringWithFormat:@"%@ (%@)", self.name, self.server.name];
}

- (nullable QLKCue *) firstCue
{
    return self.firstCueList.firstCue;
}

- (nullable QLKCue *) firstCueList
{
    return self.root.firstCue;
}

- (NSString *) fullNameWithCueList:(QLKCue *)cueList
{
    return [NSString stringWithFormat:@"%@ - %@ (%@)", self.name, [cueList propertyForKey:QLKOSCNameKey], self.server.name];
}

- (BOOL) isQLabWorkspaceVersionAtLeastVersion:(QLKQLabWorkspaceVersion *)version
{
    NSComparisonResult result = [_workspaceQLabVersion compare:version];
    return ( result != NSOrderedAscending );
}

- (BOOL) connectedToQLab3
{
    return ( _workspaceQLabVersion.majorVersion == 3 );
}



#pragma mark - Connection/reconnection

- (void) connectWithPasscode:(nullable NSString *)passcode completion:(nullable QLKMessageHandlerBlock)completion
{
    self.client.delegate = self;
    
    if ( !self.connected && !self.client.isConnected && ![self.client connect] )
    {
        NSLog( @"[workspace] *** Error: couldn't connect to server" );
        
        self.client.delegate = nil;
        
        // Notify that we are unable to connect to workspace
        [self notifyAboutConnectionError];
        
        if ( completion )
            completion( @"error" );
        
        return;
    }
    
    NSLog( @"[workspace] connecting..." );
    
    __weak typeof(self) weakSelf = self;
    [self.client sendMessageWithArgument:passcode toAddress:@"/connect" block:^(id data) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        if ( [data isEqualToString:@"ok"] )
        {
            // upon success, update cached passcode to use for automatic reconnection
            if ( strongSelf.hasPasscode )
                strongSelf.passcode = passcode;
            else
                strongSelf.passcode = nil;
                
            NSLog( @"[workspace] connected successfully" );
            
            [strongSelf finishConnection];
        }
        else
        {
            strongSelf.client.delegate = nil;
            [strongSelf.client disconnect];
            
            if ( [data isEqualToString:@"badpass"] )
                NSLog( @"[workspace] invalid passcode" );
            else
                NSLog( @"[workspace] connection error: %@", data );
            
            [strongSelf notifyAboutConnectionError];
        }
        
        if ( completion )
            completion( data );
        
    }];
}

// Called when a connection is successfully made
- (void) finishConnection
{
    if ( self.connected )
        return;
    
    pthread_mutex_init( &_deferredCueUpdatesMutex, NULL );
    
    self.connected = YES;
    [self startReceivingUpdates];
    [self fetchQLabVersionWithBlock:nil];
    [self fetchCueLists];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidConnectNotification object:self];
}

- (void) reconnect
{
    // Reconnect using the last-known passcode, e.g. when app wakes from sleep
    NSLog( @"[workspace] reconnecting..." );
    [self connectWithPasscode:self.passcode completion:nil];
}

- (void) disconnect
{
    NSLog( @"[workspace] disconnect: %@", self.name );
    
    self.client.delegate = nil;
    [self stopHeartbeat];
    [self stopReceivingUpdates];
    
    [self disconnectFromWorkspace];
    
    self.connected = NO;
    
    [self.client disconnect];
    
    [self.root removeAllChildCues];
    
    pthread_mutex_lock( &_deferredCueUpdatesMutex );
    [self.deferredCueUpdates removeAllObjects];
    pthread_mutex_unlock( &_deferredCueUpdatesMutex );
    
    pthread_mutex_destroy( &_deferredCueUpdatesMutex );
}

// Temporary disconnect when going to sleep
- (void) temporarilyDisconnect
{
    NSLog( @"[workspace] temp disconnect" );
    
    [self disconnectFromWorkspace];
    [self stopHeartbeat];
    [self stopReceivingUpdates];
    
    self.connected = NO;
    
    [self.client disconnect];
}

- (void) notifyAboutDisconnection
{
    NSLog( @"[workspace] *** notifyAboutDisconnection" );
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidDisconnectNotification object:self];
}

- (void) notifyAboutConnectionError
{
    NSLog( @"[workspace] *** notifyAboutConnectionError" );
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceConnectionErrorNotification object:self];
}



#pragma mark - Cues

- (nullable QLKCue *) cueWithID:(NSString *)uid
{
    return [self.root cueWithID:uid];
}

- (nullable QLKCue *) cueWithNumber:(NSString *)number {
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
    [self.client sendMessagesWithArguments:@[ @YES ] toAddress:@"/alwaysReply" workspace:NO block:nil];
}

- (void) disableAlwaysReply
{
    [self.client sendMessagesWithArguments:@[ @NO ] toAddress:@"/alwaysReply" workspace:NO block:nil];
}

- (void) fetchQLabVersionWithBlock:(nullable QLKMessageHandlerBlock)block
{
    __weak typeof(self) weakSelf = self;
    [self.client sendMessagesWithArguments:nil toAddress:@"/version" workspace:NO block:^(id data) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        if ( [data isKindOfClass:[NSString class]] )
            strongSelf->_workspaceQLabVersion = [[QLKQLabWorkspaceVersion alloc] initWithString:(NSString *)data];
        
        if ( block )
            block( data );
        
    }];
}

- (void) fetchCueLists
{
    __weak typeof(self) weakSelf = self;
    [self fetchCueListsWithBlock:^(id data) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        if ( !strongSelf.connected )
            return;
        
        if ( [data isKindOfClass:[NSArray class]] == NO )
            return; 
        
        BOOL rootCueUpdated = NO;
        NSMutableArray<QLKCue *> *currentCueLists = [NSMutableArray arrayWithCapacity:((NSArray *)data).count];
        
        NSUInteger index = 0;
        for ( NSDictionary<NSString *, NSObject<NSCopying> *> *aCueListDict in (NSArray *)data )
        {
            NSString *uid = (NSString *)aCueListDict[QLKOSCUIDKey];
            if ( !uid )
                continue;
            
            QLKCue *cueList = [strongSelf.root cueWithID:uid includeChildren:NO];
            if ( cueList )
            {
                if ( cueList.sortIndex != index )
                {
                    cueList.sortIndex = index;
                    rootCueUpdated = YES;
                }
            }
            else
            {
                cueList = [[QLKCue alloc] initWithDictionary:aCueListDict workspace:strongSelf];
                cueList.sortIndex = index;
                
                // manually set cue type to "Cue List" when connected to QLab 3 workspaces (default is "Group")
                if ( strongSelf.connectedToQLab3 )
                    [cueList setProperty:QLKCueTypeCueList forKey:QLKOSCTypeKey];
                
                // allow notification observers to react to this new-found cue list
                NSNotification *notification = [NSNotification notificationWithName:QLKCueNeedsUpdateNotification
                                                                             object:cueList];
                [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                           postingStyle:NSPostWhenIdle
                                                           coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                               forModes:@[ NSRunLoopCommonModes ]];
                
                rootCueUpdated = YES;
            }
            [currentCueLists addObject:cueList];
            
            index++;
        }
        
        QLKCue *activeCuesList = [strongSelf.root cueWithID:QLKActiveCuesIdentifier includeChildren:NO];
        if ( activeCuesList )
        {
            if ( activeCuesList.sortIndex != index )
            {
                activeCuesList.sortIndex = index;
                rootCueUpdated = YES;
            }
        }
        else
        {
            // Manually add active cues list to root
            activeCuesList = [[QLKCue alloc] initWithWorkspace:strongSelf];
            activeCuesList.sortIndex = index;
            
            
            [activeCuesList setProperty:QLKActiveCuesIdentifier
                                 forKey:QLKOSCUIDKey
                               tellQLab:NO];
            [activeCuesList setProperty:@"Active Cues"
                                 forKey:QLKOSCNameKey
                               tellQLab:NO];
            [activeCuesList setProperty:QLKCueTypeCueList
                                 forKey:QLKOSCTypeKey
                               tellQLab:NO];
            
            rootCueUpdated = YES;
        }
        [currentCueLists addObject:activeCuesList];
        
        
        if ( strongSelf.root.cues.count != currentCueLists.count )
            rootCueUpdated = YES;
        
        [strongSelf.root setProperty:currentCueLists forKey:QLKOSCCuesKey tellQLab:NO];
        
        
        if ( rootCueUpdated )
            [strongSelf.root enqueueCueUpdatedNotification];
        
    }];
}

- (void) fetchCueListsWithBlock:(nullable QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:nil toAddress:@"/cueLists" block:block];
}

- (void) fetchPlaybackPositionForCue:(QLKCue *)cue block:(nullable QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:QLKOSCPlaybackPositionIdKey] block:block];
}

- (void) go
{
    [self.client sendMessageWithArgument:nil toAddress:@"/go"];
}

- (void) save
{
    [self.client sendMessageWithArgument:nil toAddress:@"/save"];
}

- (void) undo
{
    [self.client sendMessageWithArgument:nil toAddress:@"/undo"];
}

- (void) redo
{
    [self.client sendMessageWithArgument:nil toAddress:@"/redo"];
}

- (void) resetAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/reset"];
}

- (void) pauseAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/pause"];
}

- (void) resumeAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/resume"];
}

- (void) stopAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/stop"];
}

- (void) panicAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/panic"];
}



#pragma mark - Heartbeat

- (void) startHeartbeat
{
    [self clearHeartbeatTimeout];
    [self sendHeartbeat];
}

- (void) stopHeartbeat
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
    [self clearHeartbeatTimeout];
    
    self.heartbeatAttempts = -1; // not running
}

- (void) clearHeartbeatTimeout
{
    [self.heartbeatTimeout invalidate];
    self.heartbeatTimeout = nil;
    
    self.heartbeatAttempts = 0;
}

- (void) sendHeartbeat
{
    //NSLog( @"sending heartbeat..." );
    
    __weak typeof(self) weakSelf = self;
    [self.client sendMessageWithArgument:nil toAddress:@"/thump" block:^(id data) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        //NSLog( @"heartbeat received" );
        
        // exit if not running
        if ( strongSelf.heartbeatAttempts == -1 )
            return;
        
        [strongSelf clearHeartbeatTimeout];
        
        // Don't send if we have become disconnected while waiting for response
        if ( !strongSelf.connected || !strongSelf.client.isConnected )
            return;
        
        [strongSelf performSelector:@selector(sendHeartbeat)
                         withObject:nil
                         afterDelay:HEARTBEAT_INTERVAL];
        
    }];
    
    // Start timeout for heartbeat response
    self.heartbeatTimeout = [NSTimer scheduledTimerWithTimeInterval:HEARTBEAT_FAILURE_INTERVAL
                                                             target:self
                                                           selector:@selector(heartbeatTimeout:)
                                                           userInfo:nil
                                                            repeats:NO];
}

- (void) heartbeatTimeout:(NSTimer *)timer
{
    if ( !timer.isValid )
        return;
    
    if ( self.heartbeatAttempts == -1 )
        return;
    
    // exit if workspace has disconnected while waiting for response
    if ( !self.connected )
        return;
    
    // if timer fires before we receive a response from /thump,
    // - if we have attempts left, try sending again
    // - else post a connection error notification
    if ( self.heartbeatAttempts < HEARTBEAT_MAX_ATTEMPTS )
    {
        self.heartbeatAttempts++;
        [self sendHeartbeat];
    }
    else
    {
        NSLog( @"Heartbeat failure: workspace may have died" );
        [self notifyAboutConnectionError];
    }
}



#pragma mark - Cue Actions

- (void) startCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"start"]];

    // immediately update local state for snappier UI response
    [cue updatePropertiesWithDictionary:@{ QLKOSCIsRunningKey : @YES }];
}

- (void) stopCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"stop"]];
}

- (void) pauseCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"pause"]];

    // immediately update local state for snappier UI response
    [cue updatePropertiesWithDictionary:@{ QLKOSCIsPausedKey : @YES }];
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
    NSString *address = [NSString stringWithFormat:@"/delete_id/%@", [cue propertyForKey:QLKOSCUIDKey]];
    [self.client sendMessageWithArgument:nil toAddress:address];
}

- (void) resumeCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"resume"]];
}

- (void) hardStopCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"hardStop"]];
}

- (void) hardPauseCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"hardPause"]];

    // immediately update local state for snappier UI response
    [cue updatePropertiesWithDictionary:@{ QLKOSCIsPausedKey : @YES }];
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
    
    // immediately update local state for snappier UI response
    // NOTE: /isPanicking requires QLab 4.0+
    if ( !self.connectedToQLab3 )
    {
        [cue updatePropertiesWithDictionary:@{ QLKOSCIsPanickingKey : @YES }];
        for ( QLKCue *aCue in cue.cues )
        {
            if ( aCue.isRunning )
                [aCue updatePropertiesWithDictionary:@{ QLKOSCIsPanickingKey : @YES }];
        }
    }
}



#pragma mark - Cue Getters/Setters

- (void) cue:(QLKCue *)cue valueForKey:(NSString *)key block:(nullable QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:nil
                               toAddress:[self addressForCue:cue action:key]
                                   block:block];
}

- (void) cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys
{
    [self cue:cue valuesForKeys:keys block:nil];
}

- (void) cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys block:(nullable QLKMessageHandlerBlock)block
{
    NSString *JSONKeys = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:keys options:0 error:nil] encoding:NSUTF8StringEncoding];
    [self.client sendMessageWithArgument:JSONKeys toAddress:[self addressForCue:cue action:@"valuesForKeys"] block:block];
}

- (void) cue:(QLKCue *)cue updatePropertySend:(nullable id)value forKey:(NSString *)key
{
    [self.client sendMessageWithArgument:value toAddress:[self addressForCue:cue action:key]];
}

- (void) cue:(QLKCue *)cue updatePropertiesSend:(nullable NSArray *)values forKey:(NSString *)key
{
    [self.client sendMessagesWithArguments:values toAddress:[self addressForCue:cue action:key]];
}

- (void) updateAllCuePropertiesSendOSC
{
    [self.root sendAllPropertiesToQLab];
}

- (void) runningOrPausedCuesWithBlock:(nullable QLKMessageHandlerBlock)block
{
    [self.client sendMessagesWithArguments:nil toAddress:@"/runningOrPausedCues" block:block];
}



#pragma mark - Property Fetching

- (void) fetchDefaultCueListPropertiesForCue:(QLKCue *)cue
{
    NSArray<NSString *> *keys = @[ QLKOSCUIDKey, QLKOSCNumberKey, QLKOSCNameKey, QLKOSCListNameKey, QLKOSCTypeKey, QLKOSCColorNameKey, QLKOSCFlaggedKey, QLKOSCArmedKey, QLKOSCNotesKey ];
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void) fetchBasicPropertiesForCue:(QLKCue *)cue
{
    NSArray<NSString *> *keys = @[ QLKOSCNameKey, QLKOSCNumberKey, QLKOSCFileTargetKey, QLKOSCCueTargetNumberKey, QLKOSCHasFileTargetsKey, QLKOSCHasCueTargetsKey, QLKOSCArmedKey, QLKOSCColorNameKey, QLKOSCContinueModeKey, QLKOSCFlaggedKey, QLKOSCPreWaitKey, QLKOSCPostWaitKey, QLKOSCDurationKey, QLKOSCAllowsEditingDurationKey ];
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void) fetchNotesForCue:(QLKCue *)cue
{
    NSArray<NSString *> *keys = @[ QLKOSCNotesKey ];
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void) fetchDisplayAndGeometryForCue:(QLKCue *)cue
{
    NSString *fullSurfaceKey = ( self.connectedToQLab3 ? QLKOSCFullScreenKey : QLKOSCFullSurfaceKey );
    NSArray<NSString *> *keys = @[ fullSurfaceKey, QLKOSCTranslationXKey, QLKOSCTranslationYKey, QLKOSCScaleXKey, QLKOSCScaleYKey, QLKOSCOriginXKey, QLKOSCOriginYKey, QLKOSCLayerKey, QLKOSCOpacityKey, QLKOSCQuaternionKey, QLKOSCPreserveAspectRatioKey, QLKOSCSurfaceSizeKey, QLKOSCCueSizeKey, QLKOSCSurfaceIDKey, QLKOSCSurfaceListKey ];
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void) fetchPropertiesForCue:(QLKCue *)cue keys:(NSArray<NSString *> *)keys includeChildren:(BOOL)includeChildren
{
    pthread_mutex_lock( &_deferredCueUpdatesMutex );
    NSMutableSet *currentKeys = [self.deferredCueUpdates objectForKey:cue];
    pthread_mutex_unlock( &_deferredCueUpdatesMutex );
    
    if ( currentKeys )
    {
        [currentKeys addObjectsFromArray:keys];
        if ( includeChildren )
            [currentKeys addObject:@"includeChildren"];
    }
    else
    {
        [self cue:cue valuesForKeys:keys block:nil];
    }
    
    if ( !includeChildren )
        return;
    
    for ( QLKCue *aCue in cue.cues )
    {
        [self fetchPropertiesForCue:aCue keys:keys includeChildren:includeChildren];
    }
}

- (void) deferFetchingPropertiesForCue:(QLKCue *)cue
{
    if ( cue.isCueList || cue.isCueCart )
        return;
    
    // if currentKeys set does not exist, setObject with a new empty set to begin deferring
    // if currentKeys exists, already deferred -- do nothing
    pthread_mutex_lock( &_deferredCueUpdatesMutex );
    
    NSMutableSet *currentKeys = [self.deferredCueUpdates objectForKey:cue];
    if ( !currentKeys )
    {
        currentKeys = [NSMutableSet setWithCapacity:0];
        [self.deferredCueUpdates setObject:currentKeys forKey:cue];
    }
    
    pthread_mutex_unlock( &_deferredCueUpdatesMutex );
}

- (void) resumeFetchingPropertiesForCue:(QLKCue *)cue
{
    pthread_mutex_lock( &_deferredCueUpdatesMutex );
    NSMutableSet *currentKeys = [self.deferredCueUpdates objectForKey:cue];
    [self.deferredCueUpdates removeObjectForKey:cue];
    pthread_mutex_unlock( &_deferredCueUpdatesMutex );
    
    if ( currentKeys.count )
    {
        BOOL includeChildren = [currentKeys containsObject:@"includeChildren"];
        [currentKeys removeObject:@"includeChildren"];
        
        [self fetchPropertiesForCue:cue
                               keys:currentKeys.allObjects
                    includeChildren:includeChildren];
    }
}



#pragma mark - OSC address helpers

- (void) sendMessage:(nullable id)object toAddress:(NSString *)address
{
    [self sendMessage:object toAddress:address block:nil];
}

- (void) sendMessage:(nullable id)object toAddress:(NSString *)address block:(nullable QLKMessageHandlerBlock)block
{
    [self.client sendMessageWithArgument:object toAddress:address block:block];
}

- (void) sendApplicationMessageWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address block:(nullable QLKMessageHandlerBlock)block
{
    [self.client sendMessagesWithArguments:arguments toAddress:address workspace:NO block:block];
}

- (NSString *) addressForCue:(QLKCue *)cue action:(NSString *)action
{
    return [NSString stringWithFormat:@"/cue_id/%@/%@", [cue propertyForKey:QLKOSCUIDKey], action];
}

- (NSString *) addressForWildcardNumber:(NSString *)number action:(NSString *)action
{
    return [NSString stringWithFormat:@"/cue/%@/%@", number, action];
}

- (NSString *) workspacePrefix
{
    return [NSString stringWithFormat:@"/workspace/%@", self.uniqueID];
}



#pragma mark - QLKClientDelegate

- (NSString *) workspaceID
{
    return self.uniqueID;
}

- (void) workspaceUpdated
{
    [self fetchCueLists];
    
    NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateNotification
                                                                 object:self
                                                               userInfo:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                   forModes:@[ NSRunLoopCommonModes ]];
}

- (void) workspaceSettingsUpdated:(NSString *)settingsType
{
    NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateSettingsNotification
                                                                 object:self
                                                               userInfo:@{ @"settingsType" : settingsType }];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                   forModes:@[ NSRunLoopCommonModes ]];
}

- (void) workspaceDisconnected
{
    if ( !self.connected )
        return;
    
    NSLog( @"[workspace] *** workspaceDisconnected" );
    
    [self disconnect];
    [self notifyAboutDisconnection];
}

- (void) lightDashboardUpdated
{
    // NOTE: Dashboard updates require a connection to QLab 4.2+
    NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateLightDashboardNotification
                                                                 object:self
                                                               userInfo:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                   forModes:@[ NSRunLoopCommonModes ]];
}

- (void) preferencesUpdated:(NSString *)key
{
    // NOTE: Preferences updates require a connection to QLab 4.2+
    NSNotification *notification = [NSNotification notificationWithName:QLKQLabDidUpdatePreferencesNotification
                                                                 object:self
                                                               userInfo:@{ @"preferencesKey" : key }];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                   forModes:@[ NSRunLoopCommonModes ]];
}

- (void) cueNeedsUpdate:(NSString *)cueID
{
    QLKCue *cue = [self cueWithID:cueID];
    
    if ( cue.isGroup )
    {
        __weak typeof(self) weakSelf = self;
        [self cue:cue valueForKey:@"children" block:^(id data) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ( !strongSelf )
                return;
            
            if ( [data isKindOfClass:[NSArray class]] == NO )
                return;
            
            [cue updateChildCuesWithPropertiesArray:(NSArray *)data removeUnused:YES];
            
        }];
    }
    
    if ( cue )
    {
        NSNotification *notification = [NSNotification notificationWithName:QLKCueNeedsUpdateNotification
                                                                     object:cue];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                   postingStyle:NSPostWhenIdle
                                                   coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                       forModes:@[ NSRunLoopCommonModes ]];
    }
}

- (void) cueUpdated:(NSString *)cueID withProperties:(NSDictionary<NSString *, NSObject<NSCopying> *> *)properties
{
    QLKCue *cue = [self cueWithID:cueID];
    if ( !cue || cue.ignoreUpdates )
        return;
    
    dispatch_async( self.replyBlockQueue, ^{
        [cue updatePropertiesWithDictionary:properties];
    });
}

- (void) cueListUpdated:(NSString *)cueListID withPlaybackPositionID:(nullable NSString *)cueID
{
    QLKCue *cueList = [self cueWithID:cueListID];
    if ( !cueList || cueList.ignoreUpdates )
        return;
    
    dispatch_async( self.replyBlockQueue, ^{
        [cueList setPlaybackPositionID:cueID tellQLab:NO];
    });
}

- (BOOL) clientShouldDisconnectOnError
{
    NSLog( @"[workspace] *** clientShouldDisconnectOnError" );
    
    if ( self.server && self.attemptToReconnect )
        return NO;
    
    // else
    return YES;
}

- (void) clientConnectionErrorOccurred
{
    if ( !self.connected )
        return;
    
    NSLog( @"[workspace] *** Error: clientConnectionErrorOccurred" );
    
    [self notifyAboutConnectionError];
}



#pragma mark - deprecated

- (void) fetchChildrenForCue:(QLKCue *)cue block:(nullable QLKMessageHandlerBlock)block
{
    [self cue:cue valueForKey:@"children" block:block];
}

- (void) fetchAudioLevelsForCue:(QLKCue *)cue block:(nullable QLKMessageHandlerBlock)block
{
    [self cue:cue valueForKey:@"sliderLevels" block:block];
}

- (void) connect
{
    NSLog( @"[workspace] connect" );
    [self connectWithPasscode:self.passcode completion:nil];
}

@end

NS_ASSUME_NONNULL_END
