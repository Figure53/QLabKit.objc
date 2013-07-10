//
//  QLRCue.m
//  QLab for iPad
//
//  Created by Zach Waugh on 5/11/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "QLKCue.h"
#import "QLKColor.h"

NSString * const QLRCueUpdatedNotification = @"QLRCueUpdatedNotification";
NSString * const QLRCueNeedsUpdateNotification = @"QLRCueNeedsUpdateNotification";
NSString * const QLRCueEditCueNotification = @"QLRCueEditCueNotification";

// Cue Types
NSString * const QLRCueTypeCue = @"Cue";
NSString * const QLRCueTypeGroup = @"Group";
NSString * const QLRCueTypeAudio = @"Audio";
NSString * const QLRCueTypeFade = @"Fade";
NSString * const QLRCueTypeMicrophone = @"Mic";
NSString * const QLRCueTypeVideo = @"Video";
NSString * const QLRCueTypeAnimation = @"Animation";
NSString * const QLRCueTypeCamera = @"Camera";
NSString * const QLRCueTypeMIDI = @"MIDI";
NSString * const QLRCueTypeMIDISysEx = @"MIDI SysEx";
NSString * const QLRCueTypeMTC = @"MTC";
NSString * const QLRCueTypeMSC = @"MSC";
NSString * const QLRCueTypeArtNet = @"ArtNet";
NSString * const QLRCueTypeStop = @"Stop";
NSString * const QLRCueTypeMIDIFile = @"MIDI File";
NSString * const QLRCueTypeTimecode = @"Timecode";
NSString * const QLRCueTypePause = @"Pause";
NSString * const QLRCueTypeReset = @"Reset";
NSString * const QLRCueTypeStart = @"Start";
NSString * const QLRCueTypeDevamp = @"Devamp";
NSString * const QLRCueTypeLoad = @"Load";
NSString * const QLRCueTypeScript = @"Script";
NSString * const QLRCueTypeGoto = @"Goto";
NSString * const QLRCueTypeTarget = @"Target";
NSString * const QLRCueTypeWait = @"Wait";
NSString * const QLRCueTypeMemo = @"Memo";
NSString * const QLRCueTypeArm = @"Arm";
NSString * const QLRCueTypeDisarm = @"Disarm";
NSString * const QLRCueTypeStagetracker = @"Stagetracker";

// OSC key constants
NSString * const QLROSCNameKey = @"name";
NSString * const QLROSCNumberKey = @"number";
NSString * const QLROSCNotesKey = @"notes";
NSString * const QLROSCColorNameKey = @"colorName";
NSString * const QLROSCFlaggedKey = @"flagged";
NSString * const QLROSCArmedKey = @"armed";

// Identifiers for "fake" cues
NSString * const QLRActiveCueListIdentifier = @"__active__";
NSString * const QLRRootCueIdentifier = @"__root__";

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
  _type = QLRCueTypeCue;
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
  
  if ([_type isEqualToString:QLRCueTypeGroup]) {
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
- (void)updatePropertiesWithDict:(NSDictionary *)dict
{
#if DEBUG
  //NSLog(@"updateProperties: %@", dict);
#endif
  
  // We don't know what properties are present, so we need to check for the existence of every property because we don't want to overwrite an existing value with nil
  // Probably a better way to do this
  
  // Default properties
  
  if (dict[QLROSCNameKey]) {
    self.name = dict[QLROSCNameKey];
    [self updateDisplayName];
  }
  
  if (dict[QLROSCNumberKey]) {
    self.number = dict[QLROSCNumberKey];
    [self updateDisplayName];
  }
  
  if (dict[QLROSCNotesKey]) {
    self.notes = dict[QLROSCNotesKey];
  }
  
  if (dict[QLROSCColorNameKey]) {
    self.color = [QLKColor colorWithName:dict[QLROSCColorNameKey]];
  }
  
  if (dict[QLROSCFlaggedKey]) {
    self.flagged = [dict[QLROSCFlaggedKey] boolValue];
  }
  
  if (dict[QLROSCArmedKey]) {
    self.armed = [dict[QLROSCArmedKey] boolValue];
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

  [[NSNotificationCenter defaultCenter] postNotificationName:QLRCueUpdatedNotification object:self];
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
  if ([type isEqualToString:QLRCueTypeMIDIFile]) {
    return @"midi-file";
  } else if ([type isEqualToString:QLRCueTypeMicrophone]) {
    return @"microphone";
  } else {
    return [type lowercaseString];
  }
}

- (BOOL)isAudio
{
	return ([self.type isEqualToString:QLRCueTypeAudio] || [self.type isEqualToString:QLRCueTypeMicrophone] || [self.type isEqualToString:QLRCueTypeFade] || [self isVideo]);
}

- (BOOL)isVideo
{
	return ([self.type isEqualToString:QLRCueTypeVideo] || [self.type isEqualToString:QLRCueTypeCamera]);
}

- (BOOL)isGroup
{
	return [self.type isEqualToString:QLRCueTypeGroup];
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
