//
//  QLKCue.m
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


#import "QLKCue.h"
#import "QLKColor.h"
#import "QLKCue_private.h"


@interface QLKCue ()

@property (nonatomic, weak) QLKWorkspace *workspace;
@property (strong, nonatomic) NSMutableDictionary *cueData;

@end

@implementation QLKCue

- (id) init
{
    self = [super init];
    if ( !self )
        return nil;
    
    self.cueData = [NSMutableDictionary dictionary];
    
    return self;
}

- (id) initWithWorkspace:(QLKWorkspace *)workspace
{
    self = [self init];
    self.workspace = workspace;
    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict workspace:(QLKWorkspace *)workspace
{
    self = [self init];
    if ( !self )
        return nil;
    self.workspace = workspace;
    [self updatePropertiesWithDictionary:dict];
    
    return self;
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"(Cue: %p) name: %@ [id:%@ number:%@ type:%@]",
            self,
            self.name,
            self.uid,
            self.number,
            self.type];
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
    return [self.uid hash];
}

- (BOOL) isEqualToCue:(QLKCue *)cue
{
    return [self.uid isEqualToString:cue.uid];
}

// Basic properties
- (void) updatePropertiesWithDictionary:(NSDictionary *)dict
{
#if DEBUG
    //NSLog(@"updateProperties: %@", dict);
#endif
    
    //Merge existing properties with new properties dict (conflicts default overwrite)
    //If incoming dictionary is lacking a key that is stored locally, preserve the entry
    //Complex properties now gathered with instance methods:
    //- (QLKColor *)color;
    //- (GLKQuaternion)quaternion
    
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    [tempDict addEntriesFromDictionary:self.cueData];
    NSMutableArray *children = [NSMutableArray array];
    
    for (NSDictionary *subdict in dict[QLKOSCCuesKey]) {
        //if we have a child matching this UID, then update; otherwise, insert. If the cue is no longer there, then it is lost locally too.
        QLKCue *subcue = [self cueWithId:subdict[QLKOSCUIDKey]];
        if (subcue) {
            [subcue updatePropertiesWithDictionary:subdict];
            [children addObject:subcue];
        } else {
            [children addObject:[[QLKCue alloc]  initWithDictionary:subdict workspace:self.workspace]];
        }
    }
    [tempDict addEntriesFromDictionary:dict]; //adding will overwrite
    self.cueData = [NSMutableDictionary dictionaryWithDictionary:tempDict];
    
    if (dict[QLKOSCCuesKey]) {
        [self setProperty:children
                   forKey:QLKOSCCuesKey
              tellQLab:NO];
    }
    
    _icon = [QLKImage imageNamed:[self iconFile]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueUpdatedNotification object:self];
}

- (void) sendAllPropertiesToQLab
{
    NSArray *cueArray = [self propertyForKey:QLKOSCCuesKey];
    if (cueArray != nil)
        for (QLKCue *cue in cueArray)
            [cue sendAllPropertiesToQLab];
    for (NSString *key in [self.cueData allKeys]) {
        if ([key isEqualToString:QLKOSCCuesKey]) continue;
        [self.workspace cue:self
         updatePropertySend:[self propertyForKey:key]
                     forKey:key];
    }
}

- (NSString *) displayName
{
    NSString *name = [self nonEmptyName];
    NSString *number = (![[self propertyForKey:QLKOSCNumberKey] isEqualToString:@""]) ? [NSString stringWithFormat:@"%@: ", self.number] : @"";
    return [NSString stringWithFormat:@"%@%@",number, name];
}

- (NSString *) nonEmptyName
{
    NSString *nonEmptyName; //non-empty name placeholder return value
    
    if ( self.name && ![self.name isEqualToString:@""] )
    {
        nonEmptyName = self.name;
    }
    else if ( self.listName && ![self.listName isEqualToString:@""] )
    {
        nonEmptyName = self.listName;
    }
    else
    {
        nonEmptyName = [NSString stringWithFormat:@"(Untitled %@ Cue)", self.type];
    }
    
    return nonEmptyName;
}

