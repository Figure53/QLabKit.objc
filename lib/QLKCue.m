//
//  QLKCue.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2017 Figure 53 LLC, http://figure53.com
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


NS_ASSUME_NONNULL_BEGIN

@interface QLKCue () {
    NSUInteger _sortIndex;
    NSArray<QLKCue *> *_childCuesSorted;
    
    QLKImage *_icon;
    BOOL _isAudio;
    BOOL _isVideo;
    BOOL _isGroup;
    BOOL _isCueList;
    BOOL _isCueCart;
    
    //unsigned long _random;     //debug
}

@property (nonatomic, weak, readwrite, nullable)    QLKWorkspace *workspace;
@property (nonatomic, strong, readonly)             NSMutableDictionary<NSString *, id> *cueData;
@property (nonatomic, strong, readonly)             NSMapTable<NSString *, QLKCue *> *childCuesUIDMap;

@property (nonatomic, strong, readonly)             dispatch_queue_t dataQueue;
@property (nonatomic, strong, readonly)             dispatch_queue_t childPropertiesQueue;

- (NSArray<QLKCue *> *) _arrayWithSortedChildCues:(NSArray<QLKCue *> *)childCues;

@end


@implementation QLKCue

- (instancetype) init
{
    self = [super init];
    if ( self )
    {
        _cueData = [NSMutableDictionary dictionaryWithCapacity:30]; // total possible keys is closer to 65, but 30 allows for most commonly used keys -- just so we aren't initially overallocating for keys more rarely used
        [_cueData setValuesForKeysWithDictionary:@{
                                                   QLKOSCFlaggedKey : @NO,
                                                   QLKOSCArmedKey : @YES,
                                                   QLKOSCPreWaitKey : @0.0,
                                                   QLKOSCPercentPreWaitElapsedKey : @0.0,
                                                   QLKOSCPercentActionElapsedKey : @0.0,
                                                   QLKOSCPostWaitKey : @0.0,
                                                   QLKOSCPercentPostWaitElapsedKey : @0.0,
                                                   QLKOSCIsPanickingKey : @NO,
                                                   QLKOSCIsTailingOutKey : @NO,
                                                   QLKOSCIsRunningKey : @NO,
                                                   QLKOSCIsLoadedKey : @NO,
                                                   QLKOSCIsPausedKey : @NO,
                                                   QLKOSCIsBrokenKey : @NO,
                                                   QLKOSCIsOverriddenKey : @NO,
                                                   QLKOSCContinueModeKey : @0,
                                                   }];
        _childCuesUIDMap = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0]; // only Group cues will have children, so default to 0 capacity
        _childCuesSorted = @[];
        
        _dataQueue = dispatch_queue_create( "com.figure53.QLabKit.QLKCue.dataQueue", DISPATCH_QUEUE_CONCURRENT );
        _childPropertiesQueue = dispatch_queue_create( "com.figure53.QLabKit.QLKCue.childPropertiesQueue", DISPATCH_QUEUE_SERIAL );
    }
    
    //_random = arc4random_uniform(999999999);  //debug
    //NSLog( @"init    %lu", _random );         //debug
    
    return self;
}

- (instancetype) initWithWorkspace:(QLKWorkspace *)workspace
{
    self = [self init];
    if ( self )
    {
        self.workspace = workspace;
    }
    return self;
}

- (instancetype) initWithDictionary:(NSDictionary<NSString *, id> *)dict workspace:(QLKWorkspace *)workspace
{
    self = [self init];
    if ( self )
    {
        self.workspace = workspace;
        [self updatePropertiesWithDictionary:dict];
    }
    return self;
}

//- (void) dealloc
//{
//    NSLog( @"dealloc %lu", _random );   //debug
//}

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
    return self.uid.hash;
}

- (BOOL) isEqualToCue:(QLKCue *)cue
{
    return ( cue.uid && [self.uid isEqualToString:(NSString * _Nonnull)cue.uid] );
}

NSInteger SortCuesBySortIndex( id id1, id id2, void *context )
{
    // Sort Function
    NSUInteger cue1Index = ((QLKCue *)id1).sortIndex;
    NSUInteger cue2Index = ((QLKCue *)id2).sortIndex;
    
    if ( cue1Index < cue2Index )
        return NSOrderedAscending;
    else if ( cue1Index > cue2Index )
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (NSArray<QLKCue *> *) _arrayWithSortedChildCues:(NSArray<QLKCue *> *)childCues
{
    NSData *hint = childCues.sortedArrayHint;
    NSArray *sortedCues = [childCues sortedArrayUsingFunction:SortCuesBySortIndex context:nil hint:hint];
    return sortedCues;
}

- (void) addChildCue:(QLKCue *)cue
{
    NSString *uid = [cue propertyForKey:QLKOSCUIDKey];
    [self addChildCue:cue withID:uid];
}

- (void) addChildCue:(QLKCue *)cue withID:(NSString *)uid
{
    if ( uid.length == 0 )
        return;
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async( self.dataQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        [strongSelf.childCuesUIDMap setObject:cue forKey:uid];
        strongSelf->_childCuesSorted = [strongSelf _arrayWithSortedChildCues:strongSelf.childCuesUIDMap.objectEnumerator.allObjects];
        
    });
}

