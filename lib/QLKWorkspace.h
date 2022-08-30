//
//  QLKWorkspace.h
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

#import <Foundation/Foundation.h>

#import "QLKClient.h"
#import "QLKCue.h"
#import "QLKDefines.h"
#import "QLKVersionNumber.h"
#import <F53OSC/F53OSC.h>


NS_ASSUME_NONNULL_BEGIN

// Notifications sent by workspaces
extern NSNotificationName const QLKWorkspaceDidUpdateNotification;
extern NSNotificationName const QLKWorkspaceDidUpdateSettingsNotification;
extern NSNotificationName const QLKWorkspaceDidUpdateAccessPermissionsNotification;
extern NSNotificationName const QLKWorkspaceDidUpdateLightDashboardNotification;
extern NSNotificationName const QLKWorkspaceDidConnectNotification;
extern NSNotificationName const QLKWorkspaceDidDisconnectNotification;
extern NSNotificationName const QLKWorkspaceConnectionErrorNotification;
extern NSNotificationName const QLKQLabDidUpdatePreferencesNotification;

@class QLKServer, QLKCue;


@interface QLKWorkspace : NSObject <QLKClientDelegate>

// Name of this workspace.
@property (nonatomic, copy, readonly) NSString *name;

// Name without the file extension, for cleaner presentation.
@property (nonatomic, copy, readonly) NSString *nameWithoutPathExtension;

// A unique internal ID.
@property (nonatomic, copy, readonly) NSString *uniqueID;

// The server (QLab machine) this workspace is on.
@property (nonatomic, readonly, nullable) QLKServer *server;

// Name of the server (QLab machine) this workspace is on.
@property (nonatomic, readonly, nullable) NSString *serverName;

// Name of this workspace and name of the server (QLab machine) this workspace is on.
@property (nonatomic, readonly) NSString *fullName;

// Name of this workspace with cue list name and name of the server (QLab machine) this workspace is on.
- (NSString *)fullNameWithCueList:(QLKCue *)cueList;

// The root cue is the parent of all the cues in this workspace.
@property (nonatomic, readonly) QLKCue *root;

@property (nonatomic, weak, readonly, nullable) QLKCue *firstCue;
@property (nonatomic, weak, readonly, nullable) QLKCue *firstCueList;

// Whether or not this workspace is protected by a passcode.
@property (nonatomic, readonly) BOOL hasPasscode;

// Cached passcode for this workspace after entered by user.
@property (nonatomic, strong, nullable) NSString *passcode;

// Whether we currently have a connection.
@property (atomic, readonly) BOOL connected;

// Whether we should wait to disconnect upon receiving a connection error from the client. Default is NO.
// When set to YES, this workspace will prevent the client from disconnecting upon receiving a client connection error. This workspace is then responsible for disconnecting/destroying the client as needed.
@property (nonatomic) BOOL attemptToReconnect;

// When unknown, default value is equivalent to version 3.0.0
@property (nonatomic, readonly) QLKVersionNumber *workspaceQLabVersion;

@property (nonatomic, readonly) BOOL connectedToQLab3;

@property (nonatomic) BOOL defaultSendUpdatesOSC;

// When set to YES, each new QLKCue object is immediately set to defer fetching cue properties (by sending the cue's workspace object a `deferFetchingPropertiesForCue:` after init). Default is NO.
@property (atomic) BOOL defaultDeferFetchingPropertiesForNewCues;

@property (nonatomic, readonly) dispatch_queue_t cuePropertiesQueue;


// workspace with QLKClient automatically configured to use the QLKServer `host` and `port` values
- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server;

// workspace with a given QLKClient (e.g. a customized subclass)
- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server client:(QLKClient *)client;

// update transient values from a dictionary (currently only the `name` and `hasPasscode` values are allowed to be changed after initial init). Returns YES if any value changed.
- (BOOL)updateWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict;

- (BOOL)isQLabWorkspaceVersionAtLeastVersion:(QLKVersionNumber *)version;

- (void)connectWithPasscode:(nullable NSString *)passcode completion:(nullable QLKMessageReplyBlock)completion;
- (void)finishConnection;
- (void)reconnect;
- (void)disconnect;
- (void)temporarilyDisconnect;

// In v5+, the reply payload from `/connect` determines these permissions. These properties are local hints only.
// QLab enforces the current access roles granted to each passcode as each OSC message is received.
@property (nonatomic, readonly) BOOL canView;
@property (nonatomic, readonly) BOOL canEdit;
@property (nonatomic, readonly) BOOL canControl;

- (nullable QLKCue *)cueWithID:(NSString *)uid;
- (nullable QLKCue *)cueWithNumber:(NSString *)number;

- (void)cueNeedsUpdate:(NSString *)cueID;

// QLab Server API
- (void)startReceivingUpdates;
- (void)stopReceivingUpdates;
- (void)enableAlwaysReply;
- (void)disableAlwaysReply;

