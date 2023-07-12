//
//  QLKWorkspace.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2022 Figure 53 LLC, https://figure53.com
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

#import <F53OSC/F53OSC.h>
#import <pthread.h>

#import "QLKClient.h"
#import "QLKCue.h"
#import "QLKServer.h"


#define HEARTBEAT_INTERVAL         5 // seconds
#define HEARTBEAT_FAILURE_INTERVAL 1 // seconds
#define HEARTBEAT_MAX_ATTEMPTS     5

NSNotificationName const QLKWorkspaceDidUpdateNotification = @"QLKWorkspaceDidUpdateNotification";
NSNotificationName const QLKWorkspaceDidUpdateSettingsNotification = @"QLKWorkspaceDidUpdateSettingsNotification";
NSNotificationName const QLKWorkspaceDidUpdateAccessPermissionsNotification = @"QLKWorkspaceDidUpdateAccessPermissionsNotification";
NSNotificationName const QLKWorkspaceDidUpdateLightDashboardNotification = @"QLKWorkspaceDidUpdateLightDashboardNotification";
NSNotificationName const QLKWorkspaceDidConnectNotification = @"QLKWorkspaceDidConnectNotification";
NSNotificationName const QLKWorkspaceDidDisconnectNotification = @"QLKWorkspaceDidDisconnectNotification";
NSNotificationName const QLKWorkspaceConnectionErrorNotification = @"QLKWorkspaceConnectionErrorNotification";
NSNotificationName const QLKQLabDidUpdatePreferencesNotification = @"QLKQLabDidUpdatePreferencesNotification";


NS_ASSUME_NONNULL_BEGIN

@interface QLKWorkspace ()
{
    pthread_mutex_t _deferredCueUpdatesMutex;
}

// Temporary cache of connection parameters.
@property (nonatomic, copy, nullable) NSString *connectionPasscode;
@property (nonatomic, copy, nullable) QLKMessageReplyBlock connectionCompletion;

@property (atomic, readwrite) BOOL connected;
@property (nonatomic, readwrite) BOOL canView;
@property (nonatomic, readwrite) BOOL canEdit;
@property (nonatomic, readwrite) BOOL canControl;

@property (nonatomic, nullable, readwrite) NSArray<NSDictionary<NSString *, id> *> *videoOutputsList;

@property (nonatomic, readonly) QLKClient *client;
@property (nonatomic, strong, nullable) NSTimer *heartbeatTimeout;
@property (nonatomic) NSInteger heartbeatAttempts;

@property (nonatomic, readonly) dispatch_queue_t replyBlockQueue;

@property (nonatomic, readonly) NSMapTable<QLKCue *, NSMutableSet *> *deferredCueUpdates;


- (void)notifyAboutDisconnection;
- (void)notifyAboutConnectionError;

- (void)disconnectFromWorkspace;

- (void)clearHeartbeatTimeout;
- (void)sendHeartbeat;
- (void)heartbeatTimeout:(NSTimer *)timer;

@end


