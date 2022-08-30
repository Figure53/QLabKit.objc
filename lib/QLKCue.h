//
//  QLKCue.h
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

#import "QLKDefines.h"
#import "QLKQuaternion.h"
#import "QLKWorkspace.h"
#import <Foundation/Foundation.h>

@class QLKColor;
@class QLKWorkspace;

NS_ASSUME_NONNULL_BEGIN

// Compatibility macros for version-specific OSC method keys
#define QLK_OSC_KEY_PLAYBACK_POSITION_ID (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4PlaybackPositionIdKey : QLKOSCPlaybackPositionIDKey)
#define QLK_OSC_KEY_FILL_STAGE           (self.workspace.workspaceQLabVersion.majorVersion == 3 ? QLKOSCFullScreenKey : (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCFullSurfaceKey : QLKOSCFillStageKey))
#define QLK_OSC_KEY_TRANSLATION_X        (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4TranslationXKey : QLKOSCTranslationXKey)
#define QLK_OSC_KEY_TRANSLATION_Y        (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4TranslationYKey : QLKOSCTranslationYKey)
#define QLK_OSC_KEY_SCALE_X              (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4ScaleXKey : QLKOSCScaleXKey)
#define QLK_OSC_KEY_SCALE_Y              (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4ScaleYKey : QLKOSCScaleYKey)
#define QLK_OSC_KEY_ORIGIN_X             (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4OriginXKey : QLKOSCOriginXKey)
#define QLK_OSC_KEY_ORIGIN_Y             (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4OriginYKey : QLKOSCOriginYKey)
#define QLK_OSC_KEY_ROTATE_X             (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4RotateXKey : QLKOSCRotateXKey)
#define QLK_OSC_KEY_ROTATE_Y             (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4RotateYKey : QLKOSCRotateYKey)
#define QLK_OSC_KEY_ROTATE_Z             (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4RotateZKey : QLKOSCRotateZKey)
#define QLK_OSC_KEY_FADE_LEVELS_MODE     (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCV4FadeLevelsModeKey : QLKOSCFadeLevelsModeKey)
#define QLK_OSC_KEY_VIDEO_OUTPUT_ID      (self.workspace.workspaceQLabVersion.majorVersion < 5 ? QLKOSCSurfaceIDKey : QLKOSCStageIDKey) // NOTE: `surfaceID` returns NSNumber, `stageID` returns NSString

typedef NS_ENUM(NSUInteger, QLKCueFadeMode)
{
    QLKCueFadeModeAbsolute = 0,
    QLKCueFadeModeRelative
};

@interface QLKCue : NSObject

@property (nonatomic, weak, readonly, nullable) QLKWorkspace *workspace;
@property (atomic) NSUInteger sortIndex;

@property (atomic, strong, readonly, nullable) NSString *iconName;
@property (nonatomic, readonly) NSArray<QLKCue *> *cues;
@property (nonatomic, readonly, nullable) NSString *parentID;
@property (nonatomic, readonly, nullable) NSString *playbackPositionID; // for cue list cues, the unique ID of the current playback position
@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSString *number;
@property (nonatomic, strong, nullable) NSString *uid;
@property (nonatomic, strong, nullable) NSString *listName;
@property (nonatomic, strong, nullable) NSString *type;
@property (nonatomic, strong, nullable) NSString *notes;
@property (nonatomic, getter=isFlagged) BOOL flagged;
- (BOOL)isPanicking;
- (BOOL)isCrossfadingOut;   // v5.0+
- (BOOL)isAuditioning;      // v5.0+
- (BOOL)isChildAuditioning; // v5.0+
- (BOOL)isRunning;
- (BOOL)isTailingOut;
- (BOOL)isPaused;
- (BOOL)isBroken;
- (BOOL)isOverridden;
- (BOOL)isWarning; // v5.0+
- (BOOL)isLoaded;
- (BOOL)isChildFlagged; // v5.0+

