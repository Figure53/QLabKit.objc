//
//  QLRConnection.m
//  QLab for iPad
//
//  Created by Zach Waugh on 5/12/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "QLKWorkspace.h"
#import "QLKCue.h"
#import "QLKServer.h"
#import "F53OSC.h"

#define HEARTBEAT_INTERVAL 5 // seconds
#define HEARTBEAT_FAILURE_INTERVAL 1 // seconds
#define HEARTBEAT_MAX_ATTEMPTS 5

#define DEBUG_OSC 0

NSString * const QLRWorkspaceDidUpdateCuesNotification = @"QLRWorkspaceDidUpdateCuesNotification";
NSString * const QLRWorkspaceDidConnectNotification = @"QLRWorkspaceConnectionDidConnectNotification";
NSString * const QLRWorkspaceDidDisconnectNotification = @"QLRWorkspaceConnectionDidDisconnectNotification";
NSString * const QLRWorkspaceConnectionErrorNotification = @"QLRWorkspaceTimeoutNotification";
NSString * const QLRWorkspaceDidChangePlaybackPositionNotification = @"QLRWorkspaceDidChangePlaybackPositionNotification";

@interface QLKWorkspace ()

@property (strong, readonly) F53OSCClient *client;
@property (strong, nonatomic) NSMutableDictionary *callbacks;
@property (strong) NSTimer *heartbeatTimeout;
@property (assign) NSInteger attempts;
@property (strong, nonatomic) NSString *passcode;

- (void)startHeartbeat;
- (void)stopHeartbeat;
- (void)clearHeartbeatTimeout;
- (void)sendHeartbeat;
- (void)heartbeatTimeout:(NSTimer *)timer;

- (NSString *)workspacePrefix;
- (NSString *)addressWithoutWorkspace:(NSString *)address;
- (NSString *)addressForCue:(QLKCue *)cue action:(NSString *)action;
- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address;
- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address block:(QLRMessageHandlerBlock)block;
- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address;
- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address block:(QLRMessageHandlerBlock)block;

@end

@implementation QLKWorkspace

- (id)init
{
  self = [super init];
  if (!self) return nil;

  _uniqueId = @"";
  _connected = NO;
  _attempts = 0;
  
  // Setup root cue - parent of cue lists
  _root = [[QLKCue alloc] init];
  _root.uid = QLRRootCueIdentifier;
  _root.name = @"Cue Lists";
  _root.type = QLRCueTypeGroup;
  
  _callbacks = [[NSMutableDictionary alloc] init];
  _hasPasscode = NO;

  return self;
}

- (id)initWithDictionary:(NSDictionary *)dict server:(QLKServer *)server
{
  self = [self init];
  if (!self) return nil;

  _name = dict[@"displayName"];
  _server = server;
  _client = [[F53OSCClient alloc] init];
  _client.host = server.client.host;
  _client.port = server.client.port;
  _client.useTcp = YES;
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
  return [NSString stringWithFormat:@"%@ (%@)", self.name, self.server.name];
}

- (NSString *)fullNameWithCueList:(QLKCue *)cueList
{
  return [NSString stringWithFormat:@"%@ - %@ (%@)", self.name, cueList.name, self.server.name];
}

#pragma mark - Connection/reconnection

- (void)connect
{
  NSLog(@"connect: %@, %@", self.name, self.server);
  
  [self connectToWorkspace];
  [self finishConnection];
}

- (void)connectWithPasscode:(NSString *)passcode block:(QLRMessageHandlerBlock)block;
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
  [[NSNotificationCenter defaultCenter] postNotificationName:QLRWorkspaceDidConnectNotification object:self];
}

- (void)disconnect
{
  NSLog(@"disconnect: %@", self.name);
  [self disconnectFromWorkspace];
  [self stopReceivingUpdates];
  self.connected = NO;
  [self.client disconnect];
  self.root.cues = nil;
  self.callbacks = [NSMutableDictionary dictionary];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:QLRWorkspaceDidDisconnectNotification object:self];
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
  [[NSNotificationCenter defaultCenter] postNotificationName:QLRWorkspaceConnectionErrorNotification object:self];
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

#pragma mark - OSC

#pragma mark - Workspace Methods

- (void)connectToWorkspace
{
  [self connectToWorkspaceWithPasscode:nil completion:nil];
}

- (void)connectToWorkspaceWithPasscode:(NSString *)passcode completion:(QLRMessageHandlerBlock)block
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
  
  [self sendMessage:passcode toAddress:@"/connect" block:^(id data) {
    if (block) block(data);
  }];
}

- (void)disconnectFromWorkspace
{
  [self sendMessage:nil toAddress:@"/disconnect"];
}

- (void)startReceivingUpdates
{
  [self sendMessage:@YES toAddress:@"/updates"];
}