@implementation QLKWorkspace

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _name = @"";
        _uniqueID = @"";
        _connected = NO;
        _heartbeatAttempts = -1; // not running

        _hasPasscode = NO;
        _defaultSendUpdatesOSC = NO;
        _defaultDeferFetchingPropertiesForNewCues = NO;

        _cuePropertiesQueue = dispatch_queue_create("com.figure53.QLabKit.cuePropertiesQueue", DISPATCH_QUEUE_SERIAL);
        _replyBlockQueue = dispatch_queue_create("com.figure53.QLabKit.replyBlockQueue", DISPATCH_QUEUE_SERIAL);

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

        // init workspace to QLab version "3.0.0" until we are told otherwise
        // NOTE: QLab 4 added the "version" key/value pair to the `/workspaces` payload
        // - so we assume the absense of a "version" string (nil or empty) to be a connection to QLab 3
        QLKVersionNumber *defaultVersion = [[QLKVersionNumber alloc] initWithString:@"3.0.0"];
        _workspaceQLabVersion = defaultVersion;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server
{
    QLKClient *client = [[QLKClient alloc] initWithHost:server.host port:server.port];
    client.useTCP = YES;
    return [self initWithDictionary:dict server:server client:client];
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server client:(QLKClient *)client
{
    self = [self init];
    if (self)
    {
        if (dict[QLKOSCUIDKey])
            _uniqueID = (NSString *)dict[QLKOSCUIDKey];

        if ([dict[@"version"] isKindOfClass:[NSString class]])
            _workspaceQLabVersion = [[QLKVersionNumber alloc] initWithString:(NSString *)dict[@"version"]];

        [self updateWithDictionary:dict];

        _server = server;
        _client = client;
    }
    return self;
}

- (BOOL)updateWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict
{
    BOOL didUpdate = NO;

    if (dict[@"displayName"] && [_name isEqual:dict[@"displayName"]] == NO)
    {
        _name = (NSString *)dict[@"displayName"];
        didUpdate = YES;
    }

    // v5 added multiple passcodes per workspace, so these workspaces always have "hasPasscode" as YES.
    // Only v3 and v4 workspaces include "hasPasscode" in their reply to `/workspaces`.
    if ([self.workspaceQLabVersion isNewerThanVersion:@"5.0 b0"])
    {
        if (!_hasPasscode)
        {
            _hasPasscode = YES;
            didUpdate = YES;
        }
    }
    else // v3 and v4 workspaces
    {
        if (_hasPasscode != [(NSNumber *)dict[@"hasPasscode"] boolValue])
        {
            _hasPasscode = [(NSNumber *)dict[@"hasPasscode"] boolValue];
            didUpdate = YES;
        }
    }

    return didUpdate;
}

- (void)dealloc
{
    self.client.delegate = nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@ : %@", super.description, self.name, self.uniqueID];
}

- (NSString *)nameWithoutPathExtension
{
    if ([self.name.lowercaseString.pathExtension isEqualToString:@"cues"] ||
        [self.name.lowercaseString.pathExtension isEqualToString:@"qlab4"] ||
        [self.name.lowercaseString.pathExtension isEqualToString:@"qlab5"])
        return self.name.stringByDeletingPathExtension;
    else
        return self.name;
}

- (nullable NSString *)serverName
{
    return self.server.name;
}

- (NSString *)fullName
{
    return [NSString stringWithFormat:@"%@ (%@)", self.name, self.server.name];
}

- (nullable QLKCue *)firstCue
{
    return self.firstCueList.firstCue;
}

- (nullable QLKCue *)firstCueList
{
    return self.root.firstCue;
}

- (NSString *)fullNameWithCueList:(QLKCue *)cueList
{
    return [NSString stringWithFormat:@"%@ - %@ (%@)", self.name, [cueList propertyForKey:QLKOSCNameKey], self.server.name];
}

- (BOOL)isQLabWorkspaceVersionAtLeastVersion:(QLKVersionNumber *)version
{
    NSComparisonResult result = [_workspaceQLabVersion compare:version ignoreBuild:YES];
    return (result != NSOrderedAscending);
}

- (BOOL)connectedToQLab3
{
    return (_workspaceQLabVersion.majorVersion == 3);
}


#pragma mark - Connection/reconnection

- (void)connectWithPasscode:(nullable NSString *)passcode completion:(nullable QLKMessageReplyBlock)completion
{
    self.client.delegate = self;

    // cache parameters
    self.connectionPasscode = passcode;
    self.connectionCompletion = completion;

    if (self.connected && self.client.isConnected)
    {
        [self finishConnectWithPasscode];
        return;
    }

    NSLog(@"[workspace] connecting...");

    self.canView = NO;
    self.canEdit = NO;
    self.canControl = NO;

    BOOL didInitateConnection = [self.client connect];
    if (didInitateConnection)
    {
        // If the client connects synchronously or is somehow already connected, finish the connection now.
        if (self.client.isConnected)
            [self finishConnectWithPasscode];

        // Otherwise for async client connections, the QLKClientDelegate `clientConnected:` implementation below will call `finishConnectWithPasscode`.
        // If connecting to QLab v5 or later, the callback is called after the client performs a successful encryption handshake with QLab.
    }
    else
    {
        NSLog(@"[workspace] *** Error: couldn't connect to server");

        self.client.delegate = nil;

        self.connectionPasscode = nil;
        self.connectionCompletion = nil;

        // Notify that we are unable to connect to workspace
        [self notifyAboutConnectionError];

        if (completion)
            completion(@"error", @"error");
    }
}

- (void)finishConnectWithPasscode
{
    NSString *passcode = self.connectionPasscode;

    // "No Passcode" in v5+ is empty string. Exit if we are here without a passcode.
    if (self.workspaceQLabVersion.majorVersion >= 5 && !passcode)
        return;

    QLKMessageReplyBlock completion = self.connectionCompletion;

    // Unset cached params. We try these once.
    self.connectionPasscode = nil;
    self.connectionCompletion = nil;

    __weak typeof(self) weakSelf = self;
    [self.client sendMessageWithArgument:passcode
                               toAddress:@"/connect"
                                   block:^(NSString *status, id _Nullable data) {
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       if (!strongSelf)
                                           return;

                                       if ([data isKindOfClass:[NSString class]] == NO)
                                           return;

                                       NSString *replyString = (NSString *)data;
                                       if ([replyString hasPrefix:@"ok"])
                                       {
                                           // upon success, update cached passcode to use for automatic reconnection
                                           if (strongSelf.hasPasscode)
                                               strongSelf.passcode = passcode;
                                           else
                                               strongSelf.passcode = nil;

                                           // Set local hints for access permission granted to this passcode.
                                           if (self.workspaceQLabVersion.majorVersion >= 5)
                                           {
                                               NSArray<NSString *> *components = @[]; // default to "none"
                                               if ([replyString hasPrefix:@"ok:"])
                                               {
                                                   NSString *permissions = [replyString substringFromIndex:3];
                                                   if (permissions)
                                                       components = [permissions componentsSeparatedByString:@"|"];
                                               }
                                               self.canView = [components containsObject:@"view"];
                                               self.canEdit = [components containsObject:@"edit"];
                                               self.canControl = [components containsObject:@"control"];
                                           }
                                           else // QLab 3 and 4 grant full access to any client.
                                           {
                                               self.canView = YES;
                                               self.canEdit = YES;
                                               self.canControl = YES;
                                           }

                                           NSLog(@"[workspace] connected successfully - view: %@, edit: %@, control: %@", self.canView ? @"Y" : @"N", self.canEdit ? @"Y" : @"N", self.canControl ? @"Y" : @"N");

                                           [strongSelf finishConnection];
                                       }
                                       else
                                       {
                                           strongSelf.client.delegate = nil;
                                           [strongSelf.client disconnect];

                                           if ([replyString isEqualToString:@"badpass"])
                                           {
                                               NSLog(@"[workspace] invalid passcode");
                                           }
                                           else
                                           {
                                               NSLog(@"[workspace] connection error: %@", data);
                                               [strongSelf notifyAboutConnectionError];
                                           }
                                       }

                                       if (completion)
                                           completion(status, data);
                                   }];
}

// Called when a connection is successfully made
- (void)finishConnection
{
    if (self.connected)
        return;

    pthread_mutex_init(&_deferredCueUpdatesMutex, NULL);

    self.connected = YES;
    [self startReceivingUpdates];
    [self fetchQLabVersionWithBlock:nil];
    [self fetchCueLists];
    [self refreshVideoOutputsList];

    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidConnectNotification object:self];
}

