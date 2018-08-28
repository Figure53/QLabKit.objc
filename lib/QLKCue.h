//
//  QLKCue.h
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
@import GLKit.GLKitBase;
@import GLKit.GLKMathTypes;
@import GLKit.GLKQuaternion;
#import "QLKDefines.h"
#import "QLKWorkspace.h"

@class QLKColor;
@class QLKWorkspace;

typedef NS_ENUM( NSUInteger, QLKCueFadeMode ) {
    QLKCueFadeModeAbsolute = 0,
    QLKCueFadeModeRelative
};


NS_ASSUME_NONNULL_BEGIN

@interface QLKCue : NSObject

@property (nonatomic, weak, readonly, nullable)     QLKWorkspace *workspace;
@property (atomic)                                  NSUInteger sortIndex;

@property (strong, atomic, readonly, nullable)      QLKImage *icon;
@property (strong, nonatomic, readonly)             NSArray<QLKCue *> *cues;
@property (strong, nonatomic, readonly, nullable)   NSString *parentID;
@property (strong, nonatomic, readonly, nullable)   NSString *playbackPositionID; // for cue list cues, the unique ID of the current playback position
@property (strong, nonatomic, nullable)             NSString *name;
@property (strong, nonatomic, nullable)             NSString *number;
@property (strong, nonatomic, nullable)             NSString *uid;
@property (strong, nonatomic, nullable)             NSString *listName;
@property (strong, nonatomic, nullable)             NSString *type;
@property (strong, nonatomic, nullable)             NSString *notes;
@property (nonatomic, getter=isFlagged)             BOOL flagged;
@property (nonatomic, getter=isOverridden, readonly) BOOL overridden;
@property (nonatomic, getter=isBroken, readonly)    BOOL broken;
@property (nonatomic, getter=isRunning, readonly)   BOOL running;
@property (nonatomic, getter=isTailingOut, readonly) BOOL tailingOut;
@property (nonatomic, getter=isPanicking, readonly) BOOL panicking;

@property (nonatomic, readonly)                     NSString *displayName;
@property (nonatomic, readonly, copy)               NSString *nonEmptyName;
@property (nonatomic, readonly, copy, nullable)     NSString *workspaceName;
@property (nonatomic, readonly)                     NSTimeInterval currentDuration;
@property (nonatomic, readonly, copy, nullable)     NSString *audioFadeModeName;
@property (nonatomic, readonly, copy, nullable)     NSString *geoFadeModeName;
@property (nonatomic, readonly, copy, nullable)     NSString *surfaceName;
@property (nonatomic, readonly, copy, nullable)     NSString *patchName;
@property (nonatomic, readonly, nullable)           QLKColor *color;
@property (nonatomic, readonly)                     GLKQuaternion quaternion;
@property (nonatomic, readonly)                     CGSize surfaceSize;
@property (nonatomic, readonly)                     CGSize cueSize;
@property (nonatomic, readonly, copy)               NSArray<NSString *> *availableSurfaceNames;
@property (nonatomic, readonly, copy)               NSArray<NSString *> *propertyKeys;

@property (atomic, getter=isAudio, readonly)        BOOL audio;
@property (atomic, getter=isVideo, readonly)        BOOL video;
@property (atomic, getter=isGroup, readonly)        BOOL group;
@property (atomic, getter=isCueList, readonly)      BOOL cueList;
@property (atomic, getter=isCueCart, readonly)      BOOL cueCart;
@property (nonatomic, readonly)                     BOOL hasChildren;
@property (nonatomic, readonly, weak, nullable)     QLKCue *firstCue;
@property (nonatomic, readonly, weak, nullable)     QLKCue *lastCue;

@property (nonatomic)                               BOOL ignoreUpdates;

+ (NSString *) iconForType:(NSString *)type;
+ (BOOL) cueTypeIsAudio:(NSString *)type;
+ (BOOL) cueTypeIsVideo:(NSString *)type;
+ (BOOL) cueTypeIsGroup:(NSString *)type;
+ (BOOL) cueTypeIsCueList:(NSString *)type;
+ (BOOL) cueTypeIsCueCart:(NSString *)type;

+ (NSArray<NSString *> *) fadeModeTitles;

- (instancetype) initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict workspace:(QLKWorkspace *)workspace;
- (instancetype) initWithWorkspace:(QLKWorkspace *)workspace;
- (BOOL) isEqualToCue:(QLKCue *)cue;
- (void) addChildCue:(QLKCue *)cue; // cue is added to internal index using current value of QLKOSCUIDKey property.
- (void) addChildCue:(QLKCue *)cue withID:(NSString *)uid; // Same as addChildCue: but more efficient if the uid is already known.
- (void) removeChildCue:(QLKCue *)cue;
- (void) removeAllChildCues;
- (void) removeChildCuesWithIDs:(NSArray<NSString *> *)uids;

- (BOOL) updatePropertiesWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict; // if cue was actually updated, posts `QLKCueUpdatedNotification` and returns YES
- (BOOL) updatePropertiesWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict notify:(BOOL)notify; // optionally posts `QLKCueUpdatedNotification`
- (void) updateChildCuesWithPropertiesArray:(NSArray<NSDictionary *> *)data removeUnused:(BOOL)removeUnused;

- (NSArray<NSString *> *) allChildCueUids;
- (nullable QLKCue *) cueAtIndex:(NSInteger)index;
- (nullable QLKCue *) cueWithID:(NSString *)uid; // deep searches Group cue child cues
- (nullable QLKCue *) cueWithID:(NSString *)uid includeChildren:(BOOL)includeChildren; // optionally deep search Group cue child cues
- (nullable QLKCue *) cueWithNumber:(NSString *)number;

//  convenience method for posting QLKCueUpdatedNotification
- (void) enqueueCueUpdatedNotification;

// convenience setter
- (void) setQuaternion:(GLKQuaternion)quaternion tellQLab:(BOOL)osc;

- (nullable id) propertyForKey:(NSString *)key;
- (BOOL) setProperty:(nullable id)value forKey:(NSString *)key; // returns YES if property actually changed
- (BOOL) setProperty:(nullable id)value forKey:(NSString *)key tellQLab:(BOOL)osc; // returns YES if property actually changed
- (BOOL) setPlaybackPositionID:(nullable NSString *)cueID tellQLab:(BOOL)osc;
- (void) sendAllPropertiesToQLab;

- (void) pullDownPropertyForKey:(NSString *)key block:(nullable QLKMessageHandlerBlock)block;

- (void) start;
- (void) stop;
- (void) pause;
- (void) reset;
- (void) load;
- (void) resume;
- (void) hardStop;
- (void) hardPause;
- (void) togglePause;
- (void) preview;
- (void) panic;

@end

NS_ASSUME_NONNULL_END