- (void)stopReceivingUpdates
{
  [self sendMessage:@NO toAddress:@"/updates"];
}

- (void)enableAlwaysReply
{
  F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/alwaysReply" arguments:@[@YES]];
  [self.client sendPacket:message];
}

- (void)disableAlwaysReply
{
  F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:@"/alwaysReply" arguments:@[@NO]];
  [self.client sendPacket:message];
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
    activeCues.uid = QLRActiveCueListIdentifier;
    activeCues.name = @"Active Cues";
    activeCues.type = QLRCueTypeGroup;
    [children addObject:activeCues];
    
    self.root.cues = children;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:QLRWorkspaceDidUpdateCuesNotification object:self];
    });
  }];
}

- (void)fetchCueListsWithCompletion:(QLRMessageHandlerBlock)block
{
  [self sendMessage:nil toAddress:@"/cueLists" block:block];
}

- (void)fetchPlaybackPositionForCue:(QLKCue *)cue completion:(QLRMessageHandlerBlock)block
{
  [self sendMessage:nil toAddress:[self addressForCue:cue action:@"playbackPositionId"] block:block];
}

- (void)go
{
  [self sendMessage:nil toAddress:@"/go"];
}

- (void)stopAll
{
  [self sendMessage:nil toAddress:@"/stop"];
}

- (void)save
{
  [self sendMessage:nil toAddress:@"/save"];
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
  [self sendMessage:nil toAddress:@"/thump" block:^(id data) {
    [self clearHeartbeatTimeout];
    //NSLog(@"heartbeat received");
    
    // Ignore if we have manually disconnected while waiting for response
    if (self.isConnected) {
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
    [[NSNotificationCenter defaultCenter] postNotificationName:QLRWorkspaceConnectionErrorNotification object:self];
  }
}

#pragma mark - Cue Actions

- (void)startCue:(QLKCue *)cue
{
  [self sendMessage:nil toAddress:[self addressForCue:cue action:@"start"]];
}

- (void)stopCue:(QLKCue *)cue
{
  [self sendMessage:nil toAddress:[self addressForCue:cue action:@"stop"]];
}

- (void)pauseCue:(QLKCue *)cue
{
  [self sendMessage:nil toAddress:[self addressForCue:cue action:@"pause"]];
}

- (void)loadCue:(QLKCue *)cue
{
  [self sendMessage:nil toAddress:[self addressForCue:cue action:@"load"]];
}

- (void)resetCue:(QLKCue *)cue
{
  [self sendMessage:nil toAddress:[self addressForCue:cue action:@"reset"]];
}

- (void)deleteCue:(QLKCue *)cue
{
  [self sendMessage:nil toAddress:@"/delete"];
}

#pragma mark - Cue Getters

- (void)cue:(QLKCue *)cue valuesForKeys:(NSArray *)keys
{
  NSString *JSONKeys = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:keys options:0 error:nil] encoding:NSUTF8StringEncoding];
  [self sendMessage:JSONKeys toAddress:[self addressForCue:cue action:@"valuesForKeys"] block:nil];
}

