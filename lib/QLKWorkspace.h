//
//  QLKWorkspace.h
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

@import Foundation;

#import "F53OSC.h"
#import "QLKCue.h"
#import "QLKClient.h"
#import "QLKDefines.h"


NS_ASSUME_NONNULL_BEGIN

// Notifications sent by workspaces
extern NSString * const QLKWorkspaceDidUpdateNotification;
extern NSString * const QLKWorkspaceDidUpdateSettingsNotification;
extern NSString * const QLKWorkspaceDidUpdateLightDashboardNotification;
extern NSString * const QLKWorkspaceDidConnectNotification;
extern NSString * const QLKWorkspaceDidDisconnectNotification;
extern NSString * const QLKWorkspaceConnectionErrorNotification;
extern NSString * const QLKQLabDidUpdatePreferencesNotification;

@class QLKServer, QLKCue;


@interface QLKQLabWorkspaceVersion : NSObject

@property (nonatomic, readonly)     NSInteger majorVersion;
@property (nonatomic, readonly)     NSInteger minorVersion;
@property (nonatomic, readonly)     NSInteger patchVersion;

+ (instancetype) versionWithString:(NSString *)versionString;
- (instancetype) initWithString:(NSString *)versionString NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *stringValue;

- (NSComparisonResult) compare:(QLKQLabWorkspaceVersion *)otherVersion;

- (BOOL) isOlderThanVersion:(NSString *)version;
- (BOOL) isEqualToVersion:(NSString *)version;
- (BOOL) isNewerThanVersion:(NSString *)version;

@end


@interface QLKWorkspace : NSObject <QLKClientDelegate>

// Name of this workspace
@property (copy, nonatomic, readonly)               NSString *name;

// Name without the ".cues" extension, for cleaner presentation
@property (copy, nonatomic, readonly)               NSString *nameWithoutPathExtension;

// A unique internal ID
@property (copy, nonatomic, readonly)               NSString *uniqueID;

// The server (QLab machine) this workspace is on
@property (strong, nonatomic, readonly, nullable)   QLKServer *server;

// Name of the server (QLab machine) this workspace is on
@property (strong, nonatomic, readonly, nullable)   NSString *serverName;

// Name of this workspace and name of the server (QLab machine) this workspace is on
@property (nonatomic, readonly)                     NSString *fullName;

// Name of this workspace with cue list name and name of the server (QLab machine) this workspace is on
- (NSString *) fullNameWithCueList:(QLKCue *)cueList;

// The root cue is the parent of all the cues in this workspace
@property (strong, nonatomic, readonly)             QLKCue *root;

@property (weak, nonatomic, readonly, nullable)     QLKCue *firstCue;
@property (weak, nonatomic, readonly, nullable)     QLKCue *firstCueList;

// Whether or not this workspace is protected by a passcode
@property (assign, nonatomic, readonly)             BOOL hasPasscode;

// Cached passcode for this workspace after entered by user
@property (strong, nonatomic, nullable)             NSString *passcode;

// Whether we currently have a connection
@property (atomic, readonly)                        BOOL connected;

// Whether we should wait to disconnect upon receiving a connection error from the client. Default is NO
// When set to YES, this workspace will prevent the client from disconnecting upon receiving a client connection error. This workspace is then responsible for disconnecting/destroying the client as needed.
@property (nonatomic)                               BOOL attemptToReconnect;

// When unknown, default value is equivalent to version 3.0.0
@property (nonatomic, strong, readonly)             QLKQLabWorkspaceVersion *workspaceQLabVersion;

@property (nonatomic, readonly)                     BOOL connectedToQLab3;

@property (nonatomic)                               BOOL defaultSendUpdatesOSC;

// When set to YES, each new QLKCue object is immediately set to defer fetching cue properties (by sending the cue's workspace object a `deferFetchingPropertiesForCue:` after init). Default is NO.
@property (atomic)                                  BOOL defaultDeferFetchingPropertiesForNewCues;

@property (nonatomic, strong, readonly)             dispatch_queue_t cuePropertiesQueue;


// workspace with QLKClient automatically configured to use the QLKServer `host` and `port` values
- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server;

// workspace with a given QLKClient (e.g. a customized subclass)
- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict server:(QLKServer *)server client:(QLKClient *)client;

// update transient values from a dictionary (currently only the `name` and `hasPasscode` values are allowed to be changed after initial init). Returns YES if any value changed.
- (BOOL) updateWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict;

- (BOOL) isQLabWorkspaceVersionAtLeastVersion:(QLKQLabWorkspaceVersion *)version;

- (void) connectWithPasscode:(nullable NSString *)passcode completion:(nullable QLKMessageHandlerBlock)completion;
- (void) finishConnection;
- (void) reconnect;
- (void) disconnect;
- (void) temporarilyDisconnect;

