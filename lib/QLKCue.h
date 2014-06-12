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
#import "QLKWorkspace.h"


@class QLKColor, QLKWorkspace;

@interface QLKCue : NSObject




@property (strong, nonatomic) NSMutableDictionary *cueData;

@property (strong, nonatomic) QLKImage *icon;

+ (QLKCue *) cueWithDictionary:(NSDictionary *)dict;
- (id) initWithDictionary:(NSDictionary *)dict workspace:(QLKWorkspace *)workspace;
- (BOOL) isEqualToCue:(QLKCue *)cue;
- (NSString *) iconFile;
- (NSString *) nonEmptyName;
- (BOOL) isAudio;
- (BOOL) isVideo;
- (BOOL) isGroup;
- (void) updatePropertiesWithDictionary:(NSDictionary *)dict;
- (BOOL) hasChildren;
- (QLKCue *) firstCue;
- (QLKCue *) lastCue;
- (QLKCue *) cueAtIndex:(NSInteger)index;
- (QLKCue *) cueWithId:(NSString *)cueId;
- (NSArray *) flattenedCues;
- (NSString *) surfaceName;
- (NSString *) patchName;
+ (NSString *) iconForType:(NSString *)type;

- (void)setProperty:(id)value forKey:(NSString *)propertyKey doUpdateOSC:(BOOL)osc;
- (id)propertyForKey:(NSString *)key;
- (GLKQuaternion)quaternion;
- (CGSize)surfaceSize;
- (CGSize)cueSize;
- (QLKColor *)color;
- (NSString *)displayName;

//   Deprecated Cue Properties (guide to the dictionary)
//      Necessities
//@"uniqueID": @property (strong, nonatomic) NSString *uid;
//QLKOSCNameKey: @property (strong, nonatomic) NSString *name;
//@"listName": @property (strong, nonatomic) NSString *listName;
//QLKOSCNumberKey: @property (strong, nonatomic) NSString *number;
//QLKOSCFlaggedKey: @property (assign, nonatomic) BOOL flagged;
//@"type": @property (strong, nonatomic) NSString *type;
//QLKOSCNotesKey: @property (strong, nonatomic) NSString *notes;

//      Optionals


//QLKOSCArmedKey: @property (assign, nonatomic) BOOL armed;
//@"preWait": @property (assign, nonatomic) double preWait;
//@"postWait": @property (assign, nonatomic) double postWait;
//@"duration": @property (assign, nonatomic) double duration;
//@"continueMode": @property (assign, nonatomic) QLKCueContinueMode continueMode;
//@"patch": @property (assign, nonatomic) NSInteger patch;
//@"patchList": @property (strong, nonatomic) NSArray *patches;
//@"fullScreen": @property (assign, nonatomic) BOOL fullScreen;
//@"translationX": @property (assign, nonatomic) CGFloat translationX;
//@"translationY": @property (assign, nonatomic) CGFloat translationY;
//@"scaleX": @property (assign, nonatomic) CGFloat scaleX;
//@"scaleY": @property (assign, nonatomic) CGFloat scaleY;
//@"preserveAspectRatio": @property (assign, nonatomic) BOOL preserveAspectRatio;
//@"quaternion": @property (assign, nonatomic) GLKQuaternion quaternion;
//@"surfaceSize": @property (assign, nonatomic) CGSize surfaceSize;
//@"cueSize": @property (assign, nonatomic) CGSize cueSize;
//@"layer": @property (assign, nonatomic) NSInteger videoLayer;
//@"opacity": @property (assign, nonatomic) NSInteger videoOpacity;
//@"surfaceID": @property (assign, nonatomic) NSInteger surfaceID;
//@"surfaceList": @property (strong, nonatomic) NSArray *surfaces;

//deprecated accessors
- (NSString *)uid DEPRECATED_ATTRIBUTE;
- (NSString *)name DEPRECATED_ATTRIBUTE;
- (NSString *)listName DEPRECATED_ATTRIBUTE;
- (NSString *)number DEPRECATED_ATTRIBUTE;
- (BOOL)flagged DEPRECATED_ATTRIBUTE;
- (NSString *)type DEPRECATED_ATTRIBUTE;
- (NSString *)notes DEPRECATED_ATTRIBUTE;

//deprecated mutators
- (void)setUid:(NSString *)uid DEPRECATED_ATTRIBUTE;
- (void)setName:(NSString *)name DEPRECATED_ATTRIBUTE;
- (void)setListName:(NSString *)listName DEPRECATED_ATTRIBUTE;
- (void)setNumber:(NSString *)number DEPRECATED_ATTRIBUTE;
- (void)setFlagged:(BOOL)flagged DEPRECATED_ATTRIBUTE;
- (void)setType:(NSString *)type DEPRECATED_ATTRIBUTE;
- (void)setNotes:(NSString *)notes DEPRECATED_ATTRIBUTE;

@end