- (void)fetchAudioLevelsForCue:(QLKCue *)cue completion:(QLRMessageHandlerBlock)block
{
  NSString *address = [self addressForCue:cue action:@"sliderLevels"];
  [self sendMessage:nil toAddress:address block:block];
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

- (void)fetchChildrenForCue:(QLKCue *)cue completion:(QLRMessageHandlerBlock)block
{
  NSString *address = [self addressForCue:cue action:@"children"];
  [self sendMessage:nil toAddress:address block:block];
}

- (void)runningOrPausedCuesWithBlock:(QLRMessageHandlerBlock)block
{
  [self sendMessages:nil toAddress:@"/runningOrPausedCues" block:block];
}

#pragma mark - Cue Setters

- (void)cue:(QLKCue *)cue updateName:(NSString *)name
{
  [self sendMessage:name toAddress:[self addressForCue:cue action:@"name"]];
}

- (void)cue:(QLKCue *)cue updateNotes:(NSString *)notes
{
  [self sendMessage:notes toAddress:[self addressForCue:cue action:@"notes"]];
}

- (void)cue:(QLKCue *)cue updateNumber:(NSString *)number
{
  [self sendMessage:number toAddress:[self addressForCue:cue action:@"number"]];
}

- (void)cue:(QLKCue *)cue updatePreWait:(float)preWait
{
  [self sendMessage:@(preWait) toAddress:[self addressForCue:cue action:@"preWait"]];
}

- (void)cue:(QLKCue *)cue updatePostWait:(float)postWait
{
  [self sendMessage:@(postWait) toAddress:[self addressForCue:cue action:@"postWait"]];
}

- (void)cue:(QLKCue *)cue updateDuration:(float)duration
{
  [self sendMessage:@(duration) toAddress:[self addressForCue:cue action:@"duration"]];
}

- (void)cue:(QLKCue *)cue updateArmed:(BOOL)armed
{
  [self sendMessage:@(armed) toAddress:[self addressForCue:cue action:@"armed"]];
}

- (void)cue:(QLKCue *)cue updateFlagged:(BOOL)flagged
{
  [self sendMessage:@(flagged) toAddress:[self addressForCue:cue action:@"flagged"]];
}

- (void)cue:(QLKCue *)cue updateColor:(NSString *)color
{
  [self sendMessage:color toAddress:[self addressForCue:cue action:@"colorName"]];
}

- (void)cue:(QLKCue *)cue updateContinueMode:(QLRCueContinueMode)continueMode
{
  [self sendMessage:@(continueMode) toAddress:[self addressForCue:cue action:@"continueMode"]];
}

- (void)cue:(QLKCue *)cue updateChannel:(NSInteger)channel level:(double)level
{
	NSArray *params = @[@(channel), @(level)];
  [self sendMessages:params toAddress:[self addressForCue:cue action:@"sliderLevel"]];
}

- (void)cue:(QLKCue *)cue updatePatch:(NSInteger)patch
{
  [self sendMessage:@(patch) toAddress:[self addressForCue:cue action:@"patch"]];
}

- (void)cue:(QLKCue *)cue updatePlaybackPosition:(QLKCue *)playbackCue
{
  [self sendMessage:playbackCue.uid toAddress:[self addressForCue:cue action:@"playbackPositionId"]];
}

- (void)cue:(QLKCue *)cue updateStartNextCueWhenSliceEnds:(BOOL)start
{
  [self sendMessage:@(start) toAddress:[self addressForCue:cue action:@"startNextCueWhenSliceEnds"]];
}

- (void)cue:(QLKCue *)cue updateStopTargetWhenSliceEnds:(BOOL)stop
{
  [self sendMessage:@(stop) toAddress:[self addressForCue:cue action:@"stopTargetWhenSliceEnds"]];
}

#pragma mark - OSC Video methods

- (void)cue:(QLKCue *)cue updateSurfaceID:(NSInteger)surfaceID
{
  [self sendMessage:@(surfaceID) toAddress:[self addressForCue:cue action:@"surfaceID"]];
}

- (void)cue:(QLKCue *)cue updateFullScreen:(BOOL)fullScreen
{
  [self sendMessage:@(fullScreen) toAddress:[self addressForCue:cue action:@"fullScreen"]];
}

- (void)cue:(QLKCue *)cue updateTranslationX:(CGFloat)translationX
{
  [self sendMessage:@(translationX) toAddress:[self addressForCue:cue action:@"translationX"]];
}

- (void)cue:(QLKCue *)cue updateTranslationY:(CGFloat)translationY
{
  [self sendMessage:@(translationY) toAddress:[self addressForCue:cue action:@"translationY"]];
}

- (void)cue:(QLKCue *)cue updateScaleX:(CGFloat)scaleX
{
  [self sendMessage:@(scaleX) toAddress:[self addressForCue:cue action:@"scaleX"]];
}

- (void)cue:(QLKCue *)cue updateScaleY:(CGFloat)scaleY
{
  [self sendMessage:@(scaleY) toAddress:[self addressForCue:cue action:@"scaleY"]];
}

- (void)cue:(QLKCue *)cue updateRotationX:(CGFloat)rotationX
{
  [self sendMessage:@(rotationX) toAddress:[self addressForCue:cue action:@"rotationX"]];
}

- (void)cue:(QLKCue *)cue updateRotationY:(CGFloat)rotationY
{
  [self sendMessage:@(rotationY) toAddress:[self addressForCue:cue action:@"rotationY"]];
}

- (void)cue:(QLKCue *)cue updateRotationZ:(CGFloat)rotationZ
{
  [self sendMessage:@(rotationZ) toAddress:[self addressForCue:cue action:@"rotationZ"]];
}

- (void)cue:(QLKCue *)cue updatePreserveAspectRatio:(BOOL)preserve
{
  [self sendMessage:@(preserve) toAddress:[self addressForCue:cue action:@"preserveAspectRatio"]];
}

- (void)cue:(QLKCue *)cue updateLayer:(NSInteger)layer
{
  [self sendMessage:@(layer) toAddress:[self addressForCue:cue action:@"layer"]];
}

- (void)cue:(QLKCue *)cue updateOpacity:(CGFloat)opacity
{
  [self sendMessage:@(opacity) toAddress:[self addressForCue:cue action:@"opacity"]];
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

- (NSString *)addressWithoutWorkspace:(NSString *)address
{
  if ([address hasPrefix:[self workspacePrefix]]) {
    return [address substringFromIndex:[[self workspacePrefix] length]];
  } else {
    return address;
  }
}

#pragma mark - OSC message senders

- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address
{
  [self sendMessage:message toAddress:address block:nil];
}

- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address block:(QLRMessageHandlerBlock)block
{
  NSArray *messages = (message != nil) ? @[message] : nil;
  [self sendMessages:messages toAddress:address block:block];
}

- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address
{
  [self sendMessages:messages toAddress:address block:nil];
}

- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address block:(QLRMessageHandlerBlock)block
{
  NSAssert(self.server != nil, @"Workspace has no server");
  NSAssert(self.client != nil, @"Server has no client");
  
  if (block) {
    self.callbacks[address] = block;
  }
  
  NSString *fullAddress = [NSString stringWithFormat:@"%@%@", [self workspacePrefix], address];
 
#if DEBUG_OSC
  NSLog(@"[OSC] to: %@, data: %@", fullAddress, messages);
#endif
  
  F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:fullAddress arguments:messages];
  [self.client sendPacket:message];
}

#pragma mark - F53OSCPacketDestination

- (void)takeMessage:(F53OSCMessage *)message
{
  [self processMessage:message];
}

#pragma mark - F53OSCClientDelegate

- (void)clientDidConnect:(F53OSCClient *)client
{
  NSLog(@"clientDidConnect: %@", client);
}

- (void)clientDidDisconnect:(F53OSCClient *)client
{
  NSLog(@"clientDidDisconnect: %@, connected? %d", client, self.connected);
  
  // Only care if we think we're connected
  if (self.connected) {
    [self notifyAboutConnectionError];
  }
}

#pragma mark - OSC processing

- (void)processMessage:(F53OSCMessage *)message
{
#if DEBUG_OSC
  NSLog(@"[osc] received message: %@", message);
#endif
  
  // Reply to a message we sent
  if ([message.addressPattern hasPrefix:@"/reply"]) {
    NSString *address = [self addressWithoutWorkspace:[message.addressPattern substringFromIndex:@"/reply".length]];
    NSString *body = message.arguments[0];
    NSError *error = nil;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    
    if (error) {
      NSLog(@"error decoding JSON: %@, %@", error, message.arguments);
    }
    
    id data = response[@"data"];
         
    if ([address hasPrefix:@"/cue_id"]) {
      NSString *cueId = [address componentsSeparatedByString:@"/"][2];
      QLKCue *cue = [self cueWithId:cueId];
      
      if ([data isKindOfClass:[NSDictionary class]]) {
        [cue updatePropertiesWithDict:data];
      }
    }
    
    QLRMessageHandlerBlock block = self.callbacks[address];
    
    if (block) {
			dispatch_async(dispatch_get_main_queue(), ^{
				block(data);
        
        // Clear handler for address
        [self.callbacks removeObjectForKey:address];
			});
    }
  } else if ([message.addressPattern hasPrefix:@"/update"]) {
    // QLab has informed us we need to update
    NSString *relativeAddress = message.addressPattern;
    id data = message.arguments;
    NSArray *parts = [relativeAddress pathComponents];

    if (parts.count == 4) {
      // Workspace updated - /update/workspace/<workspace_id>
      [self fetchCueLists];
    } else if (parts.count == 6) {
      // Individual cue updated - /update/workspace/<workspace_id>/cue_id/<cue_id>
      NSString *cueId = parts[5];
      QLKCue *cue = [self cueWithId:cueId];
    
      //NSLog(@"update cue: %@", cue);
      
      if ([cue isGroup]) {
        [self fetchChildrenForCue:cue completion:^(id data) {
          NSMutableArray *children = [NSMutableArray array];
          
          for (NSDictionary *dict in data) {
            QLKCue *cue = [QLKCue cueWithDictionary:dict];
            [children addObject:cue];
          }
          
          cue.cues = children;
          
          dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:QLRCueUpdatedNotification object:cue];
            [[NSNotificationCenter defaultCenter] postNotificationName:QLRWorkspaceDidUpdateCuesNotification object:self];
          });
        }];
      }
      
      if (cue) {
        [self fetchMainPropertiesForCue:cue];
        [[NSNotificationCenter defaultCenter] postNotificationName:QLRCueNeedsUpdateNotification object:cue];
      }
    } else if (parts.count == 7 && [relativeAddress hasSuffix:@"/playbackPosition"]) {
      // Special update, playback position has changed
      QLKCue *cue = nil;
      
      if ([data count] > 0) {
        cue = [self cueWithId:data[0]];
      }
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:QLRWorkspaceDidChangePlaybackPositionNotification object:cue];
      });
    } else if ([relativeAddress hasSuffix:@"/disconnect"]) {
      [self notifyAboutConnectionError];
    } else {
      NSLog(@"unhandled update message: %@", relativeAddress);
    }
  }
}

@end
