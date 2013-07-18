//
//  QLKCue.m
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


#import "QLKCue.h"
#import "QLKColor.h"

NSString * const QLKCueUpdatedNotification = @"QLKCueUpdatedNotification";
NSString * const QLKCueNeedsUpdateNotification = @"QLKCueNeedsUpdateNotification";
NSString * const QLKCueEditCueNotification = @"QLKCueEditCueNotification";

// Cue Types
NSString * const QLKCueTypeCue = @"Cue";
NSString * const QLKCueTypeGroup = @"Group";
NSString * const QLKCueTypeAudio = @"Audio";
NSString * const QLKCueTypeFade = @"Fade";
NSString * const QLKCueTypeMicrophone = @"Mic";
NSString * const QLKCueTypeVideo = @"Video";
NSString * const QLKCueTypeAnimation = @"Animation";
NSString * const QLKCueTypeCamera = @"Camera";
NSString * const QLKCueTypeMIDI = @"MIDI";
NSString * const QLKCueTypeMIDISysEx = @"MIDI SysEx";
NSString * const QLKCueTypeMTC = @"MTC";
NSString * const QLKCueTypeMSC = @"MSC";
NSString * const QLKCueTypeArtNet = @"ArtNet";
NSString * const QLKCueTypeStop = @"Stop";
NSString * const QLKCueTypeMIDIFile = @"MIDI File";
NSString * const QLKCueTypeTimecode = @"Timecode";
NSString * const QLKCueTypePause = @"Pause";
NSString * const QLKCueTypeReset = @"Reset";
NSString * const QLKCueTypeStart = @"Start";
NSString * const QLKCueTypeDevamp = @"Devamp";
NSString * const QLKCueTypeLoad = @"Load";
NSString * const QLKCueTypeScript = @"Script";
NSString * const QLKCueTypeGoto = @"Goto";
NSString * const QLKCueTypeTarget = @"Target";
NSString * const QLKCueTypeWait = @"Wait";
NSString * const QLKCueTypeMemo = @"Memo";
NSString * const QLKCueTypeArm = @"Arm";
NSString * const QLKCueTypeDisarm = @"Disarm";
NSString * const QLKCueTypeStagetracker = @"Stagetracker";

// OSC key constants
NSString * const QLKOSCNameKey = @"name";
NSString * const QLKOSCNumberKey = @"number";
NSString * const QLKOSCNotesKey = @"notes";
NSString * const QLKOSCColorNameKey = @"colorName";
NSString * const QLKOSCFlaggedKey = @"flagged";
NSString * const QLKOSCArmedKey = @"armed";

// Identifiers for "fake" cues
NSString * const QLKActiveCueListIdentifier = @"__active__";
NSString * const QLKRootCueIdentifier = @"__root__";

@interface QLKCue ()

- (void)updateDisplayName;
- (NSArray *)flattenCuesWithDepth:(NSInteger)depth;

@end

@implementation QLKCue

- (id)init 
{
  self = [super init];
  if (!self) return nil;
    
  _uid = nil;
  _number = @"";
  _notes = @"";
  _name = @"(Untitled Cue)";
  _listName = @"";
  _flagged = NO;
  _color = [QLKColor defaultColor];
  _type = QLKCueTypeCue;
  _cues = [NSMutableArray array];
  _depth = 0;
  _expanded = NO;
  _patches = @[];

  return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
  self = [self init];
  if (!self) return nil;

  _name = [dict[@"name"] copy];
  _listName = [dict[@"listName"] copy];
  _type = [dict[@"type"] copy];
  _notes = [dict[@"notes"] copy];
  _uid = [dict[@"uniqueID"] copy];
  _number = [dict[@"number"] copy];
  _flagged = [dict[@"flagged"] boolValue];
  
  NSString *color = dict[@"colorName"];
  if (![color isEqualToString:@"none"]) {
    _color = [QLKColor colorWithName:color];
  }
  
  if ([_type isEqualToString:QLKCueTypeGroup]) {
    for (NSDictionary *cueDict in dict[@"cues"]) {
      [_cues addObject:[QLKCue cueWithDictionary:cueDict]];
    }
  }
  
  _icon = [QLKImage imageNamed:[self iconFile]];
  [self updateDisplayName];

  return self;
}

