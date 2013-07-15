//
//  QLRCue.h
//  QLab for iPad
//
//  Created by Zach Waugh on 5/11/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "QLKDefines.h"

extern NSString * const QLRCueUpdatedNotification;
extern NSString * const QLRCueNeedsUpdateNotification;
extern NSString * const QLRCueEditCueNotification;

// Cue types
extern NSString * const QLRCueTypeCue;
extern NSString * const QLRCueTypeGroup;
extern NSString * const QLRCueTypeAudio;
extern NSString * const QLRCueTypeFade;
extern NSString * const QLRCueTypeMicrophone;
extern NSString * const QLRCueTypeVideo;
extern NSString * const QLRCueTypeAnimation;
extern NSString * const QLRCueTypeCamera;
extern NSString * const QLRCueTypeMIDI;
extern NSString * const QLRCueTypeMIDISysEx;
extern NSString * const QLRCueTypeTimecode;
extern NSString * const QLRCueTypeMTC;
extern NSString * const QLRCueTypeMSC;
extern NSString * const QLRCueTypeStop;
extern NSString * const QLRCueTypeMIDIFile;
extern NSString * const QLRCueTypePause;
extern NSString * const QLRCueTypeReset;
extern NSString * const QLRCueTypeStart;
extern NSString * const QLRCueTypeDevamp;
extern NSString * const QLRCueTypeLoad;
extern NSString * const QLRCueTypeScript;
extern NSString * const QLRCueTypeGoto;
extern NSString * const QLRCueTypeTarget;
extern NSString * const QLRCueTypeWait;
extern NSString * const QLRCueTypeMemo;
extern NSString * const QLRCueTypeArm;
extern NSString * const QLRCueTypeDisarm;
extern NSString * const QLRCueTypeStagetracker;

extern NSString * const QLRActiveCueListIdentifier;
extern NSString * const QLRRootCueIdentifier;

// Continue mode type
typedef enum {
  QLRCueContinueModeNoContinue,
  QLRCueContinueModeAutoContinue,
  QLRCueContinueModeAutoFollow
} QLRCueContinueMode;

@class QLKColor;

@interface QLKCue : NSObject

@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *number;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *listName;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *notes;
@property (strong, nonatomic) QLKImage *icon;
@property (strong, nonatomic) QLKColor *color;
@property (strong, nonatomic) NSMutableArray *cues;
@property (assign, nonatomic) BOOL flagged;
@property (assign, nonatomic) BOOL armed;
@property (assign, nonatomic) double preWait;
@property (assign, nonatomic) double postWait;
@property (assign, nonatomic) double duration;
@property (assign, nonatomic) QLRCueContinueMode continueMode;
@property (assign, nonatomic) NSInteger patch;
@property (strong, nonatomic) NSArray *patches;
@property (assign, nonatomic) BOOL fullScreen;
@property (assign, nonatomic) CGFloat translationX;
@property (assign, nonatomic) CGFloat translationY;
@property (assign, nonatomic) CGFloat scaleX;
@property (assign, nonatomic) CGFloat scaleY;
@property (assign, nonatomic) BOOL preserveAspectRatio;
@property (assign, nonatomic) GLKQuaternion quaternion;
@property (assign, nonatomic) CGSize surfaceSize;
@property (assign, nonatomic) CGSize cueSize;
@property (assign, nonatomic) NSInteger videoLayer;
@property (assign, nonatomic) NSInteger videoOpacity;
@property (assign, nonatomic) NSInteger depth;
@property (assign, nonatomic) NSInteger surfaceID;
@property (strong, nonatomic) NSArray *surfaces;
@property (assign, nonatomic) BOOL expanded;

+ (QLKCue *)cueWithDictionary:(NSDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;
- (BOOL)isEqualToCue:(QLKCue *)cue;
- (NSString *)displayName;
- (NSString *)iconFile;
+ (NSString *)iconForType:(NSString *)type;
- (BOOL)hasChildren;
- (BOOL)isAudio;
- (BOOL)isVideo;
- (BOOL)isGroup;
- (void)updatePropertiesWithDictionary:(NSDictionary *)dict;
- (QLKCue *)firstCue;
- (QLKCue *)lastCue;
- (QLKCue *)cueAtIndex:(NSInteger)index;
- (QLKCue *)cueWithId:(NSString *)cueId;
- (NSArray *)flattenedCues;
- (NSString *)surfaceName;
- (NSString *)patchName;

@end
