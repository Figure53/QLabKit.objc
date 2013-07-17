//
//  QLKConnection.m
//  QLab for iPad
//
//  Created by Zach Waugh on 5/12/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "QLKWorkspace.h"
#import "QLKCue.h"
#import "QLKServer.h"
#import "QLKClient.h"
#import "F53OSC.h"

#define HEARTBEAT_INTERVAL 5 // seconds
#define HEARTBEAT_FAILURE_INTERVAL 1 // seconds
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
@property (strong, nonatomic) NSString *passcode;

- (void)startHeartbeat;
- (void)stopHeartbeat;
- (void)clearHeartbeatTimeout;
- (void)sendHeartbeat;
- (void)heartbeatTimeout:(NSTimer *)timer;

- (NSString *)workspacePrefix;
- (NSString *)addressForCue:(QLKCue *)cue action:(NSString *)action;

@end

@implementation QLKWorkspace

- (void)dealloc
{
  self.client.delegate = nil;
}

- (id)init
{
  self = [super init];
  if (!self) return nil;

  _uniqueId = @"";
  _connected = NO;
  _attempts = 0;
  
  // Setup root cue - parent of cue lists
  _root = [[QLKCue alloc] init];
  _root.uid = QLKRootCueIdentifier;
  _root.name = @"Cue Lists";
  _root.type = QLKCueTypeGroup;
  
  _hasPasscode = NO;

  return self;
}

- (id)initWithDictionary:(NSDictionary *)dict server:(QLKServer *)server
{
  self = [self init];
  if (!self) return nil;

  _name = dict[@"displayName"];
  _serverName = server.name;
  _client = [[QLKClient alloc] initWithHost:server.host port:server.port];
  _client.useTCP = YES;
  _client.delegate = self;
  _uniqueId = dict[@"uniqueID"];
  _hasPasscode = [dict[@"hasPasscode"] boolValue];

  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ - %@", [super description], self.name];
}

- (NSString *)fullName
{
  return [NSString stringWithFormat:@"%@ (%@)", self.name, self.serverName];
}

- (NSString *)fullNameWithCueList:(QLKCue *)cueList
{
  return [NSString stringWithFormat:@"%@ - %@ (%@)", self.name, cueList.name, self.serverName];
}

#pragma mark - Connection/reconnection

- (void)connect
{
  NSLog(@"connect: %@, %@", self.name, self.serverName);
  
  [self connectToWorkspace];
  [self finishConnection];
}

- (void)connectWithPasscode:(NSString *)passcode block:(QLKMessageHandlerBlock)block;
{
  NSLog(@"connect with passcode: %@, %@", self.name, passcode);
  [self connectToWorkspaceWithPasscode:passcode completion:block];
}

// Called when a connection is successfully made
- (void)finishConnection
{
  self.connected = YES;
  [self startReceivingUpdates];
  [self fetchCueLists];
  [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidConnectNotification object:self];
}

- (void)disconnect
{
  NSLog(@"disconnect: %@", self.name);
  [self disconnectFromWorkspace];
  [self stopReceivingUpdates];
  self.connected = NO;
  [self.client disconnect];
  self.root.cues = nil;
  
  [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidDisconnectNotification object:self];
}

// Reconnect when app wakes from sleep
- (void)reconnect
{
  NSLog(@"reconnecting...");

  // Try to use some password as before
  [self connectToWorkspaceWithPasscode:self.passcode completion:^(id data) {
    NSLog(@"reconnect response: %@", data);
    if ([data isEqualToString:@"ok"]) {
      NSLog(@"reconnected successfully: %@", data);
      [self finishConnection];
    } else {
      NSLog(@"error reconnecting");
      [self notifyAboutConnectionError];
    }
  }];
}

// Temporary disconnect when going to sleep
- (void)temporarilyDisconnect
{
  NSLog(@"temp disconnect");
  [self disconnectFromWorkspace];
  [self stopHeartbeat];
  [self stopReceivingUpdates];
  
  [self.client disconnect];
  self.connected = NO;
}