+ (QLKCue *)cueWithDictionary:(NSDictionary *)dict
{
  return [[QLKCue alloc] initWithDictionary:dict];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"(Cue: %p) name: %@ [id:%@ number:%@ type:%@]", self,  self.name, self.uid, self.number, self.type];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if (!object || ![object isKindOfClass:[self class]]) {
    return NO;
  } else {
    return [self isEqualToCue:object];
  }
}

- (NSUInteger)hash
{
  return [self.uid hash];
}

- (BOOL)isEqualToCue:(QLKCue *)cue
{
  return [self.uid isEqualToString:cue.uid];
}

// Basic properties
- (void)updatePropertiesWithDictionary:(NSDictionary *)dict
{
#if DEBUG
  //NSLog(@"updateProperties: %@", dict);
#endif
  
  // We don't know what properties are present, so we need to check for the existence of every property because we don't want to overwrite an existing value with nil
  // Probably a better way to do this
  
  // Default properties
  
  if (dict[QLKOSCNameKey]) {
    self.name = dict[QLKOSCNameKey];
    [self updateDisplayName];
  }
  
  if (dict[QLKOSCNumberKey]) {
    self.number = dict[QLKOSCNumberKey];
    [self updateDisplayName];
  }
  
  if (dict[QLKOSCNotesKey]) {
    self.notes = dict[QLKOSCNotesKey];
  }
  
  if (dict[QLKOSCColorNameKey]) {
    self.color = [QLKColor colorWithName:dict[QLKOSCColorNameKey]];
  }
  
  if (dict[QLKOSCFlaggedKey]) {
    self.flagged = [dict[QLKOSCFlaggedKey] boolValue];
  }
  
  if (dict[QLKOSCArmedKey]) {
    self.armed = [dict[QLKOSCArmedKey] boolValue];
  }
  
  if (dict[@"preWait"]) {
    self.preWait = [dict[@"preWait"] doubleValue];
  }
  
  if (dict[@"postWait"]) {
    self.postWait = [dict[@"postWait"] doubleValue];
  }
  
  if (dict[@"duration"]) {
    self.duration = [dict[@"duration"] doubleValue];
  }
  
  if (dict[@"continueMode"]) {
    self.continueMode = [dict[@"continueMode"] integerValue];
  }
  
  // Audio cue
  
  if (dict[@"patch"]) {
    self.patch = [dict[@"patch"] integerValue];
  }
  
  if (dict[@"patchList"]) {
    self.patches = dict[@"patchList"];
  }

  // Video cue
  
  if (dict[@"fullScreen"]) {
    self.fullScreen = [dict[@"fullScreen"] boolValue];
  }
  
  if (dict[@"surfaceID"]) {
    self.surfaceID = [dict[@"surfaceID"] integerValue];
  }
  
  if (dict[@"surfaceList"]) {
    self.surfaces = dict[@"surfaceList"];
  }
  
  if (dict[@"translationX"]) {
    self.translationX = [dict[@"translationX"] floatValue];
  }
  
  if (dict[@"translationY"]) {
    self.translationY = [dict[@"translationY"] floatValue];
  }
  
  if (dict[@"scaleX"]) {
    self.scaleX = [dict[@"scaleX"] floatValue];
  }
  
  if (dict[@"scaleY"]) {
    self.scaleY = [dict[@"scaleY"] floatValue];
  }
  
  if (dict[@"preserveAspectRatio"]) {
    self.preserveAspectRatio = [dict[@"preserveAspectRatio"] boolValue];
  }
  
  if (dict[@"layer"]) {
    self.videoLayer = [dict[@"layer"] integerValue];
  }
  
  if (dict[@"opacity"]) {
   self.videoOpacity = round([dict[@"opacity"] floatValue] * 100.0);
  }
  
  if (dict[@"quaternion"]) {
    NSArray *quaternionComponents = dict[@"quaternion"];
    self.quaternion = GLKQuaternionMake([quaternionComponents[0] floatValue], [quaternionComponents[1] floatValue], [quaternionComponents[2] floatValue], [quaternionComponents[3] floatValue]);
  }
  
  if (dict[@"surfaceSize"]) {
    self.surfaceSize = CGSizeMake([dict[@"surfaceSize"][@"width"] floatValue], [dict[@"surfaceSize"][@"height"] floatValue]);
  }
 
  if (dict[@"cueSize"]) {
    self.cueSize = CGSizeMake([dict[@"cueSize"][@"width"] floatValue], [dict[@"cueSize"][@"height"] floatValue]);
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueUpdatedNotification object:self];
}