- (void)reconnect
{
    // Reconnect using the last-known passcode, e.g. when app wakes from sleep
    NSLog(@"[workspace] reconnecting...");
    [self connectWithPasscode:self.passcode completion:nil];
}

- (void)disconnect
{
    NSLog(@"[workspace] disconnect: %@", self.name);

    self.client.delegate = nil;
    [self stopHeartbeat];
    [self stopReceivingUpdates];

    [self disconnectFromWorkspace];

    self.connected = NO;

    self.canView = NO;
    self.canEdit = NO;
    self.canControl = NO;

    [self.client disconnect];

    [self.root removeAllChildCues];

    pthread_mutex_lock(&_deferredCueUpdatesMutex);
    [self.deferredCueUpdates removeAllObjects];
    pthread_mutex_unlock(&_deferredCueUpdatesMutex);

    pthread_mutex_destroy(&_deferredCueUpdatesMutex);
}

// Temporary disconnect when going to sleep
- (void)temporarilyDisconnect
{
    NSLog(@"[workspace] temp disconnect");

    [self disconnectFromWorkspace];
    [self stopHeartbeat];
    [self stopReceivingUpdates];

    self.connected = NO;

    [self.client disconnect];
}

- (void)notifyAboutDisconnection
{
    NSLog(@"[workspace] *** notifyAboutDisconnection");

    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceDidDisconnectNotification object:self];
}

- (void)notifyAboutConnectionError
{
    NSLog(@"[workspace] *** notifyAboutConnectionError");

    [[NSNotificationCenter defaultCenter] postNotificationName:QLKWorkspaceConnectionErrorNotification object:self];
}


#pragma mark - Cues

- (nullable QLKCue *)cueWithID:(NSString *)uid
{
    return [self.root cueWithID:uid];
}

- (nullable QLKCue *)cueWithNumber:(NSString *)number
{
    return [self.root cueWithNumber:number];
}


#pragma mark - Workspace Methods

- (void)cueNeedsUpdate:(NSString *)cueID
{
    QLKCue *cue = [self cueWithID:cueID];

    if (cue.isGroup)
    {
        __weak typeof(self) weakSelf = self;
        [self cue:cue
            valueForKey:@"children"
                  block:^(NSString *status, id _Nullable data) {
                      __strong typeof(weakSelf) strongSelf = weakSelf;
                      if (!strongSelf)
                          return;

                      if ([data isKindOfClass:[NSArray class]] == NO)
                          return;

                      [cue updateChildCuesWithPropertiesArray:(NSArray *)data removeUnused:YES];
                  }];
    }

    if (cue)
    {
        NSNotification *notification = [NSNotification notificationWithName:QLKCueNeedsUpdateNotification
                                                                     object:cue];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                   postingStyle:NSPostWhenIdle
                                                   coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                       forModes:@[NSRunLoopCommonModes]];
    }
}

- (void)disconnectFromWorkspace
{
    [self.client sendMessageWithArgument:nil toAddress:@"/disconnect"];
}

- (void)startReceivingUpdates
{
    [self.client sendMessageWithArgument:@YES toAddress:@"/updates"];
}

- (void)stopReceivingUpdates
{
    [self.client sendMessageWithArgument:@NO toAddress:@"/updates"];
}

- (void)enableAlwaysReply
{
    [self.client sendMessagesWithArguments:@[@YES] toAddress:@"/alwaysReply" workspace:NO block:nil];
}

- (void)disableAlwaysReply
{
    [self.client sendMessagesWithArguments:@[@NO] toAddress:@"/alwaysReply" workspace:NO block:nil];
}

- (void)fetchQLabVersionWithBlock:(nullable QLKMessageReplyBlock)block
{
    __weak typeof(self) weakSelf = self;
    [self.client sendMessagesWithArguments:nil
                                 toAddress:@"/version"
                                 workspace:NO
                                     block:^(NSString *status, id _Nullable data) {
                                         __strong typeof(weakSelf) strongSelf = weakSelf;
                                         if (!strongSelf)
                                             return;

                                         if ([data isKindOfClass:[NSString class]])
                                             strongSelf->_workspaceQLabVersion = [[QLKVersionNumber alloc] initWithString:(NSString *)data];

                                         if (block)
                                             block(status, data);
                                     }];
}