- (void)notifyAboutConnectionError
{
  NSLog(@"notifyAboutConnectionError: main thread? %d", [NSThread isMainThread]);
  [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceConnectionErrorNotification object:self];
}

#pragma mark - Cues

- (QLKCue *)firstCue
{
  return [[self firstCueList] firstCue];
}

- (QLKCue *)firstCueList
{
  return [self.root firstCue];
}

- (QLKCue *)cueWithId:(NSString *)uid
{
  return [self.root cueWithId:uid];
  //return [[self.cue.cues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uid = %@", uid]] lastObject];
}

#pragma mark - Workspace Methods

- (void)connectToWorkspace
{
  [self connectToWorkspaceWithPasscode:nil completion:nil];
}

- (void)connectToWorkspaceWithPasscode:(NSString *)passcode completion:(QLKMessageHandlerBlock)block
{
	if ([self.client connect]) {
		NSLog(@"connected to server");
	} else {
    NSLog(@"*** Error: couldn't connect to server");
    // Notify that we are unable to connect to workspace
    [self notifyAboutConnectionError];
    return;
  }
	
  if (passcode) {
    self.passcode = passcode;
  }
  
  [self.client sendMessage:passcode toAddress:@"/connect" block:^(id data) {
    if (block) block(data);
  }];
}

- (void)disconnectFromWorkspace
{
  [self.client sendMessage:nil toAddress:@"/disconnect"];
}

- (void)startReceivingUpdates
{
  [self.client sendMessage:@YES toAddress:@"/updates"];
}

- (void)stopReceivingUpdates
{
  [self.client sendMessage:@NO toAddress:@"/updates"];
}

- (void)enableAlwaysReply
{
  F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/alwaysReply" arguments:@[@YES]];
  [self.client sendMessage:message];
}

- (void)disableAlwaysReply
{
  F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/alwaysReply" arguments:@[@NO]];
  [self.client sendMessage:message];
}

- (void)fetchCueLists
{
  [self fetchCueListsWithCompletion:^(id data) {
    NSArray *cueLists = (NSArray *)data;
    
    NSMutableArray *children = [NSMutableArray array];
    
    for (NSDictionary *cueList in cueLists) {
      QLKCue *cue = [QLKCue cueWithDictionary:cueList];
      [children addObject:cue];
    }
    
    // Manually add active cues to end of list
    QLKCue *activeCues = [[QLKCue alloc] init];
    activeCues.uid = QLKActiveCueListIdentifier;
    activeCues.name = @"Active Cues";
    activeCues.type = QLKCueTypeGroup;
    [children addObject:activeCues];
    
    self.root.cues = children;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidUpdateCuesNotification object:self];
    });
  }];
}

- (void)fetchCueListsWithCompletion:(QLKMessageHandlerBlock)block
{
  [self.client sendMessage:nil toAddress:@"/cueLists" block:block];
}

- (void)fetchPlaybackPositionForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block
{
  [self.client sendMessage:nil toAddress:[self addressForCue:cue action:@"playbackPositionId"] block:block];
}

- (void)go
{
  [self.client sendMessage:nil toAddress:@"/go"];
}

- (void)stopAll
{
  [self.client sendMessage:nil toAddress:@"/stop"];
}

- (void)save
{
  [self.client sendMessage:nil toAddress:@"/save"];
}

#pragma mark - Heartbeat

// Send heartbeat every 5 seconds (HEARTBEAT_INTERVAL)
- (void)startHeartbeat
{
  self.attempts = 0;
  [self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:HEARTBEAT_INTERVAL];
}

- (void)stopHeartbeat
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
  [self clearHeartbeatTimeout];
}

- (void)clearHeartbeatTimeout
{
  self.attempts = 0;
  [self.heartbeatTimeout invalidate];
  self.heartbeatTimeout = nil;
}

