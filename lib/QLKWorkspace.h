//
//  QLKWorkspace.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013 Figure 53 LLC, http://figure53.com
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
#import "F53OSC.h"
#import "QLKCue.h"
#import "QLKClient.h"
#import "QLKDefines.h"

// Notifications sent by workspaces
extern NSString * const QLKWorkspaceDidUpdateCuesNotification;
extern NSString * const QLKWorkspaceDidConnectNotification;
extern NSString * const QLKWorkspaceDidDisconnectNotification;
extern NSString * const QLKWorkspaceConnectionErrorNotification;
extern NSString * const QLKWorkspaceDidChangePlaybackPositionNotification;

@class QLKServer;

@interface QLKWorkspace : NSObject <QLKClientDelegate>

// Name of this workspace
@property (copy, nonatomic) NSString *name;

// A unique internal id
@property (copy, nonatomic) NSString *uniqueId;

// Name of the server (QLab machine) this workspace is on
@property (strong, nonatomic) NSString *serverName;

// The root cue is the parent of all the cues in this workspace
@property (strong, nonatomic) QLKCue *root;

// Whether or not this workspace is protected by a passcode
@property (assign, nonatomic) BOOL hasPasscode;

// Cached passcode for this workspace after entered by user
@property (strong, nonatomic) NSString *passcode;

// Whether we currently have a conection
@property (assign, nonatomic) BOOL connected;

- (id)initWithDictionary:(NSDictionary *)dict server:(QLKServer *)server;

- (void)connect;
- (void)connectWithPasscode:(NSString *)passcode completion:(QLKMessageHandlerBlock)block;
- (void)finishConnection;
- (void)disconnect;
- (void)temporarilyDisconnect;
- (void)reconnect;

- (NSString *)fullName;
- (NSString *)fullNameWithCueList:(QLKCue *)cueList;

- (QLKCue *)firstCue;
- (QLKCue *)firstCueList;
- (QLKCue *)cueWithId:(NSString *)uid;

// QLab Server API
- (void)startReceivingUpdates;
- (void)stopReceivingUpdates;
- (void)enableAlwaysReply;
- (void)disableAlwaysReply;
- (void)go;
- (void)stopAll;
- (void)save;
- (void)fetchCueLists;
- (void)fetchCueListsWithCompletion:(QLKMessageHandlerBlock)block;
- (void)fetchPlaybackPositionForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block;
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
- (void)cue:(QLKCue *)cue updateContinueMode:(QLKCueContinueMode)continueMode;
- (void)cue:(QLKCue *)cue updateChannel:(NSInteger)channel level:(double)level;
- (void)cue:(QLKCue *)cue updatePatch:(NSInteger)patch;
- (void)cue:(QLKCue *)cue updateColor:(NSString *)color;
- (void)cue:(QLKCue *)cue updateSurfaceID:(NSInteger)surfaceID;
- (void)cue:(QLKCue *)cue updateFullScreen:(BOOL)fullScreen;
- (void)cue:(QLKCue *)cue updateTranslationX:(CGFloat)originX;
- (void)cue:(QLKCue *)cue updateTranslationY:(CGFloat)originY;
- (void)cue:(QLKCue *)cue updateTargetID:(int) uid;
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
- (void)fetchChildrenForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block;
- (void)fetchNotesForCue:(QLKCue *)cue;
- (void)fetchAudioLevelsForCue:(QLKCue *)cue completion:(QLKMessageHandlerBlock)block;
- (void)fetchDisplayAndGeometryForCue:(QLKCue *)cue;
- (void)runningOrPausedCuesWithBlock:(QLKMessageHandlerBlock)block;

// Lower level API
- (void)sendMessage:(id)object toAddress:(NSString *)address;
- (void)sendMessage:(id)object toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block;

// Helper for sending messages to this workspace: /workspace/<workspace_id>
- (NSString *)workspacePrefix;

// Helper for sending message to a specific cue: /cue_id/<cue.uid>/action
- (NSString *)addressForCue:(QLKCue *)cue action:(NSString *)action;

@end