- (void) removeChildCue:(QLKCue *)cue
{
    NSString *uid = [cue propertyForKey:QLKOSCUIDKey];
    
    if ( uid.length == 0 )
        return;
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async( self.dataQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        [strongSelf.childCuesUIDMap removeObjectForKey:uid];
        strongSelf->_childCuesSorted = [strongSelf _arrayWithSortedChildCues:strongSelf.childCuesUIDMap.objectEnumerator.allObjects];
        
    });
}

- (void) removeAllChildCues
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async( self.dataQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        [strongSelf.childCuesUIDMap removeAllObjects];
        strongSelf->_childCuesSorted = @[];
        
    });
}

- (void) removeChildCuesWithIDs:(NSArray<NSString *> *)uids
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async( self.dataQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        for ( NSString *aUid in uids )
        {
            [strongSelf.childCuesUIDMap removeObjectForKey:aUid];
        }
        strongSelf->_childCuesSorted = [strongSelf _arrayWithSortedChildCues:strongSelf.childCuesUIDMap.objectEnumerator.allObjects];
        
    });
}



#pragma mark - Class methods

+ (NSString *) iconForType:(NSString *)type
{
    // Map cue type to icon
    if ( [type isEqualToString:QLKCueTypeMIDIFile] )
    {
        return @"midi-file";
    }
    else
    {
        return type.lowercaseString;
    }
}

+ (BOOL) cueTypeIsAudio:(NSString *)type
{
    if ( [type isEqualToString:QLKCueTypeAudio] )
        return YES;
    
    if ( [type isEqualToString:QLKCueTypeMic] )
        return YES;
    
    if ( [type isEqualToString:QLKCueTypeFade] )
        return YES;
    
    if ( [QLKCue cueTypeIsVideo:type] )
        return YES;
    
    return NO;
}

+ (BOOL) cueTypeIsVideo:(NSString *)type
{
    if ( [type isEqualToString:QLKCueTypeVideo] )
        return YES;
    
    if ( [type isEqualToString:QLKCueTypeCamera] )
        return YES;
    
    if ( [type isEqualToString:QLKCueTypeText] )
        return YES;
    
    if ( [type isEqualToString:QLKCueTypeTitles] )
        return YES;
    
    return NO;
}

+ (BOOL) cueTypeIsGroup:(NSString *)type
{
    if ( [type isEqualToString:QLKCueTypeGroup] )
        return YES;
    
    if ( [QLKCue cueTypeIsCueList:type] )
        return YES;
    
    if ( [QLKCue cueTypeIsCueCart:type] )
        return YES;
    
    return NO;
}

+ (BOOL) cueTypeIsCueList:(NSString *)type
{
    if ( [type isEqualToString:QLKCueTypeCueList] )
        return YES;
    
    return NO;
}

+ (BOOL) cueTypeIsCueCart:(NSString *)type
{
    if ( [type isEqualToString:QLKCueTypeCart] )
        return YES;
    
    return NO;
}



#pragma mark - KVC-compliance

- (nullable id) valueForUndefinedKey:(NSString *)key
{
    return [self propertyForKey:key];
}

- (void) setValue:(nullable id)value forUndefinedKey:(NSString *)key
{
    [self setProperty:value forKey:key tellQLab:NO];
}



#pragma mark - Convenience Accessors

- (NSUInteger) sortIndex
{
    __block NSUInteger sortIndex = 0;
    dispatch_sync( self.dataQueue, ^{
        sortIndex = _sortIndex;
    });
    return sortIndex;
}

- (void) setSortIndex:(NSUInteger)sortIndex
{
    dispatch_barrier_async( self.dataQueue, ^{
        _sortIndex = sortIndex;
    });
}

- (nullable QLKImage *) icon
{
    __block QLKImage *icon = nil;
    __weak typeof(self) weakSelf = self;
    dispatch_sync( self.dataQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        icon = strongSelf->_icon;
        
    });
    return icon;
}