- (void)sendHeartbeat
{
  //NSLog(@"sending heartbeat...");
  [self.client sendMessage:nil toAddress:@"/thump" block:^(id data) {
    [self clearHeartbeatTimeout];
    //NSLog(@"heartbeat received");
    
    // Ignore if we have manually disconnected while waiting for response
    if (self.client.connected) {
      [self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:HEARTBEAT_INTERVAL];
    }
  }];
  
  // Start timeout for heartbeat response
  self.heartbeatTimeout = [NSTimer scheduledTimerWithTimeInterval:HEARTBEAT_FAILURE_INTERVAL target:self selector:@selector(heartbeatTimeout:) userInfo:nil repeats:NO];
}

- (void)heartbeatTimeout:(NSTimer *)timer
{
  // If we didn't receive a heartbeat response, keep trying
  if (self.attempts < HEARTBEAT_MAX_ATTEMPTS) {
    self.attempts++;
    [self sendHeartbeat];
  } else {
    NSLog(@"Heartbeat failure: workspace may have died");
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceConnectionErrorNotification object:self];
  }
}

#pragma mark - Cue Actions

- (void)startCue:(QLKCue *)cue
{
  [self.client sendMessage:nil toAddress:[self addressForCue:cue action:@"start"]];
}

- (void)stopCue:(QLKCue *)cue
{
  [self.client sendMessage:nil toAddress:[self addressForCue:cue action:@"stop"]];
}

- (void)pauseCue:(QLKCue *)cue
{
  [self.client sendMessage:nil toAddress:[self addressForCue:cue action:@"pause"]];
}

- (void)loadCue:(QLKCue *)cue
{
  [self.client sendMessage:nil toAddress:[self addressForCue:cue action:@"load"]];
}

- (void)resetCue:(QLKCue *)cue
{
  [self.client sendMessage:nil toAddress:[self addressForCue:cue action:@"reset"]];
}

- (void)deleteCue:(QLKCue *)cue
{
  [self.client sendMessage:nil toAddress:@"/delete"];
}

#pragma mark - Cue Getters

- (void)cue:(QLKCue *)cue valuesForKeys:(NSArray *)keys
{
  NSString *JSONKeys = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:keys options:0 error:nil] encoding:NSUTF8StringEncoding];
  [self.client sendMessage:JSONKeys toAddress:[self addressForCue:cue action:@"valuesForKeys"] block:nil];
}

- (void)fetchAudioLevelsForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block
{
  NSString *address = [self addressForCue:cue action:@"sliderLevels"];
  [self.client sendMessage:nil toAddress:address block:block];
}

- (void)fetchMainPropertiesForCue:(QLKCue *)cue
{
  NSArray *keys = @[@"name", @"number", @"colorName", @"flagged", @"notes"];
  [self cue:cue valuesForKeys:keys];
}

- (void)fetchBasicPropertiesForCue:(QLKCue *)cue
{
  NSArray *keys = @[@"name", @"number", @"armed", @"colorName", @"continueMode", @"flagged", @"postWait", @"preWait", @"duration"];
  [self cue:cue valuesForKeys:keys];
}

- (void)fetchNotesForCue:(QLKCue *)cue
{
  NSArray *keys = @[@"notes"];
  [self cue:cue valuesForKeys:keys];
}

- (void)fetchDisplayAndGeometryForCue:(QLKCue *)cue
{
  NSArray *keys = @[@"fullScreen", @"translationX", @"translationY", @"scaleX", @"scaleY", @"layer", @"opacity", @"quaternion", @"preserveAspectRatio", @"surfaceSize", @"cueSize", @"surfaceID", @"surfaceList"];
  [self cue:cue valuesForKeys:keys];
}

- (void)fetchChildrenForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block
{
  NSString *address = [self addressForCue:cue action:@"children"];
  [self.client sendMessage:nil toAddress:address block:block];
}