- (void)fetchQLabVersionWithBlock:(nullable QLKMessageReplyBlock)block;
- (void)fetchCueLists;
- (void)fetchCueListsWithBlock:(nullable QLKMessageReplyBlock)block;
- (void)fetchPlaybackPositionForCue:(QLKCue *)cue block:(nullable QLKMessageReplyBlock)block;
- (void)go;
- (void)auditionGo; // v5.0+
- (void)save;
- (void)undo;
- (void)redo;
- (void)resetAll;
- (void)pauseAll;
- (void)resumeAll;
- (void)stopAll;
- (void)panicAll;

- (void)startHeartbeat;
- (void)stopHeartbeat;

// Cue actions
- (void)startCue:(QLKCue *)cue;
- (void)stopCue:(QLKCue *)cue;
- (void)pauseCue:(QLKCue *)cue;
- (void)loadCue:(QLKCue *)cue;
- (void)resetCue:(QLKCue *)cue;
- (void)deleteCue:(QLKCue *)cue;
- (void)resumeCue:(QLKCue *)cue;
- (void)hardStopCue:(QLKCue *)cue;
- (void)hardPauseCue:(QLKCue *)cue;
- (void)togglePauseCue:(QLKCue *)cue;
- (void)previewCue:(QLKCue *)cue;
- (void)auditionPreviewCue:(QLKCue *)cue; // v5.0+
- (void)panicCue:(QLKCue *)cue;

// NOTE: These methods bypass the defer/resume fetching mechanism and always immediately retrieve values.
- (void)cue:(QLKCue *)cue valueForKey:(NSString *)key block:(nullable QLKMessageReplyBlock)block;
- (void)cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys;
- (void)cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys block:(nullable QLKMessageReplyBlock)block;
- (void)cue:(QLKCue *)cue updatePropertySend:(nullable id)value forKey:(NSString *)key;
- (void)cue:(QLKCue *)cue updatePropertiesSend:(nullable NSArray *)values forKey:(NSString *)key;
- (void)updateAllCuePropertiesSendOSC;
- (void)runningOrPausedCuesWithBlock:(nullable QLKMessageReplyBlock)block;

// NOTE: These methods defer fetching values according to the defer/resumeFetchingProperties status of the cue.
- (void)fetchDefaultCueListPropertiesForCue:(QLKCue *)cue; // requests same properties returned by /cueLists method
- (void)fetchBasicPropertiesForCue:(QLKCue *)cue;
- (void)fetchNotesForCue:(QLKCue *)cue;
- (void)fetchDisplayAndGeometryForCue:(QLKCue *)cue;
- (void)fetchPropertiesForCue:(QLKCue *)cue keys:(NSArray<NSString *> *)keys includeChildren:(BOOL)includeChildren;

- (void)deferFetchingPropertiesForCue:(QLKCue *)cue;
- (void)resumeFetchingPropertiesForCue:(QLKCue *)cue;

// Workspace Settings

// Call `refreshVideoOutputsList` to populate.
// Will contain payload of `/video/settings/surfaces` on v4, payload of `/video/settings/stages` on v5.
// Workspace-level video output getters were added in v4, so always nil when connected to v3.
@property (nonatomic, nullable, readonly) NSArray<NSDictionary<NSString *, id> *> *videoOutputsList;

- (nullable NSDictionary<NSString *, id> *)surfaceDictForSurfaceID:(NSNumber *)surfaceID; // v4.x
- (nullable NSDictionary<NSString *, id> *)stageDictForStageID:(NSString *)stageID;       // v5.0+

// Lower level API
- (void)sendMessage:(nullable id)object toAddress:(NSString *)address;
- (void)sendMessage:(nullable id)object toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block;
- (void)sendApplicationMessageWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block;

// Helper for sending messages to this workspace: /workspace/{id}
@property (nonatomic, readonly, copy) NSString *workspacePrefix;

// Helper for sending messages to a specific cue: /cue_id/{cue_id}/action
- (NSString *)addressForCue:(QLKCue *)cue action:(NSString *)action;


// Deprecated in 0.0.5 - leaving for compatibility with QLabKit.objc 0.0.4
- (NSString *)addressForWildcardNumber:(NSString *)number action:(NSString *)action DEPRECATED_MSG_ATTRIBUTE("Use NSString -stringWithFormat: with the desired prefix 'cue' or 'cue_id' instead");

@end


// Deprecated in 0.0.5
DEPRECATED_MSG_ATTRIBUTE("Use QLKVersionNumber instead")
@interface QLKQLabWorkspaceVersion : QLKVersionNumber

- (NSComparisonResult)compare:(QLKVersionNumber *)otherVersion DEPRECATED_MSG_ATTRIBUTE("Use QLKVersionNumber -compare:ignoreBuild:YES instead");

@end

NS_ASSUME_NONNULL_END
