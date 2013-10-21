//
//  QLKCue.h
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
#import <GLKit/GLKit.h>
#import "QLKDefines.h"

// Notifications
extern NSString * const QLKCueUpdatedNotification;
extern NSString * const QLKCueNeedsUpdateNotification;
extern NSString * const QLKCueEditCueNotification;

// Cue types
extern NSString * const QLKCueTypeCue;
extern NSString * const QLKCueTypeGroup;
extern NSString * const QLKCueTypeAudio;
extern NSString * const QLKCueTypeFade;
extern NSString * const QLKCueTypeMicrophone;
extern NSString * const QLKCueTypeVideo;
extern NSString * const QLKCueTypeAnimation;
extern NSString * const QLKCueTypeCamera;
extern NSString * const QLKCueTypeMIDI;
extern NSString * const QLKCueTypeMIDISysEx;
extern NSString * const QLKCueTypeTimecode;
extern NSString * const QLKCueTypeMTC;
extern NSString * const QLKCueTypeMSC;
extern NSString * const QLKCueTypeStop;
extern NSString * const QLKCueTypeMIDIFile;
extern NSString * const QLKCueTypePause;
extern NSString * const QLKCueTypeReset;
extern NSString * const QLKCueTypeStart;
extern NSString * const QLKCueTypeDevamp;
extern NSString * const QLKCueTypeLoad;
extern NSString * const QLKCueTypeScript;
extern NSString * const QLKCueTypeGoto;
extern NSString * const QLKCueTypeTarget;
extern NSString * const QLKCueTypeWait;
extern NSString * const QLKCueTypeMemo;
extern NSString * const QLKCueTypeArm;
extern NSString * const QLKCueTypeDisarm;
extern NSString * const QLKCueTypeStagetracker;

// Special cue identifiers
extern NSString * const QLKActiveCueListIdentifier;
extern NSString * const QLKRootCueIdentifier;

// Continue mode type
typedef enum {
  QLKCueContinueModeNoContinue,
  QLKCueContinueModeAutoContinue,
  QLKCueContinueModeAutoFollow
} QLKCueContinueMode;

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
@property (assign, nonatomic) QLKCueContinueMode continueMode;
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
- (NSString *)iconFile;
- (NSString *)nonEmptyName;
- (BOOL)isAudio;
- (BOOL)isVideo;
- (BOOL)isGroup;
- (void)updatePropertiesWithDictionary:(NSDictionary *)dict;
- (BOOL)hasChildren;
- (QLKCue *)firstCue;
- (QLKCue *)lastCue;
- (QLKCue *)cueAtIndex:(NSInteger)index;
- (QLKCue *)cueWithId:(NSString *)cueId;
- (NSArray *)flattenedCues;
- (NSString *)surfaceName;
- (NSString *)patchName;
+ (NSString *)iconForType:(NSString *)type;

@end