- (void)runningOrPausedCuesWithBlock:(QLKMessageHandlerBlock)block
{
  [self.client sendMessages:nil toAddress:@"/runningOrPausedCues" block:block];
}

#pragma mark - Cue Setters

- (void)cue:(QLKCue *)cue updateName:(NSString *)name
{
  [self.client sendMessage:name toAddress:[self addressForCue:cue action:@"name"]];
}

- (void)cue:(QLKCue *)cue updateNotes:(NSString *)notes
{
  [self.client sendMessage:notes toAddress:[self addressForCue:cue action:@"notes"]];
}

- (void)cue:(QLKCue *)cue updateNumber:(NSString *)number
{
  [self.client sendMessage:number toAddress:[self addressForCue:cue action:@"number"]];
}

- (void)cue:(QLKCue *)cue updatePreWait:(float)preWait
{
  [self.client sendMessage:@(preWait) toAddress:[self addressForCue:cue action:@"preWait"]];
}

- (void)cue:(QLKCue *)cue updatePostWait:(float)postWait
{
  [self.client sendMessage:@(postWait) toAddress:[self addressForCue:cue action:@"postWait"]];
}

- (void)cue:(QLKCue *)cue updateDuration:(float)duration
{
  [self.client sendMessage:@(duration) toAddress:[self addressForCue:cue action:@"duration"]];
}

- (void)cue:(QLKCue *)cue updateArmed:(BOOL)armed
{
  [self.client sendMessage:@(armed) toAddress:[self addressForCue:cue action:@"armed"]];
}

- (void)cue:(QLKCue *)cue updateFlagged:(BOOL)flagged
{
  [self.client sendMessage:@(flagged) toAddress:[self addressForCue:cue action:@"flagged"]];
}

- (void)cue:(QLKCue *)cue updateColor:(NSString *)color
{
  [self.client sendMessage:color toAddress:[self addressForCue:cue action:@"colorName"]];
}

- (void)cue:(QLKCue *)cue updateContinueMode:(QLKCueContinueMode)continueMode
{
  [self.client sendMessage:@(continueMode) toAddress:[self addressForCue:cue action:@"continueMode"]];
}

- (void)cue:(QLKCue *)cue updateChannel:(NSInteger)channel level:(double)level
{
	NSArray *params = @[@(channel), @(level)];
  [self.client sendMessages:params toAddress:[self addressForCue:cue action:@"sliderLevel"]];
}

- (void)cue:(QLKCue *)cue updatePatch:(NSInteger)patch
{
  [self.client sendMessage:@(patch) toAddress:[self addressForCue:cue action:@"patch"]];
}

- (void)cue:(QLKCue *)cue updatePlaybackPosition:(QLKCue *)playbackCue
{
  [self.client sendMessage:playbackCue.uid toAddress:[self addressForCue:cue action:@"playbackPositionId"]];
}

- (void)cue:(QLKCue *)cue updateStartNextCueWhenSliceEnds:(BOOL)start
{
  [self.client sendMessage:@(start) toAddress:[self addressForCue:cue action:@"startNextCueWhenSliceEnds"]];
}

- (void)cue:(QLKCue *)cue updateStopTargetWhenSliceEnds:(BOOL)stop
{
  [self.client sendMessage:@(stop) toAddress:[self addressForCue:cue action:@"stopTargetWhenSliceEnds"]];
}

#pragma mark - OSC Video methods

- (void)cue:(QLKCue *)cue updateSurfaceID:(NSInteger)surfaceID
{
  [self.client sendMessage:@(surfaceID) toAddress:[self addressForCue:cue action:@"surfaceID"]];
}

- (void)cue:(QLKCue *)cue updateFullScreen:(BOOL)fullScreen
{
  [self.client sendMessage:@(fullScreen) toAddress:[self addressForCue:cue action:@"fullScreen"]];
}