- (NSArray<QLKCue *> *) cues
{
    NSArray *cues = [self propertyForKey:QLKOSCCuesKey];
    if ( !cues )
        return @[];
    
    return cues;
}

- (nullable NSString *) parentID
{
    return [self propertyForKey:QLKOSCParentKey];
}

- (nullable NSString *) playbackPositionID
{
    return [self propertyForKey:QLKOSCPlaybackPositionIdKey];
}

- (nullable NSString *) name
{
    return [self propertyForKey:QLKOSCNameKey];
}

- (nullable NSString *) number
{
    return [self propertyForKey:QLKOSCNumberKey];
}

- (nullable NSString *) uid
{
    return [self propertyForKey:QLKOSCUIDKey];
}

- (nullable NSString *) listName
{
    return [self propertyForKey:QLKOSCListNameKey];
}

- (nullable NSString *) type
{
    return [self propertyForKey:QLKOSCTypeKey];
}

- (nullable NSString *) notes
{
    return [self propertyForKey:QLKOSCNotesKey];
}

- (BOOL) isFlagged
{
    return [[self propertyForKey:QLKOSCFlaggedKey] boolValue];
}

- (BOOL) isRunning
{
    if ( [[self propertyForKey:QLKOSCIsRunningKey] boolValue] )
        return YES;
    
    for ( QLKCue *cue in self.cues )
    {
        if ( cue.running )
            return YES;
    }
    
    return NO;
}

