//
//  QLRConnection.h
//  QLab for iPad
//
//  Created by Zach Waugh on 5/12/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "F53OSC.h"

extern NSString * const QLRWorkspaceDidUpdateCuesNotification;
extern NSString * const QLRWorkspaceDidConnectNotification;
extern NSString * const QLRWorkspaceDidDisconnectNotification;
extern NSString * const QLRWorkspaceConnectionErrorNotification;
extern NSString * const QLRWorkspaceDidChangePlaybackPositionNotification;

@class QLRSlider, QLKServer;

@interface QLRWorkspace : NSObject <F53OSCPacketDestination, F53OSCClientDelegate>

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *uniqueId;
@property (strong, nonatomic) QLRCue *root;
@property (assign, nonatomic, getter=isConnected) BOOL connected;
@property (strong, readonly) QLKServer *server;
@property (assign, nonatomic) BOOL hasPasscode;

- (id)initWithDictionary:(NSDictionary *)dict server:(QLKServer *)server;

- (void)connect;
- (void)connectWithPasscode:(NSString *)passcode block:(QLRMessageHandlerBlock)block;
- (void)finishConnection;
- (void)disconnect;
- (void)temporarilyDisconnect;
- (void)reconnect;

- (NSString *)fullName;
- (NSString *)fullNameWithCueList:(QLRCue *)cueList;

- (QLRCue *)firstCue;
- (QLRCue *)firstCueList;
- (QLRCue *)cueWithId:(NSString *)uid;

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
- (void)fetchPlaybackPositionForCue:(QLRCue *)cue completion:(QLRMessageHandlerBlock)block;
- (void)startCue:(QLRCue *)cue;
- (void)stopCue:(QLRCue *)cue;
- (void)pauseCue:(QLRCue *)cue;
- (void)loadCue:(QLRCue *)cue;
- (void)resetCue:(QLRCue *)cue;
- (void)deleteCue:(QLRCue *)cue;
- (void)cue:(QLRCue *)cue valuesForKeys:(NSArray *)keys;
- (void)cue:(QLRCue *)cue updateName:(NSString *)name;
- (void)cue:(QLRCue *)cue updateNumber:(NSString *)number;
- (void)cue:(QLRCue *)cue updatePreWait:(float)preWait;
- (void)cue:(QLRCue *)cue updatePostWait:(float)postWait;
- (void)cue:(QLRCue *)cue updateDuration:(float)duration;
- (void)cue:(QLRCue *)cue updateArmed:(BOOL)armed;
- (void)cue:(QLRCue *)cue updateFlagged:(BOOL)flagged;
- (void)cue:(QLRCue *)cue updateNotes:(NSString *)notes;
- (void)cue:(QLRCue *)cue updateContinueMode:(QLRCueContinueMode)continueMode;
- (void)cue:(QLRCue *)cue updateChannel:(NSInteger)channel level:(double)level;
- (void)cue:(QLRCue *)cue updatePatch:(NSInteger)patch;
- (void)cue:(QLRCue *)cue updateColor:(NSString *)color;
- (void)cue:(QLRCue *)cue updateSurfaceID:(NSInteger)surfaceID;
- (void)cue:(QLRCue *)cue updateFullScreen:(BOOL)fullScreen;
- (void)cue:(QLRCue *)cue updateTranslationX:(CGFloat)originX;
- (void)cue:(QLRCue *)cue updateTranslationY:(CGFloat)originY;
- (void)cue:(QLRCue *)cue updateScaleX:(CGFloat)scaleX;
- (void)cue:(QLRCue *)cue updateScaleY:(CGFloat)scaleY;
- (void)cue:(QLRCue *)cue updateRotationX:(CGFloat)rotationX;
- (void)cue:(QLRCue *)cue updateRotationY:(CGFloat)rotationY;
- (void)cue:(QLRCue *)cue updateRotationZ:(CGFloat)rotationZ;
- (void)cue:(QLRCue *)cue updatePreserveAspectRatio:(BOOL)preserve;
- (void)cue:(QLRCue *)cue updatePlaybackPosition:(QLRCue *)playbackCue;
- (void)cue:(QLRCue *)cue updateLayer:(NSInteger)layer;
- (void)cue:(QLRCue *)cue updateOpacity:(CGFloat)opacity;
- (void)cue:(QLRCue *)cue updateStartNextCueWhenSliceEnds:(BOOL)start;
- (void)cue:(QLRCue *)cue updateStopTargetWhenSliceEnds:(BOOL)stop;

- (void)fetchMainPropertiesForCue:(QLRCue *)cue;
- (void)fetchBasicPropertiesForCue:(QLRCue *)cue;
- (void)fetchChildrenForCue:(QLRCue *)cue completion:(QLRMessageHandlerBlock)block;
- (void)fetchNotesForCue:(QLRCue *)cue;
- (void)fetchAudioLevelsForCue:(QLRCue *)cue completion:(QLRMessageHandlerBlock)block;
- (void)fetchDisplayAndGeometryForCue:(QLRCue *)cue;
- (void)runningOrPausedCuesWithBlock:(QLRMessageHandlerBlock)block;

@end