- (void)fetchCueLists
{
    __weak typeof(self) weakSelf = self;
    [self fetchCueListsWithBlock:^(NSString *status, id _Nullable data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        if (!strongSelf.connected)
            return;

        if ([data isKindOfClass:[NSArray class]] == NO)
            return;

        BOOL rootCueUpdated = NO;
        NSMutableArray<QLKCue *> *currentCueLists = [NSMutableArray arrayWithCapacity:((NSArray *)data).count];

        NSUInteger index = 0;
        for (NSDictionary<NSString *, NSObject<NSCopying> *> *aCueListDict in (NSArray *)data)
        {
            NSString *uid = (NSString *)aCueListDict[QLKOSCUIDKey];
            if (!uid)
                continue;

            QLKCue *cueList = [strongSelf.root cueWithID:uid includeChildren:NO];
            if (cueList)
            {
                if (cueList.sortIndex != index)
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
                if (strongSelf.workspaceQLabVersion.majorVersion == 3)
                    [cueList setProperty:QLKCueTypeCueList forKey:QLKOSCTypeKey];

                // allow notification observers to react to this new-found cue list
                NSNotification *notification = [NSNotification notificationWithName:QLKCueNeedsUpdateNotification
                                                                             object:cueList];
                [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                           postingStyle:NSPostWhenIdle
                                                           coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                               forModes:@[NSRunLoopCommonModes]];

                rootCueUpdated = YES;
            }
            [currentCueLists addObject:cueList];

            index++;
        }

        QLKCue *activeCuesList = [strongSelf.root cueWithID:QLKActiveCuesIdentifier includeChildren:NO];
        if (activeCuesList)
        {
            if (activeCuesList.sortIndex != index)
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


        if (strongSelf.root.cues.count != currentCueLists.count)
            rootCueUpdated = YES;

        [strongSelf.root setProperty:currentCueLists forKey:QLKOSCCuesKey tellQLab:NO];


        if (rootCueUpdated)
            [strongSelf.root enqueueCueUpdatedNotification];
    }];
}

- (void)fetchCueListsWithBlock:(nullable QLKMessageReplyBlock)block
{
    [self.client sendMessageWithArgument:nil toAddress:@"/cueLists" block:block];
}

- (void)fetchPlaybackPositionForCue:(QLKCue *)cue block:(nullable QLKMessageReplyBlock)block
{
    NSString *playbackPositionIDKey = (self.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4PlaybackPositionIdKey : QLKOSCPlaybackPositionIDKey);
    NSString *address = [self addressForCue:cue action:playbackPositionIDKey];
    [self.client sendMessageWithArgument:nil toAddress:address block:block];
}

- (void)go
{
    [self.client sendMessageWithArgument:nil toAddress:@"/go"];
}

- (void)auditionGo
{
    [self.client sendMessageWithArgument:nil toAddress:@"/auditionGo"];
}

- (void)save
{
    [self.client sendMessageWithArgument:nil toAddress:@"/save"];
}

- (void)undo
{
    [self.client sendMessageWithArgument:nil toAddress:@"/undo"];
}

- (void)redo
{
    [self.client sendMessageWithArgument:nil toAddress:@"/redo"];
}

- (void)resetAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/reset"];
}

- (void)pauseAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/pause"];
}

- (void)resumeAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/resume"];
}

- (void)stopAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/stop"];
}

- (void)panicAll
{
    [self.client sendMessageWithArgument:nil toAddress:@"/panic"];
}


#pragma mark - Heartbeat

- (void)startHeartbeat
{
    [self clearHeartbeatTimeout];
    [self sendHeartbeat];
}

- (void)stopHeartbeat
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
    [self clearHeartbeatTimeout];

    self.heartbeatAttempts = -1; // not running
}

- (void)clearHeartbeatTimeout
{
    [self.heartbeatTimeout invalidate];
    self.heartbeatTimeout = nil;

    self.heartbeatAttempts = 0;
}

- (void)sendHeartbeat
{
    //NSLog( @"sending heartbeat..." );

    __weak typeof(self) weakSelf = self;
    [self.client sendMessageWithArgument:nil
                               toAddress:@"/thump"
                                   block:^(NSString *status, id _Nullable data) {
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       if (!strongSelf)
                                           return;

                                       //NSLog( @"heartbeat received" );

                                       // exit if not running
                                       if (strongSelf.heartbeatAttempts == -1)
                                           return;

                                       [strongSelf clearHeartbeatTimeout];

                                       // Don't send if we have become disconnected while waiting for response
                                       if (!strongSelf.connected || !strongSelf.client.isConnected)
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

- (void)heartbeatTimeout:(NSTimer *)timer
{
    if (!timer.isValid)
        return;

    if (self.heartbeatAttempts == -1)
        return;

    // exit if workspace has disconnected while waiting for response
    if (!self.connected)
        return;

    // if timer fires before we receive a response from /thump,
    // - if we have attempts left, try sending again
    // - else post a connection error notification
    if (self.heartbeatAttempts < HEARTBEAT_MAX_ATTEMPTS)
    {
        self.heartbeatAttempts++;
        [self sendHeartbeat];
    }
    else
    {
        NSLog(@"Heartbeat failure: workspace may have died");
        [self notifyAboutConnectionError];
    }
}


#pragma mark - Cue Actions

- (void)startCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"start"]];

    // immediately update local state for snappier UI response
    [cue updatePropertiesWithDictionary:@{QLKOSCIsRunningKey: @YES}];
}