- (NSString *) displayName
{
    NSString *number = self.number;
    if ( number.length > 0 )
        return [NSString stringWithFormat:@"%@ \u00B7 %@", number, self.nonEmptyName];
    else
        return self.nonEmptyName;
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

- (nullable NSString *) workspaceName
{
    return self.workspace.name;
}

- (NSTimeInterval) currentDuration
{
    // return value for v4 key "currentDuration", if it exists
    // else fallback to v3 key for backward compatibility
    if ( [self propertyForKey:QLKOSCCurrentDurationKey] )
        return [[self propertyForKey:QLKOSCCurrentDurationKey] doubleValue];
    else
        return [[self propertyForKey:QLKOSCDurationKey] doubleValue];
}

- (nullable NSString *) surfaceName
{
    return [self propertyForKey:@"surfaceName"];
}

- (nullable NSString *) patchName
{
    return [self propertyForKey:@"patchDescription"][@"patchName"];
}

- (nullable QLKColor *) color
{
    return [self propertyForKey:@"color"];
}

- (GLKQuaternion) quaternion
{
    NSValue *quaternionValue = [self propertyForKey:QLKOSCQuaternionKey];
    
    GLKQuaternion quaternion;
    [quaternionValue getValue:&quaternion];
    
    return quaternion;
}

- (CGSize) surfaceSize
{
    id surfaceSize = [self propertyForKey:QLKOSCSurfaceSizeKey];
    return CGSizeMake( [surfaceSize[@"width"] floatValue], [surfaceSize[@"height"] floatValue] ) ;
}

- (CGSize) cueSize
{
    id cueSize = [self propertyForKey:QLKOSCCueSizeKey];
    return CGSizeMake( [cueSize[@"width"] floatValue], [cueSize[@"height"] floatValue] );
}

- (NSArray<NSString *> *) availableSurfaceNames
{
    NSMutableArray<NSString *> *surfaces = [NSMutableArray array];
    
    for ( id dict in [self propertyForKey:QLKOSCSurfaceListKey] )
    {
        if ( [dict isKindOfClass:[NSDictionary class]] == NO )
            continue;
        
        NSString *surfaceName = ((NSDictionary *)dict)[@"surfaceName"]; //THIS IS NOT an osc key, but rather the surface list contains a dictionary using this key
        [surfaces addObject:surfaceName];
    }
    
    return [NSArray arrayWithArray:surfaces];
}

- (NSArray<NSString *> *) propertyKeys
{
    __block NSArray *propertyKeys = nil;
    __weak typeof(_cueData) weakCueData = self.cueData;
    dispatch_sync( self.dataQueue, ^{
        propertyKeys = weakCueData.allKeys;
    });
    return propertyKeys;
}

- (BOOL) isAudio
{
    __block BOOL isAudio = NO;
    dispatch_sync( self.dataQueue, ^{
        isAudio = _isAudio;
    });
    return isAudio;
}

- (BOOL) isVideo
{
    __block BOOL isVideo = NO;
    dispatch_sync( self.dataQueue, ^{
        isVideo = _isVideo;
    });
    return isVideo;
}

- (BOOL) isGroup
{
    __block BOOL isGroup = NO;
    dispatch_sync( self.dataQueue, ^{
        isGroup = _isGroup;
    });
    return isGroup;
}

- (BOOL) isCueList
{
    __block BOOL isCueList = NO;
    dispatch_sync( self.dataQueue, ^{
        isCueList = _isCueList;
    });
    return isCueList;
}

- (BOOL) isCueCart
{
    __block BOOL isCueCart = NO;
    dispatch_sync( self.dataQueue, ^{
        isCueCart = _isCueCart;
    });
    return isCueCart;
}

- (BOOL) hasChildren
{
    return ( self.cues.count > 0 );
}

- (nullable QLKCue *) firstCue
{
    return self.cues.firstObject;
}

- (nullable QLKCue *) lastCue
{
    return self.cues.lastObject;
}

// mutators

- (void) setCues:(NSArray<QLKCue *> *)cues
{
    [self setProperty:cues
               forKey:QLKOSCCuesKey];
}

- (void) setName:(nullable NSString *)name
{
    [self setProperty:name
               forKey:QLKOSCNameKey];
}

- (void) setNumber:(nullable NSString *)number
{
    [self setProperty:number
               forKey:QLKOSCNumberKey];
}

- (void) setUid:(nullable NSString *)uid
{
    [self setProperty:uid
               forKey:QLKOSCUIDKey];
}

- (void) setListName:(nullable NSString *)listName
{
    [self setProperty:listName
               forKey:QLKOSCListNameKey];
}

- (void) setType:(nullable NSString *)type
{
    [self setProperty:type
               forKey:QLKOSCTypeKey];
}

- (void) setNotes:(nullable NSString *)notes
{
    [self setProperty:notes
               forKey:QLKOSCNotesKey];
}

- (void) setFlagged:(BOOL)flagged
{
    [self setProperty:@(flagged)
               forKey:QLKOSCFlaggedKey];
}



// Basic properties

- (BOOL) updatePropertiesWithDictionary:(NSDictionary<NSString *, id> *)dict
{
#if DEBUG
    //NSLog(@"updateProperties: %@", dict);
#endif
    return [self updatePropertiesWithDictionary:dict notify:YES];
}

- (BOOL) updatePropertiesWithDictionary:(NSDictionary<NSString *, id> *)dict notify:(BOOL)notify
{
#if DEBUG
//    NSLog(@"updateProperties: %@ notify: %@", dict, notify ? @"YES" : @"NO" );
#endif
    
    // Merge existing properties with new properties dict (conflicts default overwrite)
    // If incoming dictionary is lacking a key that is stored locally, preserve the entry
    
    BOOL cueUpdated = NO;
    
    // update values in cue, if needed
    for ( NSString *key in dict )
    {
        id value = dict[key];
        
        if ( [key isEqualToString:QLKOSCCuesKey] )
        {
            if ( [value isKindOfClass:[NSArray class]] == NO )
                continue;
            
            [self updateChildCuesWithPropertiesArray:(NSArray *)value removeUnused:NO];
        }
        else
        {
            BOOL didSetProperty = [self setProperty:value forKey:key tellQLab:NO];
            if ( didSetProperty )
                cueUpdated = YES;
        }
    }
    
    if ( notify && cueUpdated )
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async( dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ( !strongSelf )
                return;
            
            NSNotification *notification = [NSNotification notificationWithName:QLKCueUpdatedNotification object:strongSelf userInfo:nil];
            [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                       postingStyle:NSPostASAP
                                                       coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                           forModes:nil];
        });
    }
    
    return cueUpdated;
}