- (void)cue:(QLKCue *)cue updateTranslationX:(CGFloat)translationX
{
  [self.client sendMessage:@(translationX) toAddress:[self addressForCue:cue action:@"translationX"]];
}

- (void)cue:(QLKCue *)cue updateTranslationY:(CGFloat)translationY
{
  [self.client sendMessage:@(translationY) toAddress:[self addressForCue:cue action:@"translationY"]];
}

- (void)cue:(QLKCue *)cue updateScaleX:(CGFloat)scaleX
{
  [self.client sendMessage:@(scaleX) toAddress:[self addressForCue:cue action:@"scaleX"]];
}

- (void)cue:(QLKCue *)cue updateScaleY:(CGFloat)scaleY
{
  [self.client sendMessage:@(scaleY) toAddress:[self addressForCue:cue action:@"scaleY"]];
}

- (void)cue:(QLKCue *)cue updateRotationX:(CGFloat)rotationX
{
  [self.client sendMessage:@(rotationX) toAddress:[self addressForCue:cue action:@"rotationX"]];
}

- (void)cue:(QLKCue *)cue updateRotationY:(CGFloat)rotationY
{
  [self.client sendMessage:@(rotationY) toAddress:[self addressForCue:cue action:@"rotationY"]];
}

- (void)cue:(QLKCue *)cue updateRotationZ:(CGFloat)rotationZ
{
  [self.client sendMessage:@(rotationZ) toAddress:[self addressForCue:cue action:@"rotationZ"]];
}

- (void)cue:(QLKCue *)cue updatePreserveAspectRatio:(BOOL)preserve
{
  [self.client sendMessage:@(preserve) toAddress:[self addressForCue:cue action:@"preserveAspectRatio"]];
}

- (void)cue:(QLKCue *)cue updateLayer:(NSInteger)layer
{
  [self.client sendMessage:@(layer) toAddress:[self addressForCue:cue action:@"layer"]];
}

- (void)cue:(QLKCue *)cue updateOpacity:(CGFloat)opacity
{
  [self.client sendMessage:@(opacity) toAddress:[self addressForCue:cue action:@"opacity"]];
}

#pragma mark - OSC address helpers

- (NSString *)addressForCue:(QLKCue *)cue action:(NSString *)action
{
  return [NSString stringWithFormat:@"/cue_id/%@/%@", cue.uid, action];
}

- (NSString *)workspacePrefix
{
  return [NSString stringWithFormat:@"/workspace/%@", self.uniqueId];
}

#pragma mark - QLKClientDelegate

- (NSString *)workspaceID
{
  return self.uniqueId;
}

- (void)workspaceUpdated
{
  [self fetchCueLists];
}

- (void)cueUpdated:(NSString *)cueID
{
  QLKCue *cue = [self cueWithId:cueID];
  
  NSLog(@"update cue: %@", cue);
  
  if ([cue isGroup]) {
    [self fetchChildrenForCue:cue completion:^(id data) {
      NSMutableArray *children = [NSMutableArray array];
      
      for (NSDictionary *dict in data) {
        QLKCue *cue = [QLKCue cueWithDictionary:dict];
        [children addObject:cue];
      }
      
      cue.cues = children;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueUpdatedNotification object:cue];
        [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidUpdateCuesNotification object:self];
      });
    }];
  }
  
  if (cue) {
    [self fetchMainPropertiesForCue:cue];
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueNeedsUpdateNotification object:cue];
  }
}

- (void)cueUpdated:(NSString *)cueID withProperties:(NSDictionary *)properties
{
  QLKCue *cue = [self cueWithId:cueID];
  [cue updatePropertiesWithDictionary:properties];
}

- (void)playbackPositionUpdated:(NSString *)cueID
{
  QLKCue *cue = nil;
  
  if (cueID) {
    cue = [self cueWithId:cueID];
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidChangePlaybackPositionNotification object:cue];
  });
}

@end