- (void)stopCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"stop"]];
}

- (void)pauseCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"pause"]];

    // immediately update local state for snappier UI response
    [cue updatePropertiesWithDictionary:@{QLKOSCIsPausedKey: @YES}];
}

- (void)loadCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"load"]];
}

- (void)resetCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"reset"]];
}

- (void)deleteCue:(QLKCue *)cue
{
    NSString *address = [NSString stringWithFormat:@"/delete_id/%@", cue.uid];
    [self.client sendMessageWithArgument:nil toAddress:address];
}

- (void)resumeCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"resume"]];
}

- (void)hardStopCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"hardStop"]];
}

- (void)hardPauseCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"hardPause"]];

    // immediately update local state for snappier UI response
    [cue updatePropertiesWithDictionary:@{QLKOSCIsPausedKey: @YES}];
}

- (void)togglePauseCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"togglePause"]];
}

- (void)previewCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"preview"]];
}

- (void)auditionPreviewCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"auditionPreview"]];
}

- (void)panicCue:(QLKCue *)cue
{
    [self.client sendMessageWithArgument:nil toAddress:[self addressForCue:cue action:@"panic"]];

    // immediately update local state for snappier UI response
    // NOTE: /isPanicking requires QLab 4.0+
    if (!self.connectedToQLab3)
    {
        [cue updatePropertiesWithDictionary:@{QLKOSCIsPanickingKey: @YES}];
        for (QLKCue *aCue in cue.cues)
        {
            if (aCue.isRunning)
                [aCue updatePropertiesWithDictionary:@{QLKOSCIsPanickingKey: @YES}];
        }
    }
}


#pragma mark - Cue Getters/Setters

- (void)cue:(QLKCue *)cue valueForKey:(NSString *)key block:(nullable QLKMessageReplyBlock)block
{
    [self.client sendMessageWithArgument:nil
                               toAddress:[self addressForCue:cue action:key]
                                   block:block];
}

- (void)cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys
{
    [self cue:cue valuesForKeys:keys block:nil];
}

- (void)cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys block:(nullable QLKMessageReplyBlock)block
{
    NSString *JSONKeys = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:keys options:0 error:nil] encoding:NSUTF8StringEncoding];
    [self.client sendMessageWithArgument:JSONKeys toAddress:[self addressForCue:cue action:@"valuesForKeys"] block:block];
}

- (void)cue:(QLKCue *)cue updatePropertySend:(nullable id)value forKey:(NSString *)key
{
    [self.client sendMessageWithArgument:value toAddress:[self addressForCue:cue action:key]];
}

- (void)cue:(QLKCue *)cue updatePropertiesSend:(nullable NSArray *)values forKey:(NSString *)key
{
    [self.client sendMessagesWithArguments:values toAddress:[self addressForCue:cue action:key]];
}

- (void)updateAllCuePropertiesSendOSC
{
    [self.root sendAllPropertiesToQLab];
}

- (void)runningOrPausedCuesWithBlock:(nullable QLKMessageReplyBlock)block
{
    [self.client sendMessagesWithArguments:nil toAddress:@"/runningOrPausedCues" block:block];
}


#pragma mark - Cue Property Fetching