- (void) updateChildCuesWithPropertiesArray:(NSArray<NSDictionary *> *)data removeUnused:(BOOL)removeUnused
{
    // `data` contains an array of dictionary items, one item per cue in the group cue, meaning it can have 100s of entries, esp. when the group cue is a cue list of a large workspace
    // - so we process child cue updates on a separate queue to avoid blocking the main thread
    // because all of this processing happens in the background, it's not possible to return a BOOL from this update method like we do in `updatePropertiesWithDictionary:notify:`
    // - instead, we track whether any cues were updated and avoid unnecessary array sorting or posting QLKCueUpdatedNotification whenever possible
    
    __block BOOL cuesUpdated = NO;
    
    NSMutableArray<NSString *> *previousUids = nil;
    if ( removeUnused )
        previousUids = [NSMutableArray arrayWithArray:[self allChildCueUids]];
    
    __block BOOL needsSortChildCues = NO;
    __block NSUInteger index = 0;
    for ( NSDictionary<NSString *, id> *dict in data )
    {
        NSString *uid = dict[QLKOSCUIDKey];
        if ( !uid )
            continue;
        
        if ( removeUnused )
            [previousUids removeObject:uid];
        
        // NOTE: childPropertiesQueue is a serial queue, so index will be incremented correctly
        __weak typeof(self) weakSelf = self;
        dispatch_async( self.childPropertiesQueue, ^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ( !strongSelf )
                return;
            
            if ( !strongSelf.workspace.connected )
                return;
            
            @autoreleasepool
            {
                // if we have a child matching this UID, then update; otherwise, insert.
                // if the cue is no longer there, then it is lost locally too.
                QLKCue *child = [strongSelf cueWithID:uid includeChildren:NO];
                if ( child )
                {
                    BOOL didUpdateProperties = [child updatePropertiesWithDictionary:dict];
                    if ( didUpdateProperties )
                        cuesUpdated = YES;
                    
                    // mark for a re-sort if the order of this cue within the parent group has changed
                    if ( child.sortIndex != index )
                    {
                        needsSortChildCues = YES;
                        cuesUpdated = YES;
                        child.sortIndex = index;
                    }
                }
                else
                {
                    child = [[QLKCue alloc] initWithDictionary:dict workspace:strongSelf.workspace];
                    child.sortIndex = index;
                    [strongSelf addChildCue:child withID:uid];
                    
                    needsSortChildCues = NO; // addChildCue:withID: updates _childCuesSorted so we can reset the flag
                    cuesUpdated = YES;
                    
                    // NOTE: we queue the enqueing of these notifications on the same serial queue to ensure they are sent after we finish processing this dictionary.
                    // - this way, the responses from the notifications we send do not block the main queue until after we finish adding any new child cues
                    dispatch_async( strongSelf.childPropertiesQueue, ^{
                        
                        // NSNotifications should be sent on the main thread
                        dispatch_async( dispatch_get_main_queue(), ^{
                            NSNotification *notification = [NSNotification notificationWithName:QLKCueNeedsUpdateNotification
                                                                                         object:child];
                            [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                                       postingStyle:NSPostASAP
                                                                       coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                                           forModes:nil];
                        });
                        
                    });
                }
            }
            index++;
        });
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async( self.childPropertiesQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        // NOTE: this must be done after all blocks above have completed
        // - childPropertiesQueue is a serial queue, so this is safe
        if ( previousUids.count )
        {
            [strongSelf removeChildCuesWithIDs:previousUids];
            needsSortChildCues = NO; // removeChildCuesWithIDs: updates _childCuesSorted so we can reset the flag
            cuesUpdated = YES;
        }
       
        if ( needsSortChildCues )
        {
            __weak typeof(self) weakSelf2 = strongSelf;
            dispatch_sync( strongSelf.dataQueue, ^{
                
                __strong typeof(weakSelf2) strongSelf2 = weakSelf2;
                if ( !strongSelf2 )
                    return;
                
                strongSelf2->_childCuesSorted = [strongSelf2 _arrayWithSortedChildCues:strongSelf2.childCuesUIDMap.objectEnumerator.allObjects];
                
            });
        }
        
        if ( cuesUpdated )
        {
            dispatch_async( dispatch_get_main_queue(), ^{
                NSNotification *notification = [NSNotification notificationWithName:QLKCueUpdatedNotification object:strongSelf userInfo:nil];
                [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                           postingStyle:NSPostASAP
                                                           coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                               forModes:nil];
            });
        }

        
    });
}



#pragma mark - Children cues

- (NSArray<NSString *> *) allChildCueUids
{
    __block NSArray *allChildCueUids = nil;
    __weak typeof(_childCuesUIDMap) weakChildCuesUIDMap = self.childCuesUIDMap;
    dispatch_sync( self.dataQueue, ^{
        allChildCueUids = weakChildCuesUIDMap.keyEnumerator.allObjects;
    });
    return allChildCueUids;
}

- (nullable QLKCue *) cueAtIndex:(NSInteger)index
{
    NSArray *cues = self.cues;
    if ( index < 0 || (NSUInteger)index >= cues.count )
        return nil;
    
    return cues[index];
}

// Recursively search for a cue with a matching id
- (nullable QLKCue *) cueWithID:(NSString *)uid
{
    return [self cueWithID:uid includeChildren:YES];
}