- (nullable QLKCue *) cueWithID:(NSString *)uid;
- (nullable QLKCue *) cueWithNumber:(NSString *)number;

// QLab Server API
- (void) startReceivingUpdates;
- (void) stopReceivingUpdates;
- (void) enableAlwaysReply;
- (void) disableAlwaysReply;
- (void) fetchQLabVersionWithBlock:(nullable QLKMessageHandlerBlock)block;
- (void) fetchCueLists;
- (void) fetchCueListsWithBlock:(nullable QLKMessageHandlerBlock)block;
- (void) fetchPlaybackPositionForCue:(QLKCue *)cue block:(nullable QLKMessageHandlerBlock)block;
- (void) go;
- (void) save;
- (void) undo;
- (void) redo;
- (void) resetAll;
- (void) pauseAll;
- (void) resumeAll;
- (void) stopAll;
- (void) panicAll;

- (void) startHeartbeat;
- (void) stopHeartbeat;

- (void) startCue:(QLKCue *)cue;
- (void) stopCue:(QLKCue *)cue;
- (void) pauseCue:(QLKCue *)cue;
- (void) loadCue:(QLKCue *)cue;
- (void) resetCue:(QLKCue *)cue;
- (void) deleteCue:(QLKCue *)cue;
- (void) resumeCue:(QLKCue *)cue;
- (void) hardStopCue:(QLKCue *)cue;
- (void) hardPauseCue:(QLKCue *)cue;
- (void) togglePauseCue:(QLKCue *)cue;
- (void) previewCue:(QLKCue *)cue;
- (void) panicCue:(QLKCue *)cue;

// NOTE: these methods bypass the defer/resume fetching mechanism and always immediately retrieve values
- (void) cue:(QLKCue *)cue valueForKey:(NSString *)key block:(nullable QLKMessageHandlerBlock)block;
- (void) cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys;
- (void) cue:(QLKCue *)cue valuesForKeys:(NSArray<NSString *> *)keys block:(nullable QLKMessageHandlerBlock)block;
- (void) cue:(QLKCue *)cue updatePropertySend:(nullable id)value forKey:(NSString *)key;
- (void) cue:(QLKCue *)cue updatePropertiesSend:(nullable NSArray *)values forKey:(NSString *)key;
- (void) updateAllCuePropertiesSendOSC;
- (void) runningOrPausedCuesWithBlock:(nullable QLKMessageHandlerBlock)block;

// NOTE: these methods defer fetching values according to the defer/resumeFetchingProperties status of the cue
- (void) fetchDefaultCueListPropertiesForCue:(QLKCue *)cue; // requests same properties returned by /cueLists method
- (void) fetchBasicPropertiesForCue:(QLKCue *)cue;
- (void) fetchNotesForCue:(QLKCue *)cue;
- (void) fetchDisplayAndGeometryForCue:(QLKCue *)cue;
- (void) fetchPropertiesForCue:(QLKCue *)cue keys:(NSArray<NSString *> *)keys includeChildren:(BOOL)includeChildren;

- (void) deferFetchingPropertiesForCue:(QLKCue *)cue;
- (void) resumeFetchingPropertiesForCue:(QLKCue *)cue;


// Lower level API
- (void) sendMessage:(nullable id)object toAddress:(NSString *)address;
- (void) sendMessage:(nullable id)object toAddress:(NSString *)address block:(nullable QLKMessageHandlerBlock)block;
- (void) sendApplicationMessageWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address block:(nullable QLKMessageHandlerBlock)block;

// Helper for sending messages to this workspace: /workspace/<workspace_id>
@property (nonatomic, readonly, copy)               NSString *workspacePrefix;

// Helper for sending message to a specific cue: /cue_id/<cue.uid>/action
- (NSString *) addressForCue:(QLKCue *)cue action:(NSString *)action;

// Helper for sending messages to a wildcarded cue number: /cue/<number>/action
- (NSString *) addressForWildcardNumber:(NSString *)number action:(NSString *)action;



// Deprecated in 0.0.4 - leaving for compatibility with QLabKit.objc 0.0.3
- (void) connect DEPRECATED_MSG_ATTRIBUTE("Use -connectWithPasscode:completion: instead");
- (void) fetchChildrenForCue:(QLKCue *)cue block:(nullable QLKMessageHandlerBlock)block DEPRECATED_MSG_ATTRIBUTE("Use -cue:valueForKey:block: with key @\"children\" instead");
- (void) fetchAudioLevelsForCue:(QLKCue *)cue block:(nullable QLKMessageHandlerBlock)block DEPRECATED_MSG_ATTRIBUTE("Use -cue:valueForKey:block: with key @\"sliderLevels\" instead");

@end

NS_ASSUME_NONNULL_END