- (void)fetchDefaultCueListPropertiesForCue:(QLKCue *)cue
{
    NSArray<NSString *> *keys;
    if (self.workspaceQLabVersion.majorVersion < 5)
        keys = @[QLKOSCUIDKey, QLKOSCNumberKey, QLKOSCNameKey, QLKOSCListNameKey, QLKOSCTypeKey, QLKOSCColorNameKey, QLKOSCFlaggedKey, QLKOSCArmedKey, QLKOSCNotesKey];
    else
        keys = @[QLKOSCUIDKey, QLKOSCNumberKey, QLKOSCNameKey, QLKOSCListNameKey, QLKOSCTypeKey, QLKOSCColorNameKey, QLKOSCLiveColorNameKey, QLKOSCFlaggedKey, QLKOSCArmedKey, QLKOSCNotesKey];
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void)fetchBasicPropertiesForCue:(QLKCue *)cue
{
    NSArray<NSString *> *keys;
    if (self.workspaceQLabVersion.majorVersion < 5)
        keys = @[QLKOSCNameKey, QLKOSCNumberKey, QLKOSCFileTargetKey, QLKOSCCueTargetNumberKey, QLKOSCHasFileTargetsKey, QLKOSCHasCueTargetsKey, QLKOSCArmedKey, QLKOSCColorNameKey, QLKOSCContinueModeKey, QLKOSCFlaggedKey, QLKOSCPreWaitKey, QLKOSCPostWaitKey, QLKOSCDurationKey, QLKOSCAllowsEditingDurationKey];
    else if (self.workspaceQLabVersion.majorVersion == 5 && self.workspaceQLabVersion.minorVersion <= 1)
        keys = @[QLKOSCNameKey, QLKOSCNumberKey, QLKOSCFileTargetKey, QLKOSCCueTargetNumberKey, QLKOSCHasFileTargetsKey, QLKOSCHasCueTargetsKey, QLKOSCArmedKey, QLKOSCColorNameKey, QLKOSCLiveColorNameKey, QLKOSCColorConditionKey, QLKOSCContinueModeKey, QLKOSCFlaggedKey, QLKOSCPreWaitKey, QLKOSCPostWaitKey, QLKOSCDurationKey, QLKOSCAllowsEditingDurationKey];
    else // v5.2+
        keys = @[QLKOSCNameKey, QLKOSCNumberKey, QLKOSCFileTargetKey, QLKOSCCueTargetNumberKey, QLKOSCHasFileTargetsKey, QLKOSCHasCueTargetsKey, QLKOSCArmedKey, QLKOSCColorNameKey, QLKOSCLiveColorNameKey, QLKOSCUseSecondColorKey, QLKOSCSecondColorNameKey, QLKOSCContinueModeKey, QLKOSCFlaggedKey, QLKOSCPreWaitKey, QLKOSCPostWaitKey, QLKOSCDurationKey, QLKOSCAllowsEditingDurationKey];
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void)fetchNotesForCue:(QLKCue *)cue
{
    NSArray<NSString *> *keys = @[QLKOSCNotesKey];
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void)fetchDisplayAndGeometryForCue:(QLKCue *)cue
{
    NSArray<NSString *> *keys;
    if (self.workspaceQLabVersion.majorVersion == 3)
    {
        // v3.x
        keys = @[QLKOSCFullScreenKey, QLKOSCV4TranslationXKey, QLKOSCV4TranslationYKey, QLKOSCV4ScaleXKey, QLKOSCV4ScaleYKey, QLKOSCV4OriginXKey, QLKOSCV4OriginYKey, QLKOSCLayerKey, QLKOSCOpacityKey, QLKOSCQuaternionKey, QLKOSCPreserveAspectRatioKey, QLKOSCCueSizeKey, QLKOSCSurfaceIDKey, QLKOSCSurfaceSizeKey, QLKOSCSurfaceListKey];
    }
    else if (self.workspaceQLabVersion.majorVersion == 4)
    {
        // v4.x
        keys = @[QLKOSCFullSurfaceKey, QLKOSCV4TranslationXKey, QLKOSCV4TranslationYKey, QLKOSCV4ScaleXKey, QLKOSCV4ScaleYKey, QLKOSCV4OriginXKey, QLKOSCV4OriginYKey, QLKOSCLayerKey, QLKOSCOpacityKey, QLKOSCQuaternionKey, QLKOSCPreserveAspectRatioKey, QLKOSCCueSizeKey, QLKOSCSurfaceIDKey];
    }
    else if (self.workspaceQLabVersion.majorVersion == 5 && self.workspaceQLabVersion.minorVersion == 0)
    {
        // v5.0.x
        keys = @[QLKOSCFillStageKey, QLKOSCTranslationXKey, QLKOSCTranslationYKey, QLKOSCScaleXKey, QLKOSCScaleYKey, QLKOSCOriginXKey, QLKOSCOriginYKey, QLKOSCLayerKey, QLKOSCOpacityKey, QLKOSCSmoothKey, QLKOSCQuaternionKey, QLKOSCPreserveAspectRatioKey, QLKOSCCueSizeKey, QLKOSCStageIDKey];
    }
    else if (self.workspaceQLabVersion.majorVersion == 5 && self.workspaceQLabVersion.minorVersion == 1)
    {
        // v5.1.x
        keys = @[QLKOSCFillStageKey, QLKOSCTranslationXKey, QLKOSCTranslationYKey, QLKOSCScaleXKey, QLKOSCScaleYKey, QLKOSCAnchorXKey, QLKOSCAnchorYKey, QLKOSCLayerKey, QLKOSCOpacityKey, QLKOSCSmoothKey, QLKOSCQuaternionKey, QLKOSCPreserveAspectRatioKey, QLKOSCCueSizeKey, QLKOSCStageIDKey];
    }
    else // v5.2+
    {
        keys = @[QLKOSCFillStageKey, QLKOSCTranslationXKey, QLKOSCTranslationYKey, QLKOSCScaleXKey, QLKOSCScaleYKey, QLKOSCAnchorXKey, QLKOSCAnchorYKey, QLKOSCLayerKey, QLKOSCOpacityKey, QLKOSCSmoothKey, QLKOSCQuaternionKey, QLKOSCPreserveAspectRatioKey, QLKOSCFillStyleKey, QLKOSCCueSizeKey, QLKOSCStageIDKey];
    }
    [self fetchPropertiesForCue:cue keys:keys includeChildren:NO];
}

- (void)fetchPropertiesForCue:(QLKCue *)cue keys:(NSArray<NSString *> *)keys includeChildren:(BOOL)includeChildren
{
    pthread_mutex_lock(&_deferredCueUpdatesMutex);
    NSMutableSet *currentKeys = [self.deferredCueUpdates objectForKey:cue];
    pthread_mutex_unlock(&_deferredCueUpdatesMutex);

    if (currentKeys)
    {
        [currentKeys addObjectsFromArray:keys];
        if (includeChildren)
            [currentKeys addObject:@"includeChildren"];
    }
    else
    {
        [self cue:cue valuesForKeys:keys block:nil];
    }

    if (!includeChildren)
        return;

    for (QLKCue *aCue in cue.cues)
    {
        [self fetchPropertiesForCue:aCue keys:keys includeChildren:includeChildren];
    }
}