- (nullable QLKCue *) cueWithID:(NSString *)uid includeChildren:(BOOL)includeChildren
{
    __block QLKCue *cue = nil;
    __weak typeof(_childCuesUIDMap) weakChildCuesUIDMap = self.childCuesUIDMap;
    dispatch_sync( self.dataQueue, ^{
        cue = [weakChildCuesUIDMap objectForKey:uid];
    });
    
    if ( cue )
        return cue;
    
    if ( !includeChildren )
        return nil;
    
    NSArray<QLKCue *> *cues = self.cues;
    for ( QLKCue *cue in cues )
    {
        if ( !cue.isGroup )
            continue;
        
        QLKCue *childCue = [cue cueWithID:uid includeChildren:includeChildren];
        if ( childCue )
            return childCue;
    }
    
    // all else
    return nil;
}

- (nullable QLKCue *) cueWithNumber:(NSString *)number
{
    NSArray<QLKCue *> *cues = self.cues;
    for ( QLKCue *cue in cues )
    {
        if ( [cue.number isEqualToString:number] )
            return cue;
        
        if ( cue.isGroup )
        {
            QLKCue *childCue = [cue cueWithNumber:number];
            if ( childCue )
                return childCue;
        }
    }
    
    // all else
    return nil;
}

- (nullable id) propertyForKey:(NSString *)key
{
    // retrieve the value
    if ( [key isEqualToString:@"surfaceName"] )
    {
        __block NSArray *surfaceList = nil;
        __block NSNumber *surfaceID = nil;
        __weak typeof(_cueData) weakCueData = self.cueData;
        dispatch_sync( self.dataQueue, ^{
            surfaceList = weakCueData[QLKOSCSurfaceListKey];
            surfaceID = weakCueData[QLKOSCSurfaceIDKey];
        });
        if ( surfaceList.count == 0 )
            return nil;
        if ( !surfaceID )
            return nil;
        
        __block NSArray *surfaces = nil;
        dispatch_sync( self.dataQueue, ^{
            surfaces = [surfaceList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"surfaceID == %@", @( surfaceID.integerValue )]];
        });
        if ( surfaces.count <= 0 )
            return nil;
        
        return surfaces.firstObject[@"surfaceName"];
    }
    else if ( [key isEqualToString:@"patchDescription"] )
    {
        __block NSArray *patchList = nil;
        __block NSNumber *patch = nil;
        __weak typeof(_cueData) weakCueData = self.cueData;
        dispatch_sync( self.dataQueue, ^{
            patchList = weakCueData[QLKOSCPatchListKey];
            patch = weakCueData[QLKOSCPatchKey];
        });
        if ( patchList.count == 0 )
            return nil;
        if ( !patch )
            return nil;
        
        __block NSArray *patches = nil;
        dispatch_sync( self.dataQueue, ^{
            patches = [patchList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patchNumber == %@", @( patch.integerValue )]];
        });
        if ( patches.count <= 0 )
            return nil;
        
        return patches.firstObject;
    }
    else if ( [key isEqualToString:@"color"] )
    {
        __block NSString *colorName = nil;
        __weak typeof(_cueData) weakCueData = self.cueData;
        dispatch_sync( self.dataQueue, ^{
            colorName = weakCueData[QLKOSCColorNameKey];
        });
        if ( !colorName )
            return nil;
        
        return [QLKColor colorWithName:colorName];
    }
    else if ( [key isEqualToString:QLKOSCQuaternionKey] )
    {
        GLKQuaternion quaternion = GLKQuaternionIdentity;
        
        __block NSArray<NSNumber *> *quaternionComponents = nil;
        __weak typeof(_cueData) weakCueData = self.cueData;
        dispatch_sync( self.dataQueue, ^{
            quaternionComponents = weakCueData[key];
        });
        
        if ( quaternionComponents )
        {
            quaternion = GLKQuaternionMake( (quaternionComponents[0]).floatValue,
                                           (quaternionComponents[1]).floatValue,
                                           (quaternionComponents[2]).floatValue,
                                           (quaternionComponents[3]).floatValue );
        }
        
        return [NSValue valueWithBytes:&quaternion objCType:@encode( GLKQuaternion )];
    }
    else if ( [key isEqualToString:QLKOSCCuesKey] )
    {
        __block NSArray *cues = nil;
        __weak typeof(_childCuesSorted) weakChildCuesSorted = _childCuesSorted;
        dispatch_sync( self.dataQueue, ^{
            cues = weakChildCuesSorted;
        });
        return cues;
    }
    else
    {
        __block id property = nil;
        __weak typeof(_cueData) weakCueData = self.cueData;
        dispatch_sync( self.dataQueue, ^{
            property = weakCueData[key];
        });
        return property;
    }
}

- (BOOL) setProperty:(nullable id)value forKey:(NSString *)key
{
    return [self setProperty:value
                      forKey:key
                    tellQLab:self.workspace.defaultSendUpdatesOSC];
}

