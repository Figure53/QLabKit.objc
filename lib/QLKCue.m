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



@interface QLKCue ()

@property (nonatomic, weak) QLKWorkspace *workspace;
//- (void) updateDisplayName; deprecated
- (NSArray *) flattenCuesWithDepth:(NSInteger)depth;

@end

@implementation QLKCue

- (id) init
{
    self = [super init];
    if ( !self )
        return nil;

    self.cueData = [NSMutableDictionary dictionary];
    [self setProperty:[NSNull null]
               forKey:@"uniqueID"
          doUpdateOSC:NO];
    [self setProperty:@""
               forKey:QLKOSCNumberKey
          doUpdateOSC:NO];
    [self setProperty:@"(Untitled Cue)"
               forKey:QLKOSCNameKey
          doUpdateOSC:NO];
    [self setProperty:@""
               forKey:QLKOSCNotesKey
          doUpdateOSC:NO];
    [self setProperty:@""
               forKey:@"listName"
          doUpdateOSC:NO];
    [self setProperty:@(NO)
               forKey:QLKOSCFlaggedKey
          doUpdateOSC:NO];
    [self setProperty:@"none"
               forKey:@"colorName"
          doUpdateOSC:NO];
    [self setProperty:QLKCueTypeCue
               forKey:@"type"
          doUpdateOSC:NO];
    [self setProperty:[NSMutableArray array]
               forKey:@"cues"
          doUpdateOSC:NO];
    [self setProperty:@(0)
               forKey:@"depth"
          doUpdateOSC:NO];
    [self setProperty:@(NO)
               forKey:@"expanded"
          doUpdateOSC:NO];
    [self setProperty:@[]
               forKey:@"patches"
          doUpdateOSC:NO];

    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict workspace:(QLKWorkspace *)workspace {
    self = [self initWithDictionary:dict];
    self.workspace = workspace;
    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict
{
    self = [self init];
    if ( !self )
        return nil;
    
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    [tempDict addEntriesFromDictionary:self.cueData];
    [tempDict addEntriesFromDictionary:dict]; //adding will overwrite
    self.cueData = [NSMutableDictionary dictionaryWithDictionary:tempDict];
    NSMutableArray *children = [NSMutableArray array];
    for (NSDictionary *subdict in [self propertyForKey:@"cues"]) {
        [children addObject:[QLKCue cueWithDictionary:subdict]];
    }
    [self setProperty:children
               forKey:@"cues"
          doUpdateOSC:NO];

    _icon = [QLKImage imageNamed:[self iconFile]];
    
//    [self updateDisplayName];

    return self;
}

+ (QLKCue *) cueWithDictionary:(NSDictionary *)dict
{
    return [[QLKCue alloc] initWithDictionary:dict];
}

- (id)valueForKey:(NSString *)key {
    return [self propertyForKey:key];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"(Cue: %p) name: %@ [id:%@ number:%@ type:%@]",
                                      self,
                                      [self propertyForKey:QLKOSCNameKey],
                                      [self propertyForKey:@"uniqueID"],
                                      [self propertyForKey:QLKOSCNumberKey],
                                      [self propertyForKey:@"type"]];
}

- (BOOL) isEqual:(id)object
{
    if ( self == object )
    {
        return YES;
    }
    else if ( !object || ![object isKindOfClass:[self class]] )
    {
        return NO;
    }
    else
    {
        return [self isEqualToCue:object];
    }
}

- (NSUInteger) hash
{
    return [[self propertyForKey:@"uniqueID"] hash];
}

- (BOOL) isEqualToCue:(QLKCue *)cue
{
    return [[self propertyForKey:@"uniqueID"] isEqualToString:[cue propertyForKey:@"uniqueID"]];
}

// Basic properties
- (void) updatePropertiesWithDictionary:(NSDictionary *)dict
{
#if DEBUG
    //NSLog(@"updateProperties: %@", dict);
#endif
  
    //Merge existing properties with new properties dict (conflicts default overwrite)
    //Complex properties now gathered with instance methods:
        //- (QLKColor *)color;
        //- (GLKQuaternion)quaternion
    
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    [tempDict addEntriesFromDictionary:self.cueData];
    [tempDict addEntriesFromDictionary:dict];
    self.cueData = [NSMutableDictionary dictionaryWithDictionary:tempDict];

    [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueUpdatedNotification object:self];
}

- (NSString *)displayName {
    NSString *name = [self nonEmptyName];
    NSString *number = (![[self propertyForKey:QLKOSCNumberKey] isEqualToString:@""]) ? [NSString stringWithFormat:@"%@: ", [self propertyForKey:QLKOSCNumberKey]] : @"";
    
    return [NSString stringWithFormat:@"%@%@",number, name];
}

- (NSString *) nonEmptyName
{
    NSString *nename, //non-empty name placeholder return value
             *name = [self propertyForKey:QLKOSCNameKey],
             *listName = [self propertyForKey:@"listName"];

    if ( name && ![name isEqualToString:@""] )
    {
        nename = name;
    }
    else if ( listName && ![listName isEqualToString:@""] )
    {
        nename = listName;
    }
    else
    {
        nename = [NSString stringWithFormat:@"(Untitled %@ Cue)", [self propertyForKey:@"type"]];
    }

    return nename;
}

- (NSString *) iconFile
{
    return [NSString stringWithFormat:@"%@.png", [QLKCue iconForType:[self propertyForKey:@"type"]]];
}

// Map cue type to icon
+ (NSString *) iconForType:(NSString *)type
{
    if ( [type isEqualToString:QLKCueTypeMIDIFile] )
    {
        return @"midi-file";
    }
    else if ([type isEqualToString:QLKCueTypeMicrophone])
    {
        return @"microphone";
    }
    else
    {
        return [type lowercaseString];
    }
}

- (BOOL) isAudio
{
    NSString *type = [self propertyForKey:@"type"];
	return ([type isEqualToString:QLKCueTypeAudio] || [type isEqualToString:QLKCueTypeMicrophone] || [type isEqualToString:QLKCueTypeFade] || [self isVideo]);
}

- (BOOL) isVideo
{
    NSString *type = [self propertyForKey:@"type"];
	return ([type isEqualToString:QLKCueTypeVideo] || [type isEqualToString:QLKCueTypeCamera]);
}

- (BOOL) isGroup
{
    NSString *type = [self propertyForKey:@"type"];
	return [type isEqualToString:QLKCueTypeGroup];
}

- (BOOL) hasChildren
{
    return [self isGroup] && [[self propertyForKey:@"cues"] count] > 0;
}

#pragma mark - Children cues

- (QLKCue *) firstCue
{
    return [self hasChildren] ? [[self propertyForKey:@"cues"] objectAtIndex:0] : nil;
}

- (QLKCue *) lastCue
{
    return [self hasChildren] ? [[self propertyForKey:@"cues"] lastObject] : nil;
}

- (QLKCue *) cueAtIndex:(NSInteger)index
{
    return ([self hasChildren] && [[self propertyForKey:@"cues"] count] > index) ? [[self propertyForKey:@"cues"] objectAtIndex: index] : nil;
}

// Recursively search for a cue with a matching id
- (QLKCue *) cueWithId:(NSString *)cueId
{
    
    for ( QLKCue *cue in [self propertyForKey:@"cues"] )
    {
        if ( [[cue propertyForKey:@"uniqueID"] isEqualToString:cueId] )
        {
            return cue;
        }

        if ( [cue isGroup] )
        {
            QLKCue *childCue = [cue cueWithId:cueId];
            if ( childCue )
                return childCue;
        }
    }

    return nil;
}

- (NSArray *) flattenedCues
{
    return [self flattenCuesWithDepth:0];
}

- (NSArray *) flattenCuesWithDepth:(NSInteger)depth
{
    NSMutableArray *cues = [NSMutableArray array];

    for ( QLKCue *cue in [self propertyForKey:@"cues"] )
    {
        [cue setProperty:@(depth)
                  forKey:@"depth"
             doUpdateOSC:NO];
        [cues addObject:cue];

        if ( [cue isGroup] && [[cue propertyForKey:@"expanded"] boolValue])
        {
            [cues addObjectsFromArray:[cue flattenCuesWithDepth:depth + 1]];
        }
    }

    return cues;
}

#pragma mark - Accessors

- (NSString *) surfaceName
{
    NSArray *surfaces = [self.cueData valueForKey:@"surfaces"] ? [[self.cueData valueForKey:@"surfaces"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"surfaceID == %@", @([[self propertyForKey:@"surfaceID"] integerValue])]] : @[];

    return (surfaces.count > 0) ? surfaces[0][@"surfaceName"] : nil;
}

- (NSString *) patchName
{
    NSArray *patches = ([self.cueData valueForKey:@"patches"]) ? [[self.cueData valueForKey:@"patches"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patchNumber == %@", @([[self propertyForKey:@"patch"] integerValue])]] : @[];

    return (patches.count > 0) ? patches[0][@"patchName"] : nil;
}

- (QLKColor *) color {
    return [QLKColor colorWithName:[self propertyForKey:@"colorName"]];
}

- (GLKQuaternion)quaternion {
    NSArray *quaternionComponents = [self.cueData valueForKey:@"quaternion"];
    return GLKQuaternionMake([quaternionComponents[0] floatValue], [quaternionComponents[1] floatValue], [quaternionComponents[2] floatValue], [quaternionComponents[3] floatValue]);
}

- (CGSize)surfaceSize {
    id surfaceSize = [self.cueData valueForKey:@"surfaceSize"];
    return CGSizeMake([surfaceSize[@"width"] floatValue], [surfaceSize[@"height"] floatValue]);
}

- (CGSize)cueSize {
    id cueSize = [self.cueData valueForKey:@"cueSize"];
    return CGSizeMake([cueSize[@"width"] floatValue], [cueSize[@"height"] floatValue]);
}

- (void)setProperty:(id)value forKey:(NSString *)propertyKey doUpdateOSC:(BOOL)osc {
    //change the value
    [self.cueData setValue:value
                    forKey:propertyKey];
    
    //send network update
    if (osc) {
        [self.workspace cue:self updatePropertySend:value forKey:propertyKey];
    }
}

- (id)propertyForKey:(NSString *)key {
    //retrieve the value
    if ([key isEqualToString:@"surfaceName"]) {
        return [self surfaceName];
    } else if ([key isEqualToString:@"patchName"]) {
        return [self patchName];
    } else if ([key isEqualToString:@"color"]) {
        return [self color];
    } else
        return ([self.cueData valueForKey:key]);
}

#pragma mark - Deprecated Accessors
//accessors
- (NSString *)uid {
    return [self propertyForKey:@"uniqueID"];
}
- (NSString *)name {
    return [self propertyForKey:QLKOSCNameKey];
}
- (NSString *)listName {
    return [self propertyForKey:@"listName"];
}
- (NSString *)number {
    return [self propertyForKey:QLKOSCNumberKey];
}
- (BOOL)flagged {
    return [[self propertyForKey:QLKOSCFlaggedKey] boolValue];
}
- (NSString *)type {
    return [self propertyForKey:@"type"];
}
- (NSString *)notes {
    return [self propertyForKey:QLKOSCNotesKey];
}

//mutators
- (void)setUid:(NSString *)uid {
    [self setProperty:uid
               forKey:@"uniqueID"
          doUpdateOSC:NO];
}
- (void)setName:(NSString *)name {
    [self setProperty:name
               forKey:QLKOSCNameKey
          doUpdateOSC:NO];
}
- (void)setListName:(NSString *)listName {
    [self setProperty:listName
               forKey:@"listName"
          doUpdateOSC:NO];
}
- (void)setNumber:(NSString *)number {
    [self setProperty:number
               forKey:QLKOSCNumberKey
          doUpdateOSC:NO];
}
- (void)setFlagged:(BOOL)flagged {
    [self setProperty:@(flagged)
               forKey:QLKOSCFlaggedKey
          doUpdateOSC:NO];
}
- (void)setType:(NSString *)type {
    [self setProperty:type
               forKey:@"type"
          doUpdateOSC:NO];
}
- (void)setNotes:(NSString *)notes {
    [self setProperty:notes
               forKey:QLKOSCNotesKey
          doUpdateOSC:NO];
}

@end