- (void)deferFetchingPropertiesForCue:(QLKCue *)cue
{
    if (cue.isCueList || cue.isCueCart)
        return;

    // if currentKeys set does not exist, setObject with a new empty set to begin deferring
    // if currentKeys exists, already deferred -- do nothing
    pthread_mutex_lock(&_deferredCueUpdatesMutex);

    NSMutableSet *currentKeys = [self.deferredCueUpdates objectForKey:cue];
    if (!currentKeys)
    {
        currentKeys = [NSMutableSet setWithCapacity:0];
        [self.deferredCueUpdates setObject:currentKeys forKey:cue];
    }

    pthread_mutex_unlock(&_deferredCueUpdatesMutex);
}

- (void)resumeFetchingPropertiesForCue:(QLKCue *)cue
{
    pthread_mutex_lock(&_deferredCueUpdatesMutex);
    NSMutableSet *currentKeys = [self.deferredCueUpdates objectForKey:cue];
    [self.deferredCueUpdates removeObjectForKey:cue];
    pthread_mutex_unlock(&_deferredCueUpdatesMutex);

    if (currentKeys.count)
    {
        BOOL includeChildren = [currentKeys containsObject:@"includeChildren"];
        [currentKeys removeObject:@"includeChildren"];

        [self fetchPropertiesForCue:cue
                               keys:currentKeys.allObjects
                    includeChildren:includeChildren];
    }
}


#pragma mark - Workspace Settings

- (nullable NSDictionary<NSString *, id> *)surfaceDictForSurfaceID:(NSNumber *)surfaceID
{
    // Requires v4.0+ to populate `videoOutputsList` with reply payload from /settings/video/surfaces.
    if (self.workspaceQLabVersion.majorVersion < 4)
        return nil;

    for (NSDictionary<NSString *, id> *surfaceDict in self.videoOutputsList)
    {
        if ([surfaceDict[@"surfaceID"] isEqual:surfaceID])
            return surfaceDict;
    }

    // else
    return nil;
}

- (nullable NSDictionary<NSString *, id> *)stageDictForStageID:(NSString *)stageID
{
    // Requires v5.0+ to populate `videoOutputsList` with reply payload from /settings/video/stages.
    if (self.workspaceQLabVersion.majorVersion < 5)
        return nil;

    for (NSDictionary<NSString *, id> *stageDict in self.videoOutputsList)
    {
        if ([stageDict[@"uniqueID"] isEqual:stageID])
            return stageDict;
    }

    // else
    return nil;
}

- (void)refreshVideoOutputsList
{
    // /settings/video/* was added in v4.0
    if (self.workspaceQLabVersion.majorVersion < 4)
        return;

    NSString *address;
    if (self.workspaceQLabVersion.majorVersion == 4)
        address = @"/settings/video/surfaces";
    else // v5.0+
        address = @"/settings/video/stages";

    __weak typeof(self) weakSelf = self;
    [self.client sendMessageWithArgument:nil
                               toAddress:address
                                   block:^(NSString *status, id _Nullable data) {
                                       if ([data isKindOfClass:[NSArray class]] == NO)
                                           return;

                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       if (!strongSelf)
                                           return;

                                       if ([strongSelf.videoOutputsList isEqualToArray:data])
                                           return;

                                       strongSelf.videoOutputsList = data;

                                       NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateSettingsNotification
                                                                                                    object:strongSelf
                                                                                                  userInfo:@{@"settingsType": @"video"}];
                                       [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                                                  postingStyle:NSPostASAP
                                                                                  coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                                                      forModes:@[NSRunLoopCommonModes]];
                                   }];
}


#pragma mark - OSC address helpers

- (void)sendMessage:(nullable id)object toAddress:(NSString *)address
{
    [self sendMessage:object toAddress:address block:nil];
}

- (void)sendMessage:(nullable id)object toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block
{
    [self.client sendMessageWithArgument:object toAddress:address block:block];
}

- (void)sendApplicationMessageWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block
{
    [self.client sendMessagesWithArguments:arguments toAddress:address workspace:NO block:block];
}

- (NSString *)addressForCue:(QLKCue *)cue action:(NSString *)action
{
    return [NSString stringWithFormat:@"/cue_id/%@/%@", cue.uid, action];
}

- (NSString *)workspacePrefix
{
    return [NSString stringWithFormat:@"/workspace/%@", self.uniqueID];
}


#pragma mark - QLKClientDelegate

- (NSString *)workspaceIDForClient:(QLKClient *)client
{
    if (client != self.client)
        return @"";

    return self.uniqueID;
}

- (void)clientConnected:(QLKClient *)client
{
    if (client != self.client)
        return;

    // NSLog(@"[workspace] *** clientConnected:");

    [self finishConnectWithPasscode];
}

- (void)clientConnectionErrorOccurred:(QLKClient *)client
{
    if (client != self.client)
        return;

    if (!self.connected)
        return;

    NSLog(@"[workspace] *** Error: clientConnectionErrorOccurred:");

    [self notifyAboutConnectionError];
}