- (BOOL) setProperty:(nullable id)value forKey:(NSString *)key tellQLab:(BOOL)osc
{
    // exit if the value is unchanged
    __block id existingValue = nil;
    __weak typeof(_cueData) weakCueData = self.cueData;
    dispatch_sync( self.dataQueue, ^{
        existingValue = weakCueData[key];
    });
    if ( existingValue == value )
        return NO;
    if ( [existingValue isEqual:value] )
        return NO;
    
    
    // NOTE: special case when connected to QLab 3:
    // - cue list cues in v4 have type "Cue List", but in v3 they are type "Group"
    // - for compatibility when connected to a v3 workspace, QLKWorkspace manually sets the QLKCue type for cue list cues to "Cue List" when adding new cue lists
    // - so here, we also then prevent the incoming v3 cue type value from overwriting our local QLKCue type when it is already "Cue List", i.e. in the course of processing any normal cue updated message for a cue list cue
    if ( self.workspace.connectedToQLab3 &&
        [key isEqualToString:QLKOSCTypeKey] &&
        [existingValue isEqualToString:QLKCueTypeCueList] &&
        [value isEqualToString:QLKCueTypeGroup] )
    {
        return NO;
    }
    
    
    // update the value
    if ( [key isEqualToString:QLKOSCCuesKey] )
    {
        if ( [value isKindOfClass:[NSArray class]] == NO )
            return NO;
        
        NSMapTable *newChildCuesUIDMap = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory capacity:((NSArray *)value).count];
        
        NSUInteger index = 0;
        NSString *uid = nil;
        for ( QLKCue *aCue in (NSArray *)value )
        {
            uid = aCue.uid;
            if ( !uid )
                continue;
            
            aCue.sortIndex = index;
            [newChildCuesUIDMap setObject:aCue forKey:(NSString * _Nonnull)uid];
            
            index++;
        }
        
        if ( [NSThread currentThread].isMainThread )
            [self willChangeValueForKey:key];
        else
            dispatch_sync( dispatch_get_main_queue(), ^{
                [self willChangeValueForKey:key];
            });
        
        __weak typeof(self) weakSelf = self;
        dispatch_sync( self.dataQueue, ^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ( !strongSelf )
                return;
            
            strongSelf->_childCuesUIDMap = newChildCuesUIDMap;
            strongSelf->_childCuesSorted = (NSArray *)value;
            
        });
        
        if ( [NSThread currentThread].isMainThread )
            [self didChangeValueForKey:key];
        else
            dispatch_sync( dispatch_get_main_queue(), ^{
                [self didChangeValueForKey:key];
            });
    }
    else if ( [key isEqualToString:QLKOSCPlaybackPositionIdKey] )
    {
        if ( !self.isCueList )
            return NO;
        
        if ( value && [value isKindOfClass:[NSString class]] == NO )
            return NO;
        
        // set to nil if QLab returns "none"
        if ( [(NSString *)value isEqualToString:@"none"] )
            value = nil;
        
        
        dispatch_sync( self.dataQueue, ^{
            if ( value )
                weakCueData[key] = value;
            else
                [weakCueData removeObjectForKey:key];
        });
        
        
        dispatch_block_t notifyBlock = ^{
            NSNotification *notification = [NSNotification notificationWithName:QLKCueListDidChangePlaybackPositionIDNotification object:self userInfo:nil];
            [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                       postingStyle:NSPostASAP
                                                       coalesceMask:( NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender )
                                                           forModes:nil];
        };
        if ( [NSThread currentThread].isMainThread )
            notifyBlock();
        else
            dispatch_async( dispatch_get_main_queue(), notifyBlock );
    }
    else
    {
        if ( [NSThread currentThread].isMainThread )
            [self willChangeValueForKey:key];
        else
            dispatch_sync( dispatch_get_main_queue(), ^{
                [self willChangeValueForKey:key];
            });
        
        dispatch_sync( self.dataQueue, ^{
            if ( value )
                weakCueData[key] = value;
            else
                [weakCueData removeObjectForKey:key];
        });
        
        if ( [NSThread currentThread].isMainThread )
            [self didChangeValueForKey:key];
        else
            dispatch_sync( dispatch_get_main_queue(), ^{
                [self didChangeValueForKey:key];
            });
    }
    
    // update cached vars
    if ( [key isEqualToString:QLKOSCTypeKey] )
    {
        QLKImage *icon = nil;
        BOOL isAudio = NO;
        BOOL isVideo = NO;
        BOOL isGroup = NO;
        BOOL isCueList = NO;
        BOOL isCueCart = NO;
        
        if ( value )
        {
            icon = [QLKImage imageNamed:[QLKCue iconForType:(NSString *)value]];
            isAudio = [[self class] cueTypeIsAudio:(NSString *)value];
            isVideo = [[self class] cueTypeIsVideo:(NSString *)value];
            isGroup = [[self class] cueTypeIsGroup:(NSString *)value];
            isCueList = [[self class] cueTypeIsCueList:(NSString *)value];
            isCueCart = [[self class] cueTypeIsCueCart:(NSString *)value];
        }
        
        dispatch_barrier_async( self.dataQueue, ^{
            _icon = icon;
            _isAudio = isAudio;
            _isVideo = isVideo;
            _isGroup = isGroup;
            _isCueList = isCueList;
            _isCueCart = isCueCart;
        });
    }
    
    // send network update
    if ( osc )
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async( dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ( !strongSelf )
                return;
            
            [strongSelf.workspace cue:strongSelf updatePropertySend:value forKey:key];
        });
    }
    
    return YES;
}

