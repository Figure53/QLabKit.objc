//
//  QLRConnection.h
//  QLab for iPad
//
//  Created by Zach Waugh on 5/12/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "F53OSC.h"
#import "QLKCue.h"
#import "QLKClient.h"
#import "QLKDefines.h"

extern NSString * const QLRWorkspaceDidUpdateCuesNotification;
extern NSString * const QLRWorkspaceDidConnectNotification;
extern NSString * const QLRWorkspaceDidDisconnectNotification;
extern NSString * const QLRWorkspaceConnectionErrorNotification;
extern NSString * const QLRWorkspaceDidChangePlaybackPositionNotification;

@class QLKServer;

@interface QLKWorkspace : NSObject <QLKClientDelegate>

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *uniqueId;
@property (strong, nonatomic) NSString *serverName;
@property (strong, nonatomic) QLKCue *root;
@property (assign, nonatomic) BOOL hasPasscode;
@property (assign, nonatomic) BOOL connected;

- (id)initWithDictionary:(NSDictionary *)dict server:(QLKServer *)server;

- (void)connect;
- (void)connectWithPasscode:(NSString *)passcode block:(QLRMessageHandlerBlock)block;
- (void)finishConnection;
- (void)disconnect;
- (void)temporarilyDisconnect;
- (void)reconnect;

- (NSString *)fullName;
- (NSString *)fullNameWithCueList:(QLKCue *)cueList;

- (QLKCue *)firstCue;
- (QLKCue *)firstCueList;
- (QLKCue *)cueWithId:(NSString *)uid;

- (void)processMessage:(F53OSCMessage *)message;

// QLab Server API
- (void)connectToWorkspace;
- (void)connectToWorkspaceWithPasscode:(NSString *)passcode completion:(QLRMessageHandlerBlock)block;
- (void)disconnectFromWorkspace;
- (void)startReceivingUpdates;
- (void)stopReceivingUpdates;
- (void)enableAlwaysReply;
- (void)disableAlwaysReply;
- (void)go;
- (void)stopAll;
- (void)save;
- (void)fetchCueLists;
- (void)fetchCueListsWithCompletion:(QLRMessageHandlerBlock)block;
- (void)fetchPlaybackPositionForCue:(QLKCue *)cue completion:(QLRMessageHandlerBlock)block;
- (void)startCue:(QLKCue *)cue;
- (void)stopCue:(QLKCue *)cue;
- (void)pauseCue:(QLKCue *)cue;
- (void)loadCue:(QLKCue *)cue;
- (void)resetCue:(QLKCue *)cue;
- (void)deleteCue:(QLKCue *)cue;
- (void)cue:(QLKCue *)cue valuesForKeys:(NSArray *)keys;
- (void)cue:(QLKCue *)cue updateName:(NSString *)name;
- (void)cue:(QLKCue *)cue updateNumber:(NSString *)number;
- (void)cue:(QLKCue *)cue updatePreWait:(float)preWait;
- (void)cue:(QLKCue *)cue updatePostWait:(float)postWait;
- (void)cue:(QLKCue *)cue updateDuration:(float)duration;
- (void)cue:(QLKCue *)cue updateArmed:(BOOL)armed;
- (void)cue:(QLKCue *)cue updateFlagged:(BOOL)flagged;
- (void)cue:(QLKCue *)cue updateNotes:(NSString *)notes;
- (void)cue:(QLKCue *)cue updateContinueMode:(QLRCueContinueMode)continueMode;
- (void)cue:(QLKCue *)cue updateChannel:(NSInteger)channel level:(double)level;
- (void)cue:(QLKCue *)cue updatePatch:(NSInteger)patch;
- (void)cue:(QLKCue *)cue updateColor:(NSString *)color;
- (void)cue:(QLKCue *)cue updateSurfaceID:(NSInteger)surfaceID;
- (void)cue:(QLKCue *)cue updateFullScreen:(BOOL)fullScreen;
- (void)cue:(QLKCue *)cue updateTranslationX:(CGFloat)originX;
- (void)cue:(QLKCue *)cue updateTranslationY:(CGFloat)originY;
- (void)cue:(QLKCue *)cue updateScaleX:(CGFloat)scaleX;
- (void)cue:(QLKCue *)cue updateScaleY:(CGFloat)scaleY;
- (void)cue:(QLKCue *)cue updateRotationX:(CGFloat)rotationX; 
- (void)cue:(QLKCue *)cue updateRotationY:(CGFloat)rotationY;
- (void)cue:(QLKCue *)cue updateRotationZ:(CGFloat)rotationZ;
- (void)cue:(QLKCue *)cue updatePreserveAspectRatio:(BOOL)preserve;
- (void)cue:(QLKCue *)cue updatePlaybackPosition:(QLKCue *)playbackCue;
- (void)cue:(QLKCue *)cue updateLayer:(NSInteger)layer;
- (void)cue:(QLKCue *)cue updateOpacity:(CGFloat)opacity;
- (void)cue:(QLKCue *)cue updateStartNextCueWhenSliceEnds:(BOOL)start;
- (void)cue:(QLKCue *)cue updateStopTargetWhenSliceEnds:(BOOL)stop;

- (void)fetchMainPropertiesForCue:(QLKCue *)cue;
- (void)fetchBasicPropertiesForCue:(QLKCue *)cue;
- (void)fetchChildrenForCue:(QLKCue *)cue completion:(QLRMessageHandlerBlock)block;
- (void)fetchNotesForCue:(QLKCue *)cue;
- (void)fetchAudioLevelsForCue:(QLKCue *)cue completion:(QLRMessageHandlerBlock)block;
- (void)fetchDisplayAndGeometryForCue:(QLKCue *)cue;
- (void)runningOrPausedCuesWithBlock:(QLRMessageHandlerBlock)block;

@end