- (NSString *) iconFile
{
    return [NSString stringWithFormat:@"%@.png", [QLKCue iconForType:self.type]];
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

- (NSString *) workspaceName
{
    return self.workspace.name;
}

- (BOOL) isAudio
{
	return ([self.type isEqualToString:QLKCueTypeAudio] || [self.type isEqualToString:QLKCueTypeMicrophone] || [self.type isEqualToString:QLKCueTypeFade] || [self isVideo]);
}

- (BOOL) isVideo
{
	return ([self.type isEqualToString:QLKCueTypeVideo] || [self.type isEqualToString:QLKCueTypeCamera]);
}

- (BOOL) isGroup
{
	return [self.type isEqualToString:QLKCueTypeGroup];
}

- (BOOL) hasChildren
{
    return [self isGroup] && [[self propertyForKey:QLKOSCCuesKey] count] > 0;
}

#pragma mark - Children cues

- (QLKCue *) firstCue
{
    return [self hasChildren] ? [[self propertyForKey:QLKOSCCuesKey] objectAtIndex:0] : nil;
}

- (QLKCue *) lastCue
{
    return [self hasChildren] ? [[self propertyForKey:QLKOSCCuesKey] lastObject] : nil;
}

- (QLKCue *) cueAtIndex:(NSInteger)index
{
    return ([self hasChildren] && [[self propertyForKey:QLKOSCCuesKey] count] > index) ? [[self propertyForKey:QLKOSCCuesKey] objectAtIndex: index] : nil;
}

// Recursively search for a cue with a matching id
- (QLKCue *) cueWithId:(NSString *)cueId
{
    for ( QLKCue *cue in [self propertyForKey:QLKOSCCuesKey] )
    {
        if ( [cue.uid isEqualToString:cueId] )
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

- (QLKCue *) cueWithNumber:(NSString *)number
{
    for ( QLKCue *cue in [self propertyForKey:QLKOSCCuesKey] )
    {
        if ( [cue.number isEqualToString:number] )
        {
            return cue;
        }
        
        if ( [cue isGroup] )
        {
            QLKCue *childCue = [cue cueWithNumber:number];
            if ( childCue )
                return childCue;
        }
    }
    return nil;
}

#pragma mark - Accessors

- (NSString *) surfaceName
{
    NSArray *surfaces = [self.cueData valueForKey:@"surfaceList"] ? [[self.cueData valueForKey:@"surfaceList"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"surfaceID == %@", @([[self propertyForKey:QLKOSCSurfaceIDKey] integerValue])]] : @[];
    
    return (surfaces.count > 0) ? surfaces[0][@"surfaceName"] : nil;
}

- (NSString *) patchName
{
    NSArray *patches = ([self.cueData valueForKey:@"patchList"]) ? [[self.cueData valueForKey:@"patchList"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patchNumber == %@", @([[self propertyForKey:QLKOSCPatchKey] integerValue])]] : @[];
    
    return (patches.count > 0) ? patches[0][@"patchName"] : nil;
}

- (QLKColor *) color
{
    return [QLKColor colorWithName:[self propertyForKey:QLKOSCColorNameKey]];
}

- (GLKQuaternion) quaternion
{
    NSArray *quaternionComponents = [self.cueData valueForKey:@"quaternion"];
    return GLKQuaternionMake([quaternionComponents[0] floatValue], [quaternionComponents[1] floatValue], [quaternionComponents[2] floatValue], [quaternionComponents[3] floatValue]);
}

- (CGSize) surfaceSize
{
    id surfaceSize = [self.cueData valueForKey:@"surfaceSize"];
    return CGSizeMake([surfaceSize[@"width"] floatValue], [surfaceSize[@"height"] floatValue]);
}

- (CGSize) cueSize
{
    id cueSize = [self.cueData valueForKey:@"cueSize"];
    return CGSizeMake([cueSize[@"width"] floatValue], [cueSize[@"height"] floatValue]);
}

- (void) setProperty:(id)value forKey:(NSString *)propertyKey tellQLab:(BOOL)osc
{
    // change the value
    [self.cueData setValue:value
                    forKey:propertyKey];
    
    // send network update
    if (osc) {
        [self.workspace cue:self updatePropertySend:value forKey:propertyKey];
    }
}

- (void) setProperty:(id)value forKey:(NSString *)propertyKey
{
    [self setProperty:value
               forKey:propertyKey
             tellQLab:[[self workspace] defaultSendUpdatesOSC]];
}

- (id) propertyForKey:(NSString *)key
{
    // retrieve the value
    if ([key isEqualToString:@"surfaceName"]) {
        return [self surfaceName];
    } else if ([key isEqualToString:@"patchName"]) {
        return [self patchName];
    } else if ([key isEqualToString:@"color"]) {
        return [self color];
    } else if ([key isEqualToString:@"quaternion"]) {
        GLKQuaternion quaternion = [self quaternion];
        return [NSValue valueWithBytes:&quaternion objCType:@encode(GLKQuaternion)];
    }
    else
        return ([self.cueData valueForKey:key]);
}

- (NSArray *) propertyKeys
{
    return [self.cueData allKeys];
}

- (void) pushDownProperty:(id)value forKey:(NSString *)propertyKey
{
    if (!propertyKey) {
#if DEBUG
        NSLog(@"You can't set property on nil key.");
#endif
        return;
    }
    id old_data = [self propertyForKey:propertyKey];
    
    [self setProperty:value
               forKey:propertyKey
          tellQLab:NO];
    
    id null = [NSNull null];
    [[NSNotificationCenter defaultCenter] postNotificationName:QLKCueHasNewDataNotification
                                                        object:@{@"workspaceName": self.workspace.name?self.workspace.name:null,
                                                                 @"cueNumber": self.number?self.number:null,
                                                                 @"propertyKey": propertyKey?propertyKey:null,
                                                                 @"oldData": old_data?old_data:null,
                                                                 @"newData": value?value:null}];
}

- (void) pushUpProperty:(id)value forKey:(NSString *)propertyKey
{
    [self setProperty:value
               forKey:propertyKey
          tellQLab:YES];
}

- (void) triggerPushDownPropertyForKey:(NSString *)propertyKey
{
    [self.workspace cue:self
            valueForKey:propertyKey
             completion:^(id data) {
//                 if (![data isEqual:[self propertyForKey:propertyKey]])
                     [self pushDownProperty:data
                                     forKey:propertyKey];
             }];
}

- (void) pullDownPropertyForKey:(NSString *)propertyKey block:(void (^) (id value))block
{
    [self.workspace cue:self
            valueForKey:propertyKey
             completion:^(id data) {
                 [self setProperty:data
                            forKey:propertyKey
                       tellQLab:NO];
                 block(data);
             }];
    
}

#pragma mark - Actions

- (void) reset
{
    [self.workspace resetCue:self];
}

- (void) start
{
    [self.workspace startCue:self];
}

- (void) stop
{
    [self.workspace stopCue:self];
}

- (void) load
{
    [self.workspace loadCue:self];
}

- (void) pause
{
    [self.workspace pauseCue:self];
}

- (void) resume
{
    [self.workspace resumeCue:self];
}

- (void) hardStop
{
    [self.workspace hardStopCue:self];
}

- (void) togglePause
{
    [self.workspace togglePauseCue:self];
}

- (void) preview
{
    [self.workspace previewCue:self];
}

- (void) panic
{
    [self.workspace panicCue:self];
}

#pragma mark - Convenience Accessors

- (NSString *) uid
{
    return [self propertyForKey:QLKOSCUIDKey];
}

- (NSString *) name
{
    return [self propertyForKey:QLKOSCNameKey];
}

- (NSString *) listName
{
    return [self propertyForKey:QLKOSCListNameKey];
}

- (NSString *) number
{
    return [self propertyForKey:QLKOSCNumberKey];
}

- (BOOL) flagged
{
    return [[self propertyForKey:QLKOSCFlaggedKey] boolValue];
}

- (NSString *) type
{
    return [self propertyForKey:QLKOSCTypeKey];
}

- (NSString *) notes
{
    return [self propertyForKey:QLKOSCNotesKey];
}

- (NSArray *) cues
{
    return [self propertyForKey:QLKOSCCuesKey];
}

// mutators

- (void) setUid:(NSString *)uid
{
    [self setProperty:uid forKey:QLKOSCUIDKey];
}

- (void) setName:(NSString *)name
{
    [self setProperty:name
               forKey:QLKOSCNameKey];
}

- (void) setListName:(NSString *)listName
{
    [self setProperty:listName
               forKey:QLKOSCListNameKey];
}

- (void) setNumber:(NSString *)number
{
    [self setProperty:number
               forKey:QLKOSCNumberKey];
}

- (void) setFlagged:(BOOL)flagged
{
    [self setProperty:@(flagged)
               forKey:QLKOSCFlaggedKey];
}

- (void) setType:(NSString *)type
{
    [self setProperty:type
               forKey:QLKOSCTypeKey];
}

- (void) setNotes:(NSString *)notes
{
    [self setProperty:notes
               forKey:QLKOSCNotesKey];
}

- (void) setCues:(NSArray *)cues
{
    [self setProperty:cues forKey:QLKOSCCuesKey];
}

@end