@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly, copy) NSString *nonEmptyName;
@property (nonatomic, readonly, copy, nullable) NSString *workspaceName;
@property (nonatomic, readonly) NSTimeInterval currentDuration;
@property (nonatomic, readonly, copy, nullable) NSString *audioFadeModeName;
@property (nonatomic, readonly, copy, nullable) NSString *geoFadeModeName;
@property (nonatomic, readonly, nullable) QLKColor *color;
@property (nonatomic, readonly, nullable) QLKColor *liveColor; // v5.0+
@property (nonatomic, readonly) QLKQuaternion quaternion;
@property (nonatomic, readonly) CGSize cueSize;
@property (nonatomic, readonly, copy) NSArray<NSString *> *availableSurfaceNames; // v3 & v4 only
@property (nonatomic, readonly, copy) NSArray<NSString *> *availableStageNames;   // v5.0+
@property (nonatomic, readonly, copy, nullable) NSString *surfaceName;            // v3 & v4
@property (nonatomic, readonly, copy, nullable) NSString *stageName;              // v5.0+
@property (nonatomic, readonly) CGSize surfaceSize;                               // v3 & v4
@property (nonatomic, readonly) CGSize stageSize;                                 // v5.0+
@property (nonatomic, readonly, copy) NSArray<NSString *> *propertyKeys;

@property (atomic, getter=isAudio, readonly) BOOL audio;
@property (atomic, getter=isVideo, readonly) BOOL video;
@property (atomic, getter=isGroup, readonly) BOOL group;
@property (atomic, getter=isCueList, readonly) BOOL cueList;
@property (atomic, getter=isCueCart, readonly) BOOL cueCart;
@property (nonatomic, readonly) BOOL hasChildren;
@property (nonatomic, readonly, weak, nullable) QLKCue *firstCue;
@property (nonatomic, readonly, weak, nullable) QLKCue *lastCue;

@property (nonatomic) BOOL ignoreUpdates;

+ (NSString *)iconForType:(NSString *)type;
+ (BOOL)cueTypeIsAudio:(NSString *)type;
+ (BOOL)cueTypeIsVideo:(NSString *)type;
+ (BOOL)cueTypeIsGroup:(NSString *)type;
+ (BOOL)cueTypeIsCueList:(NSString *)type;
+ (BOOL)cueTypeIsCueCart:(NSString *)type;

+ (NSArray<NSString *> *)fadeModeTitles;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict workspace:(QLKWorkspace *)workspace;
- (instancetype)initWithWorkspace:(QLKWorkspace *)workspace;
- (BOOL)isEqualToCue:(QLKCue *)cue;
- (void)addChildCue:(QLKCue *)cue;                        // cue is added to internal index using current value of QLKOSCUIDKey property.
- (void)addChildCue:(QLKCue *)cue withID:(NSString *)uid; // Same as addChildCue: but more efficient if the uid is already known.
- (void)removeChildCue:(QLKCue *)cue;
- (void)removeAllChildCues;
- (void)removeChildCuesWithIDs:(NSArray<NSString *> *)uids;

- (BOOL)updatePropertiesWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict;                     // if cue was actually updated, posts `QLKCueUpdatedNotification` and returns YES
- (BOOL)updatePropertiesWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict notify:(BOOL)notify; // optionally posts `QLKCueUpdatedNotification`
- (void)updateChildCuesWithPropertiesArray:(NSArray<NSDictionary *> *)data removeUnused:(BOOL)removeUnused;

- (NSArray<NSString *> *)allChildCueUids;
- (nullable QLKCue *)cueAtIndex:(NSInteger)index;
- (nullable QLKCue *)cueWithID:(NSString *)uid;                                       // deep searches Group cue child cues
- (nullable QLKCue *)cueWithID:(NSString *)uid includeChildren:(BOOL)includeChildren; // optionally deep search Group cue child cues
- (nullable QLKCue *)cueWithNumber:(NSString *)number;

//  convenience method for posting QLKCueUpdatedNotification
- (void)enqueueCueUpdatedNotification;

// convenience setter
- (void)setQuaternion:(QLKQuaternion)quaternion tellQLab:(BOOL)osc;

- (nullable id)propertyForKey:(NSString *)key;
- (BOOL)setProperty:(nullable id)value forKey:(NSString *)key;                    // returns YES if property actually changed
- (BOOL)setProperty:(nullable id)value forKey:(NSString *)key tellQLab:(BOOL)osc; // returns YES if property actually changed
- (BOOL)setPlaybackPositionID:(nullable NSString *)cueID tellQLab:(BOOL)osc;
- (void)sendAllPropertiesToQLab;

- (void)pullDownPropertyForKey:(NSString *)key block:(nullable QLKMessageReplyBlock)block;

- (void)start;
- (void)stop;
- (void)pause;
- (void)reset;
- (void)load;
- (void)resume;
- (void)hardStop;
- (void)hardPause;
- (void)togglePause;
- (void)preview;
- (void)auditionPreview; // v5.0+
- (void)panic;

@end

NS_ASSUME_NONNULL_END