- (void) sendAllPropertiesToQLab
{
    NSArray<NSString *> *allPropertyKeys = self.propertyKeys;
    for ( NSString *key in allPropertyKeys )
    {
        id property = [self propertyForKey:key];
        if ( [key isEqualToString:QLKOSCCuesKey] )
        {
            for ( QLKCue *cue in (NSArray<QLKCue *> *)property )
            {
                [cue sendAllPropertiesToQLab];
            }
        }
        else
        {
            [self.workspace cue:self updatePropertySend:property forKey:key];
        }
    }
}

- (void) pullDownPropertyForKey:(NSString *)key block:(nullable QLKMessageHandlerBlock)block
{
    __weak typeof(self) weakSelf = self;
    [self.workspace cue:self
            valueForKey:key
                  block:^(id data) {
                      
                      __strong typeof(weakSelf) strongSelf = weakSelf;
                      if ( !strongSelf )
                          return;
                      
                      [strongSelf setProperty:data
                                       forKey:key
                                     tellQLab:NO];
                      
                      if ( block )
                          block( data );
                      
                  }];
}

- (BOOL) setPlaybackPositionID:(nullable NSString *)cueID tellQLab:(BOOL)osc
{
    return [self setProperty:cueID forKey:QLKOSCPlaybackPositionIdKey tellQLab:osc];
}

#pragma mark - Actions

- (void) start
{
    [self.workspace startCue:self];
}

- (void) stop
{
    [self.workspace stopCue:self];
}

- (void) pause
{
    [self.workspace pauseCue:self];
}

- (void) reset
{
    [self.workspace resetCue:self];
}

- (void) load
{
    [self.workspace loadCue:self];
}

- (void) resume
{
    [self.workspace resumeCue:self];
}

- (void) hardStop
{
    [self.workspace hardStopCue:self];
}

- (void) hardPause
{
    [self.workspace hardPauseCue:self];
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



#pragma mark - deprecated

- (NSString *) iconFile
{
    return [NSString stringWithFormat:@"%@.png", [QLKCue iconForType:self.type]];
}

- (nullable QLKCue *) cueWithId:(NSString *)cueId
{
    return [self cueWithID:cueId];
}

- (void) pushUpProperty:(id)value forKey:(NSString *)key
{
    [self setProperty:value
               forKey:key
             tellQLab:YES];
}

- (void) triggerPushDownPropertyForKey:(NSString *)key
{
    __weak typeof(self) weakSelf = self;
    [self.workspace cue:self
            valueForKey:key
                  block:^(id data) {
                      
                      __strong typeof(weakSelf) strongSelf = weakSelf;
                      if ( !strongSelf )
                          return;
                      
//                      if ( ![data isEqual:[strongSelf propertyForKey:propertyKey]] )
                      
                      [strongSelf pushDownProperty:data
                                            forKey:key];
                      
                  }];
}

- (void) pushDownProperty:(id)value forKey:(NSString *)key
{
    if ( !key ) {
#if DEBUG
        NSLog(@"You can't set property on nil key.");
#endif
        return;
    }
    id old_data = [self propertyForKey:key];
    
    [self setProperty:value
               forKey:key
             tellQLab:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QLKCueHasNewDataNotification"
                                                        object:@{ @"workspaceName" : ( self.workspace.name ? self.workspace.name : [NSNull null] ),
                                                                 @"cueNumber" : ( self.number ? self.number : [NSNull null] ),
                                                                 @"propertyKey" : ( key ? key : [NSNull null] ),
                                                                 @"oldData" : ( old_data ? old_data : [NSNull null] ),
                                                                 @"newData" : ( value ? value : [NSNull null] ) }];
}

@end

NS_ASSUME_NONNULL_END