- (void)clientWorkspaceUpdated:(QLKClient *)client
{
    if (client != self.client)
        return;

    [self fetchCueLists];

    NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateNotification
                                                                 object:self
                                                               userInfo:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                   forModes:@[NSRunLoopCommonModes]];
}

- (void)client:(QLKClient *)client workspaceSettingsUpdated:(NSString *)settingsType
{
    if (client != self.client)
        return;

    NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateSettingsNotification
                                                                 object:self
                                                               userInfo:@{@"settingsType": settingsType}];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                   forModes:@[NSRunLoopCommonModes]];

    if ([settingsType isEqualToString:@"video"])
    {
        [self refreshVideoOutputsList];
    }
    else if ([settingsType isEqualToString:@"network.access.osc"]) // v5+
    {
        BOOL wasCanView = self.canView;
        BOOL wasCanEdit = self.canEdit;
        BOOL wasCanControl = self.canControl;

        // Reconnect using the last-known passcode so that we can update our local access permission hints if needed.
        __weak typeof(self) weakSelf = self;
        [self connectWithPasscode:self.passcode
                       completion:^(NSString *status, id _Nullable data) {
                           __strong typeof(weakSelf) strongSelf = weakSelf;
                           if (!strongSelf)
                               return;

                           // NOTE: `connectWithPasscode:completion:` updates the QLKWorkspace permission properties prior to calling this completion.

                           if (strongSelf.canView == wasCanView &&
                               strongSelf.canEdit == wasCanEdit &&
                               strongSelf.canControl == wasCanControl)
                               return; // no change, nothing more to do

                           // else post notification that permissions have changed
                           NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateAccessPermissionsNotification
                                                                                        object:self
                                                                                      userInfo:nil];
                           [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                                      postingStyle:NSPostASAP
                                                                      coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                                          forModes:@[NSRunLoopCommonModes]];
                       }];
    }
}

- (void)client:(QLKClient *)client cueNeedsUpdate:(NSString *)cueID
{
    if (client != self.client)
        return;

    [self cueNeedsUpdate:cueID];
}

- (void)client:(QLKClient *)client cueUpdated:(NSString *)cueID withProperties:(NSDictionary<NSString *, NSObject<NSCopying> *> *)properties
{
    if (client != self.client)
        return;

    QLKCue *cue = [self cueWithID:cueID];
    if (!cue || cue.ignoreUpdates)
        return;

    dispatch_async(self.replyBlockQueue, ^{
        [cue updatePropertiesWithDictionary:properties];
    });
}

- (void)client:(QLKClient *)client cueListUpdated:(NSString *)cueListID withPlaybackPositionID:(nullable NSString *)cueID
{
    if (client != self.client)
        return;

    QLKCue *cueList = [self cueWithID:cueListID];
    if (!cueList || cueList.ignoreUpdates)
        return;

    dispatch_async(self.replyBlockQueue, ^{
        [cueList setPlaybackPositionID:cueID tellQLab:NO];
    });
}

- (void)clientWorkspaceDisconnected:(QLKClient *)client
{
    if (client != self.client)
        return;

    if (!self.connected)
        return;

    NSLog(@"[workspace] *** clientWorkspaceDisconnected:");

    [self disconnect];
    [self notifyAboutDisconnection];
}

- (BOOL)shouldEncryptConnectionsForClient:(QLKClient *)client
{
    if (client != self.client)
        return NO;

    return (self.workspaceQLabVersion.majorVersion >= 5);
}

- (BOOL)clientShouldDisconnectOnError:(QLKClient *)client
{
    if (client != self.client)
        return NO;

    NSLog(@"[workspace] *** clientShouldDisconnectOnError:");

    if (!self.server)
        return YES;

    if (!self.attemptToReconnect)
        return YES;

    // else
    return NO;
}

- (void)clientLightDashboardUpdated:(QLKClient *)client
{
    if (client != self.client)
        return;

    // NOTE: Dashboard updates require a connection to QLab 4.2+
    NSNotification *notification = [NSNotification notificationWithName:QLKWorkspaceDidUpdateLightDashboardNotification
                                                                 object:self
                                                               userInfo:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                   forModes:@[NSRunLoopCommonModes]];
}

- (void)client:(QLKClient *)client preferencesUpdated:(NSString *)key
{
    if (client != self.client)
        return;

    // NOTE: Preferences updates require a connection to QLab 4.2+
    NSNotification *notification = [NSNotification notificationWithName:QLKQLabDidUpdatePreferencesNotification
                                                                 object:self
                                                               userInfo:@{@"preferencesKey": key}];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP
                                               coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                   forModes:@[NSRunLoopCommonModes]];
}

#pragma mark - deprecated

- (NSString *)addressForWildcardNumber:(NSString *)number action:(NSString *)action
{
    return [NSString stringWithFormat:@"/cue/%@/%@", number, action];
}

@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation QLKQLabWorkspaceVersion

- (instancetype)initWithMajorVersion:(NSUInteger)major minor:(NSUInteger)minor patch:(NSUInteger)patch build:(nullable NSString *)build
{
    return [super initWithMajorVersion:major minor:minor patch:patch build:nil];
}

- (NSComparisonResult)compare:(QLKVersionNumber *)otherVersion
{
    return [self compare:otherVersion ignoreBuild:YES];
}

@end
#pragma clang diagnostic pop

NS_ASSUME_NONNULL_END
