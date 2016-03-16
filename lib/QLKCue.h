//
//  QLKCue.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2014 Figure 53 LLC, http://figure53.com
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
#import <GLKit/GLKMathTypes.h>
#import <GLKit/GLKQuaternion.h>
#import "QLKDefines.h"
#import "QLKWorkspace.h"

NS_ASSUME_NONNULL_BEGIN

@class QLKColor, QLKWorkspace;

@interface QLKCue : NSObject

@property (strong, nonatomic, readonly, nullable) QLKImage *icon;
@property (strong, nonatomic, readonly) NSArray<QLKCue *> *cues;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *number;
@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *listName;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *notes;
@property (assign, nonatomic) BOOL flagged;


- (instancetype) initWithDictionary:(NSDictionary *)dict workspace:(QLKWorkspace *)workspace;
- (instancetype) initWithWorkspace:(QLKWorkspace *)workspace;
- (BOOL) isEqualToCue:(QLKCue *)cue;
@property (nonatomic, readonly, copy) NSString *iconFile;
@property (nonatomic, readonly, copy) NSString *nonEmptyName;
@property (nonatomic, getter=isAudio, readonly) BOOL audio;
@property (nonatomic, getter=isVideo, readonly) BOOL video;
@property (nonatomic, getter=isGroup, readonly) BOOL group;
- (void) updatePropertiesWithDictionary:(NSDictionary *)dict;
@property (nonatomic, readonly) BOOL hasChildren;
@property (nonatomic, readonly, strong, nullable) QLKCue *firstCue;
@property (nonatomic, readonly, strong, nullable) QLKCue *lastCue;
- (QLKCue *) cueAtIndex:(NSInteger)index;
- (QLKCue *) cueWithId:(NSString *)cueId;
- (QLKCue *) cueWithNumber:(NSString *)number;
@property (nonatomic, readonly, copy) NSString *surfaceName;
@property (nonatomic, readonly, copy) NSString *patchName;
+ (NSString *) iconForType:(NSString *)type;
@property (nonatomic, readonly, copy) NSString *workspaceName;

- (void) pushUpProperty:(id)value forKey:(NSString *)propertyKey;
- (void) pullDownPropertyForKey:(NSString *)propertyKey block:(void (^) (id))block;
- (void) triggerPushDownPropertyForKey:(NSString *)propertyKey;

- (void) setProperty:(id)value forKey:(NSString *)propertyKey;
- (void) setProperty:(id)value forKey:(NSString *)propertyKey tellQLab:(BOOL)osc;
- (void) sendAllPropertiesToQLab;
- (id) propertyForKey:(NSString *)key;
@property (nonatomic, readonly, copy) NSArray *propertyKeys;
@property (nonatomic, readonly) GLKQuaternion quaternion;
@property (nonatomic, readonly) CGSize surfaceSize;
@property (nonatomic, readonly) CGSize cueSize;
@property (nonatomic, readonly) QLKColor *color;
@property (nonatomic, readonly) NSString *displayName;

- (void) start;
- (void) stop;
- (void) pause;
- (void) reset;
- (void) load;
- (void) resume;
- (void) hardStop;
- (void) togglePause;
- (void) preview;
- (void) panic;

//   Deprecated Cue Properties (guide to the dictionary)
//      Necessities
//QLKOSCUIDKey: @property (strong, nonatomic) NSString *uid;
//QLKOSCNameKey: @property (strong, nonatomic) NSString *name;
//QLKOSCListNameKey: @property (strong, nonatomic) NSString *listName;
//QLKOSCNumberKey: @property (strong, nonatomic) NSString *number;
//QLKOSCFlaggedKey: @property (assign, nonatomic) BOOL flagged;
//@"type": @property (strong, nonatomic) NSString *type;
//QLKOSCNotesKey: @property (strong, nonatomic) NSString *notes;

//      Optionals


//QLKOSCArmedKey: @property (assign, nonatomic) BOOL armed;
//QLKOSCPreWaitKey: @property (assign, nonatomic) double preWait;
//QLKOSCPostWaitKey: @property (assign, nonatomic) double postWait;
//QLKOSCDurationKey: @property (assign, nonatomic) double duration;
//QLKOSCContinueModeKey: @property (assign, nonatomic) QLKCueContinueMode continueMode;
//QLKOSCPatchKey: @property (assign, nonatomic) NSInteger patch;
//@"patchList": @property (strong, nonatomic) NSArray *patches;
//QLKOSCFullScreenKey: @property (assign, nonatomic) BOOL fullScreen;
//QLKOSCTranslationXKey: @property (assign, nonatomic) CGFloat translationX;
//QLKOSCTranslationYKey: @property (assign, nonatomic) CGFloat translationY;
//QLKOSCScaleXKey: @property (assign, nonatomic) CGFloat scaleX;
//QLKOSCScaleYKey: @property (assign, nonatomic) CGFloat scaleY;
//QLKOSCPreserveAspectRatioKey: @property (assign, nonatomic) BOOL preserveAspectRatio;
//@"quaternion": @property (assign, nonatomic) GLKQuaternion quaternion;
//@"surfaceSize": @property (assign, nonatomic) CGSize surfaceSize;
//@"cueSize": @property (assign, nonatomic) CGSize cueSize;
//QLKOSCLayerKey: @property (assign, nonatomic) NSInteger videoLayer;
//QLKOSCOpacityKey: @property (assign, nonatomic) NSInteger videoOpacity;
//QLKOSCSurfaceIDKey: @property (assign, nonatomic) NSInteger surfaceID;
//@"surfaceList": @property (strong, nonatomic) NSArray *surfaces;

@end

NS_ASSUME_NONNULL_END