- (void)updateDisplayName
{
  NSString *name;
  NSString *number = (![self.number isEqualToString:@""]) ? [NSString stringWithFormat:@"%@: ", self.number] : @"";
  
  if (self.name && ![self.name isEqualToString:@""]) {
    name = self.name;
  } else if (self.listName && ![self.listName isEqualToString:@""]) {
    name = self.listName;
  } else {
    name = [NSString stringWithFormat:@"(Untitled %@ Cue)", self.type];
  }
  
  self.displayName = [NSString stringWithFormat:@"%@%@",number, name];
}

- (NSString *)iconFile
{
  return [NSString stringWithFormat:@"%@.png", [QLKCue iconForType:self.type]];
}

// Map cue type to icon
+ (NSString *)iconForType:(NSString *)type
{
  if ([type isEqualToString:QLKCueTypeMIDIFile]) {
    return @"midi-file";
  } else if ([type isEqualToString:QLKCueTypeMicrophone]) {
    return @"microphone";
  } else {
    return [type lowercaseString];
  }
}

- (BOOL)isAudio
{
	return ([self.type isEqualToString:QLKCueTypeAudio] || [self.type isEqualToString:QLKCueTypeMicrophone] || [self.type isEqualToString:QLKCueTypeFade] || [self isVideo]);
}

- (BOOL)isVideo
{
	return ([self.type isEqualToString:QLKCueTypeVideo] || [self.type isEqualToString:QLKCueTypeCamera]);
}

- (BOOL)isGroup
{
	return [self.type isEqualToString:QLKCueTypeGroup];
}

- (BOOL)hasChildren
{
  return [self isGroup] && self.cues.count > 0;
}

#pragma mark - Children cues

- (QLKCue *)firstCue
{
  return [self hasChildren] ? self.cues[0] : nil;
}

- (QLKCue *)lastCue
{
  return [self hasChildren] ? [self.cues lastObject] : nil;
}

- (QLKCue *)cueAtIndex:(NSInteger)index
{
  return ([self hasChildren] && self.cues.count > index) ? self.cues[index] : nil;
}

// Recursively search for a cue with a matching id
- (QLKCue *)cueWithId:(NSString *)cueId
{
  for (QLKCue *cue in self.cues) {
    if ([cue.uid isEqualToString:cueId]) {
      return cue;
    }
    
    if ([cue isGroup]) {
      QLKCue *childCue = [cue cueWithId:cueId];
      if (childCue) {
        return childCue;
      }
    }
  }
  
  return nil;
}

- (NSArray *)flattenedCues
{
  return [self flattenCuesWithDepth:0];
}

- (NSArray *)flattenCuesWithDepth:(NSInteger)depth
{
  NSMutableArray *cues = [NSMutableArray array];

  for (QLKCue *cue in self.cues) {
    cue.depth = depth;
    [cues addObject:cue];
    
    if ([cue isGroup] && cue.expanded) {
      [cues addObjectsFromArray:[cue flattenCuesWithDepth:depth + 1]];
    }
  }
  
  return cues;
}

#pragma mark - Accessors

- (NSString *)surfaceName
{
  NSArray *surfaces = (self.surfaces) ? [self.surfaces filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"surfaceID == %@", @(self.surfaceID)]] : @[];
  
  return (surfaces.count > 0) ? surfaces[0][@"surfaceName"] : nil;
}

- (NSString *)patchName
{
  NSArray *patches = (self.patches) ? [self.patches filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patchNumber == %@", @(self.patch)]] : @[];
  
  return (patches.count > 0) ? patches[0][@"patchName"] : nil;
}

@end
