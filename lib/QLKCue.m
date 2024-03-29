//
//  QLKCue.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2023 Figure 53 LLC, https://figure53.com
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


#if DEBUG
#define DEBUG_DEALLOC 0
#endif


NS_ASSUME_NONNULL_BEGIN

@interface QLKCue ()
{
#if DEBUG_DEALLOC
    unsigned long _randomIdentifier; //debug
#endif
}

@property (atomic, strong, readwrite, nullable) NSString *iconName;
@property (atomic, getter=isAudio, readwrite) BOOL audio;
@property (atomic, getter=isVideo, readwrite) BOOL video;
@property (atomic, getter=isGroup, readwrite) BOOL group;
@property (atomic, getter=isCueList, readwrite) BOOL cueList;
@property (atomic, getter=isCueCart, readwrite) BOOL cueCart;

@property (nonatomic, weak, readwrite, nullable) QLKWorkspace *workspace;
@property (atomic, readonly) NSMutableDictionary<NSString *, id> *cueData;
@property (atomic, readonly) NSMutableArray<QLKCue *> *childCues;
@property (atomic, readonly) NSMapTable<NSString *, QLKCue *> *childCuesUIDMap;

@property (atomic) BOOL needsSortChildCues;
@property (atomic) BOOL needsNotifyCueUpdated;

@property (atomic, readonly) dispatch_queue_t dataQueue;                // concurrent queue unique to this cue
@property (atomic, weak, readonly) dispatch_queue_t cuePropertiesQueue; // cached pointer to shared workspace serial queue

@end


@implementation QLKCue

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // total possible keys is closer to 65, but 30 allows for most commonly used keys
        // - no need to initially overallocate capacity for rarely-used keys
        _cueData = [NSMutableDictionary dictionaryWithCapacity:30];
        [_cueData setValuesForKeysWithDictionary:@{
            QLKOSCFlaggedKey: @NO,
            QLKOSCArmedKey: @YES,
            QLKOSCPreWaitKey: @0.0,
            QLKOSCPercentPreWaitElapsedKey: @0.0,
            QLKOSCPercentActionElapsedKey: @0.0,
            QLKOSCPostWaitKey: @0.0,
            QLKOSCPercentPostWaitElapsedKey: @0.0,
            QLKOSCIsPanickingKey: @NO,
            QLKOSCIsCrossfadingOutKey: @NO,
            QLKOSCIsAuditioningKey: @NO,
            QLKOSCIsChildAuditioningKey: @NO,
            QLKOSCIsRunningKey: @NO,
            QLKOSCIsTailingOutKey: @NO,
            QLKOSCIsPausedKey: @NO,
            QLKOSCIsBrokenKey: @NO,
            QLKOSCIsOverriddenKey: @NO,
            QLKOSCIsWarningKey: @NO,
            QLKOSCIsLoadedKey: @NO,
            QLKOSCIsChildFlaggedKey: @NO,
            QLKOSCContinueModeKey: @0,
        }];
        _childCues = [NSMutableArray arrayWithCapacity:0];
        _childCuesUIDMap = [NSMapTable weakToWeakObjectsMapTable];

        _dataQueue = dispatch_queue_create("com.figure53.QLabKit.QLKCue.dataQueue", DISPATCH_QUEUE_CONCURRENT);
    }

#if DEBUG_DEALLOC
    _randomIdentifier = arc4random_uniform(999999999); //debug
    NSLog(@"init    %lu", _randomIdentifier);          //debug
#endif

    return self;
}

- (instancetype)initWithWorkspace:(QLKWorkspace *)workspace
{
    self = [self init];
    if (self)
    {
        self.workspace = workspace;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict workspace:(QLKWorkspace *)workspace
{
    self = [self initWithWorkspace:workspace];
    if (self)
    {
        // if this cue has child cues, populate with new cues up-front so that
        // - 1) we can apply the workspace `defaultDeferFetchingPropertiesForNewCues` if any, and
        // - 2) the cue list has at least *some* cue data to display before `updatePropertiesWithDictionary:notify:` goes to background threads
        NSObject<NSCopying> *childCues = dict[QLKOSCCuesKey];
        if ([childCues isKindOfClass:[NSArray class]])
        {
            for (NSDictionary<NSString *, NSObject<NSCopying> *> *aChildDict in ((NSArray *)childCues))
            {
                NSString *uid = (NSString *)aChildDict[QLKOSCUIDKey];
                if (!uid)
                    continue;

                NSMutableDictionary *newChildDict = [NSMutableDictionary dictionaryWithCapacity:8];

                newChildDict[QLKOSCUIDKey] = uid;
                newChildDict[QLKOSCArmedKey] = aChildDict[QLKOSCArmedKey];
                newChildDict[QLKOSCColorNameKey] = aChildDict[QLKOSCColorNameKey];
                newChildDict[QLKOSCLiveColorNameKey] = aChildDict[QLKOSCLiveColorNameKey]; // v5.0+
                newChildDict[QLKOSCFlaggedKey] = aChildDict[QLKOSCFlaggedKey];
                newChildDict[QLKOSCListNameKey] = aChildDict[QLKOSCListNameKey];
                newChildDict[QLKOSCNameKey] = aChildDict[QLKOSCNameKey];
                newChildDict[QLKOSCNumberKey] = aChildDict[QLKOSCNumberKey];
                newChildDict[QLKOSCTypeKey] = aChildDict[QLKOSCTypeKey];
                newChildDict[QLKOSCUIDKey] = aChildDict[QLKOSCUIDKey];

                QLKCue *child = [[[self class] alloc] initWithDictionary:newChildDict
                                                               workspace:workspace];

                if (workspace.defaultDeferFetchingPropertiesForNewCues)
                    [workspace deferFetchingPropertiesForCue:child];

                [self.childCues addObject:child];
                [self.childCuesUIDMap setObject:child forKey:uid];
            }
        }

        [self updatePropertiesWithDictionary:dict notify:NO];
    }
    return self;
}

- (void)dealloc
{
#if DEBUG_DEALLOC
    NSLog(@"dealloc %lu", _randomIdentifier); //debug
#endif
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"(Cue: %p) name: %@ [id:%@ number:%@ type:%@]",
                                      self,
                                      self.name,
                                      self.uid,
                                      self.number,
                                      self.type];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    else if (!object || ![object isKindOfClass:[self class]])
    {
        return NO;
    }
    else
    {
        return [self isEqualToCue:object];
    }
}

- (NSUInteger)hash
{
    return self.uid.hash;
}

- (NSComparisonResult)compare:(QLKCue *)otherCue
{
    // Sort Function
    NSUInteger thisIndex = self.sortIndex;
    NSUInteger otherIndex = otherCue.sortIndex;

    if (thisIndex < otherIndex)
        return NSOrderedAscending;
    else if (thisIndex > otherIndex)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (BOOL)isEqualToCue:(QLKCue *)cue
{
    return (cue.uid && [self.uid isEqualToString:(NSString *_Nonnull)cue.uid]);
}

- (void)setWorkspace:(nullable QLKWorkspace *)workspace
{
    if (_workspace != workspace)
    {
        [self willChangeValueForKey:@"workspace"];

        _workspace = workspace;
        _cuePropertiesQueue = _workspace.cuePropertiesQueue;

        [self didChangeValueForKey:@"workspace"];
    }
}

- (void)addChildCue:(QLKCue *)cue
{
    NSString *uid = cue.uid;
    [self addChildCue:cue withID:uid];
}

- (void)addChildCue:(QLKCue *)cue withID:(NSString *)uid
{
    if (uid.length == 0)
        return;

    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.dataQueue, ^{
        [weakSelf.childCues addObject:cue];
        [weakSelf.childCuesUIDMap setObject:cue forKey:uid];
        [weakSelf.childCues sortUsingSelector:@selector(compare:)];
        weakSelf.needsSortChildCues = NO;
    });
}

- (void)removeChildCue:(QLKCue *)cue
{
    NSString *uid = cue.uid;

    if (uid.length == 0)
        return;

    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.dataQueue, ^{
        [weakSelf.childCues removeObject:cue];
        [weakSelf.childCuesUIDMap removeObjectForKey:uid];
    });
}

- (void)removeAllChildCues
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.dataQueue, ^{
        [weakSelf.childCues removeAllObjects];
        [weakSelf.childCuesUIDMap removeAllObjects];
    });
}

- (void)removeChildCuesWithIDs:(NSArray<NSString *> *)uids
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.dataQueue, ^{
        for (NSString *aUid in uids)
        {
            QLKCue *cue = [weakSelf.childCuesUIDMap objectForKey:aUid];
            if (!cue)
                continue;

            [weakSelf.childCues removeObject:cue];
            [weakSelf.childCuesUIDMap removeObjectForKey:aUid];
        }
    });
}


#pragma mark - Class methods

+ (NSString *)iconForType:(NSString *)type
{
    // Map cue type to icon
    if ([type isEqualToString:QLKCueTypeMIDIFile])
    {
        return @"midi-file";
    }
    else
    {
        return type.lowercaseString;
    }
}

+ (BOOL)cueTypeIsAudio:(NSString *)type
{
    if ([type isEqualToString:QLKCueTypeAudio])
        return YES;

    if ([type isEqualToString:QLKCueTypeMic])
        return YES;

    if ([type isEqualToString:QLKCueTypeVideo])
        return YES;

    return NO;
}

+ (BOOL)cueTypeIsVideo:(NSString *)type
{
    if ([type isEqualToString:QLKCueTypeVideo])
        return YES;

    if ([type isEqualToString:QLKCueTypeCamera])
        return YES;

    if ([type isEqualToString:QLKCueTypeText])
        return YES;

    if ([type isEqualToString:QLKCueTypeTitles])
        return YES;

    return NO;
}

+ (BOOL)cueTypeIsGroup:(NSString *)type
{
    if ([type isEqualToString:QLKCueTypeGroup])
        return YES;

    if ([[self class] cueTypeIsCueList:type])
        return YES;

    if ([[self class] cueTypeIsCueCart:type])
        return YES;

    return NO;
}

+ (BOOL)cueTypeIsCueList:(NSString *)type
{
    if ([type isEqualToString:QLKCueTypeCueList])
        return YES;

    return NO;
}

+ (BOOL)cueTypeIsCueCart:(NSString *)type
{
    if ([type isEqualToString:QLKCueTypeCart])
        return YES;

    return NO;
}

+ (NSArray<NSString *> *)fadeModeTitles
{
    return @[NSLocalizedString(@"Absolute Fade", @"Fade mode type 0 (Absolute)"),
             NSLocalizedString(@"Relative Fade", @"Fade mode type 1 (Relative)")];
}


#pragma mark - KVC-compliance

- (nullable id)valueForUndefinedKey:(NSString *)key
{
    return [self propertyForKey:key];
}

- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key
{
    [self setProperty:value forKey:key tellQLab:NO];
}


#pragma mark - Convenience Accessors

- (NSArray<QLKCue *> *)cues
{
    NSArray *cues = [self propertyForKey:QLKOSCCuesKey];
    if (!cues)
        return @[];

    return cues;
}

- (nullable NSString *)parentID
{
    return [self propertyForKey:QLKOSCParentKey];
}

- (nullable QLKCue *)parent
{
    NSString *parentID = self.parentID;
    if (!parentID)
        return nil;

    return [self.workspace cueWithID:parentID];
}

- (nullable NSString *)playbackPositionID
{
    return [self propertyForKey:QLK_OSC_KEY_PLAYBACK_POSITION_ID];
}

- (nullable NSString *)name
{
    return [self propertyForKey:QLKOSCNameKey];
}

- (nullable NSString *)number
{
    return [self propertyForKey:QLKOSCNumberKey];
}

- (nullable NSString *)uid
{
    return [self propertyForKey:QLKOSCUIDKey];
}

- (nullable NSString *)listName
{
    return [self propertyForKey:QLKOSCListNameKey];
}

- (nullable NSString *)type
{
    return [self propertyForKey:QLKOSCTypeKey];
}

- (nullable NSString *)notes
{
    return [self propertyForKey:QLKOSCNotesKey];
}

- (BOOL)isFlagged
{
    return [[self propertyForKey:QLKOSCFlaggedKey] boolValue];
}

- (BOOL)isPanicking
{
    // NOTE: /isPanicking requires QLab 4.0+
    if (self.workspace.workspaceQLabVersion.majorVersion < 4)
        return NO;

    if ([[self propertyForKey:QLKOSCIsPanickingKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isPanicking)
            return YES;
    }

    return NO;
}

- (BOOL)isCrossfadingOut
{
    // NOTE: /isCrossfadingOut requires QLab 5.0+
    if (self.workspace.workspaceQLabVersion.majorVersion < 5)
        return NO;

    if ([[self propertyForKey:QLKOSCIsCrossfadingOutKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isCrossfadingOut)
            return YES;
    }

    return NO;
}

- (BOOL)isAuditioning
{
    // NOTE: /isAuditioning requires QLab 5.0+
    if (self.workspace.workspaceQLabVersion.majorVersion < 5)
        return NO;

    if ([[self propertyForKey:QLKOSCIsAuditioningKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isAuditioning)
            return YES;
    }

    return NO;
}

- (BOOL)isChildAuditioning
{
    // NOTE: /isChildAuditioning requires QLab 5.0+
    if (self.workspace.workspaceQLabVersion.majorVersion < 5)
        return NO;

    if ([[self propertyForKey:QLKOSCIsChildAuditioningKey] boolValue])
        return YES;

    return NO;
}

- (BOOL)isRunning
{
    if ([[self propertyForKey:QLKOSCIsRunningKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isRunning)
            return YES;
    }

    return NO;
}

- (BOOL)isTailingOut
{
    // NOTE: /isTailingOut requires QLab 4.0+
    if (self.workspace.workspaceQLabVersion.majorVersion < 4)
        return NO;

    if ([[self propertyForKey:QLKOSCIsTailingOutKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isTailingOut)
            return YES;
    }

    return NO;
}

- (BOOL)isPaused
{
    if ([[self propertyForKey:QLKOSCIsPausedKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isPaused)
            return YES;
    }

    return NO;
}

- (BOOL)isBroken
{
    if ([[self propertyForKey:QLKOSCIsBrokenKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isBroken)
            return YES;
    }

    return NO;
}

- (BOOL)isOverridden
{
    // NOTE: /isOverridden requires QLab 4.0+, but update notifications for workspace settings "overrides" requires QLab 4.2+
    if (self.workspace.workspaceQLabVersion.majorVersion < 4 || [self.workspace.workspaceQLabVersion isOlderThanVersion:@"4.2.0"])
        return NO;

    if ([[self propertyForKey:QLKOSCIsOverriddenKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isOverridden)
            return YES;
    }

    return NO;
}

- (BOOL)isWarning
{
    // NOTE: /isWarning requires QLab 5.0+
    if (self.workspace.workspaceQLabVersion.majorVersion < 5)
        return NO;

    if ([[self propertyForKey:QLKOSCIsWarningKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isWarning)
            return YES;
    }

    return NO;
}

- (BOOL)isLoaded
{
    if ([[self propertyForKey:QLKOSCIsLoadedKey] boolValue])
        return YES;

    for (QLKCue *cue in self.cues)
    {
        if (cue.isLoaded)
            return YES;
    }

    return NO;
}

- (BOOL)isChildFlagged
{
    // NOTE: /isChildFlagged requires QLab 5.0+
    if (self.workspace.workspaceQLabVersion.majorVersion < 5)
        return NO;

    if ([[self propertyForKey:QLKOSCIsChildFlaggedKey] boolValue])
        return YES;

    return NO;
}

- (NSString *)displayName
{
    NSString *number = self.number;
    if (number.length > 0)
        return [NSString stringWithFormat:@"%@ \u00B7 %@", number, self.nonEmptyName];
    else
        return self.nonEmptyName;
}

- (NSString *)nonEmptyName
{
    NSString *nonEmptyName; //non-empty name placeholder return value

    if (self.name && ![self.name isEqualToString:@""])
    {
        nonEmptyName = self.name;
    }
    else if (self.listName && ![self.listName isEqualToString:@""])
    {
        nonEmptyName = self.listName;
    }
    else
    {
        nonEmptyName = [NSString stringWithFormat:@"(Untitled %@ Cue)", self.type];
    }

    return nonEmptyName;
}

- (nullable NSString *)workspaceName
{
    return self.workspace.name;
}

- (NSTimeInterval)currentDuration
{
    // return value for v4 key "currentDuration", if it exists
    // else fallback to v3 key for backward compatibility
    if ([self propertyForKey:QLKOSCCurrentDurationKey])
        return [[self propertyForKey:QLKOSCCurrentDurationKey] doubleValue];
    else
        return [[self propertyForKey:QLKOSCDurationKey] doubleValue];
}

- (nullable NSString *)audioFadeModeName
{
    if ([self.type isEqualToString:QLKCueTypeFade])
    {
        QLKCueFadeMode mode = [[self propertyForKey:QLK_OSC_KEY_FADE_LEVELS_MODE] unsignedIntegerValue];
        if (mode <= QLKCueFadeModeRelative)
            return [[self class] fadeModeTitles][mode];
    }

    // else
    return nil;
}

- (nullable NSString *)geoFadeModeName
{
    if ([self.type isEqualToString:QLKCueTypeFade])
    {
        QLKCueFadeMode mode = [[self propertyForKey:@"geoMode"] unsignedIntegerValue];
        if (mode <= QLKCueFadeModeRelative)
            return [[self class] fadeModeTitles][mode];
    }

    // else
    return nil;
}

- (nullable QLKColor *)color
{
    return [self propertyForKey:@"color"];
}

- (nullable QLKColor *)liveColor
{
    return [self propertyForKey:@"color/live"];
}

- (QLKQuaternion)quaternion
{
    QLKQuaternion quaternion = QLKQuaternionIdentity;

    NSArray<NSNumber *> *quaternionComponents = [self propertyForKey:QLKOSCQuaternionKey];
    if (quaternionComponents.count == 4)
    {
        quaternion = QLKQuaternionMake(quaternionComponents[0].floatValue,
                                       quaternionComponents[1].floatValue,
                                       quaternionComponents[2].floatValue,
                                       quaternionComponents[3].floatValue);
    }

    return quaternion;
}

- (void)setQuaternion:(QLKQuaternion)quaternion tellQLab:(BOOL)osc
{
    // store quaternion data the same way QLab provides it - as 4-part array with the x,y,z,w values
    NSArray<NSNumber *> *quaternionComponents = @[@(quaternion.x), @(quaternion.y), @(quaternion.z), @(quaternion.w)];
    [self setProperty:quaternionComponents forKey:QLKOSCQuaternionKey tellQLab:osc];
}

- (CGSize)cueSize
{
    id cueSize = [self propertyForKey:QLKOSCCueSizeKey];
    return CGSizeMake([cueSize[@"width"] doubleValue], [cueSize[@"height"] doubleValue]);
}

- (NSArray<NSString *> *)availableSurfaceNames
{
    if (self.workspace.workspaceQLabVersion.majorVersion >= 5)
        return @[]; // use `availableStageNames` in v5.0+

    NSMutableArray<NSString *> *surfaceNames = [NSMutableArray array];

    // payload of `/cue/{number}/surfaceList` on v3
    // payload of `/video/settings/surfaces` on v4
    NSArray<NSDictionary<NSString *, id> *> *videoOutputsList;
    if (self.workspace.workspaceQLabVersion.majorVersion < 4)
        videoOutputsList = [self propertyForKey:QLKOSCSurfaceListKey];
    else // v4.x
        videoOutputsList = self.workspace.videoOutputsList;

    for (NSDictionary<NSString *, id> *surfaceDict in videoOutputsList)
    {
        NSString *surfaceName = surfaceDict[@"surfaceName"];
        [surfaceNames addObject:surfaceName];
    }

    return [NSArray arrayWithArray:surfaceNames];
}

- (NSArray<NSString *> *)availableStageNames
{
    if (self.workspace.workspaceQLabVersion.majorVersion < 5)
        return @[]; // use `availableSurfaceNames` in v3 and v4

    NSMutableArray<NSString *> *stageNames = [NSMutableArray array];

    // payload of `/video/settings/stages`
    for (NSDictionary<NSString *, id> *stageDict in self.workspace.videoOutputsList)
    {
        NSString *stageName = stageDict[@"name"];
        [stageNames addObject:stageName];
    }

    return [NSArray arrayWithArray:stageNames];
}

- (nullable NSString *)surfaceName
{
    if (self.workspace.workspaceQLabVersion.majorVersion < 4)
    {
        // In QLab v3, /surfaceList is only a VideoCue method.
        // The reply payload is an array of dictionaries, each containing "surfaceName" and "surfaceID" key values.
        NSNumber *surfaceID = [self propertyForKey:QLKOSCSurfaceIDKey];
        if (surfaceID == nil)
            return nil;

        NSArray<NSDictionary<NSString *, id> *> *surfaceList = [self propertyForKey:QLKOSCSurfaceListKey];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary<NSString *, id> *_Nullable evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
            return [evaluatedObject[QLKOSCSurfaceIDKey] isEqual:surfaceID];
        }];

        surfaceList = [surfaceList filteredArrayUsingPredicate:predicate];
        return surfaceList.firstObject[@"surfaceName"];
    }

    // QLab v4 added /settings/video/surfaces, which includes the "surfaceName" key value in the reply payload already centrally stored in (and kept up-to-date by) QLKWorkspace.
    NSNumber *surfaceID = [self propertyForKey:QLKOSCSurfaceIDKey];
    if (surfaceID == nil)
        return nil;

    NSDictionary<NSString *, id> *surfaceDict = [self.workspace surfaceDictForSurfaceID:surfaceID];
    return surfaceDict[@"surfaceName"];
}

- (nullable NSString *)stageName
{
    NSString *stageID = [self propertyForKey:QLKOSCStageIDKey];
    if (!stageID)
        return nil;

    NSDictionary<NSString *, id> *stageDict = [self.workspace stageDictForStageID:stageID];
    return stageDict[@"name"];
}

- (CGSize)surfaceSize
{
    if (self.workspace.workspaceQLabVersion.majorVersion < 4)
    {
        // In QLab v3, /surfaceSize is only a VideoCue method.
        // The reply payload is a dictionary containing "width" and "height" key values.
        NSDictionary<NSString *, NSNumber *> *surfaceSize = [self propertyForKey:QLKOSCSurfaceSizeKey];
        return CGSizeMake(surfaceSize[@"width"].doubleValue, surfaceSize[@"height"].doubleValue);
    }

    // QLab v4 added /settings/video/surfaces, which includes the "width" and "height" key values in the reply payload already centrally stored in (and kept up-to-date by) QLKWorkspace.
    NSNumber *surfaceID = [self propertyForKey:QLKOSCSurfaceIDKey];
    if (surfaceID == nil)
        return CGSizeZero;

    NSDictionary<NSString *, NSNumber *> *surfaceDict = [self.workspace surfaceDictForSurfaceID:surfaceID];
    return CGSizeMake(surfaceDict[@"width"].doubleValue, surfaceDict[@"height"].doubleValue);
}

- (CGSize)stageSize
{
    NSString *stageID = [self propertyForKey:QLKOSCStageIDKey];
    if (!stageID)
        return CGSizeZero;

    NSDictionary<NSString *, id> *stageDict = [self.workspace stageDictForStageID:stageID];
    return CGSizeMake([stageDict[@"width"] doubleValue], [stageDict[@"height"] doubleValue]);
}

- (NSArray<NSString *> *)propertyKeys
{
    __block NSArray *propertyKeys = nil;
    dispatch_sync(self.dataQueue, ^{
        propertyKeys = self.cueData.allKeys;
    });

    if (!propertyKeys)
        propertyKeys = @[];

    return propertyKeys;
}

- (BOOL)hasChildren
{
    return (self.cues.count > 0);
}

- (nullable QLKCue *)firstCue
{
    return self.cues.firstObject;
}

- (nullable QLKCue *)lastCue
{
    return self.cues.lastObject;
}

- (void)setIgnoreUpdates:(BOOL)ignoreUpdates
{
    if (_ignoreUpdates != ignoreUpdates)
    {
        [self willChangeValueForKey:@"ignoreUpdates"];
        _ignoreUpdates = ignoreUpdates;
        [self didChangeValueForKey:@"ignoreUpdates"];

        // if setting to NO, fire another "needs update" notification to allow client to sync local state with QLab
        if (!_ignoreUpdates)
        {
            NSNotification *notification = [NSNotification notificationWithName:QLKCueNeedsUpdateNotification
                                                                         object:self];
            [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                       postingStyle:NSPostWhenIdle
                                                       coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                           forModes:@[NSRunLoopCommonModes]];
        }
    }
}

// mutators

- (void)setCues:(NSArray<QLKCue *> *)cues
{
    [self setProperty:cues
               forKey:QLKOSCCuesKey];
}

- (void)setName:(nullable NSString *)name
{
    [self setProperty:name
               forKey:QLKOSCNameKey];
}

- (void)setNumber:(nullable NSString *)number
{
    [self setProperty:number
               forKey:QLKOSCNumberKey];
}

- (void)setUid:(nullable NSString *)uid
{
    [self setProperty:uid
               forKey:QLKOSCUIDKey];
}

- (void)setListName:(nullable NSString *)listName
{
    [self setProperty:listName
               forKey:QLKOSCListNameKey];
}

- (void)setType:(nullable NSString *)type
{
    [self setProperty:type
               forKey:QLKOSCTypeKey];
}

- (void)setNotes:(nullable NSString *)notes
{
    [self setProperty:notes
               forKey:QLKOSCNotesKey];
}

- (nullable QLKCue *)cueTarget
{
    NSUInteger targetMode = [[self propertyForKey:@"targetMode"] unsignedIntegerValue]; // property added in 5.2, will be nil when connected to 5.1 and earlier
    if (targetMode != QLKCueTargetModeCues)
        return nil;

    NSString *cueTargetID = [self propertyForKey:QLKOSCCurrentCueTargetKey]; // returns cue_id - cueWithID: is faster than searching workspace for a specific cue number
    if (!cueTargetID.length)
        return nil;

    return [self.workspace cueWithID:cueTargetID];
}

- (void)setFlagged:(BOOL)flagged
{
    [self setProperty:@(flagged)
               forKey:QLKOSCFlaggedKey];
}


// Basic properties

- (BOOL)updatePropertiesWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict
{
#if DEBUG
    //NSLog(@"updateProperties: %@", dict);
#endif
    return [self updatePropertiesWithDictionary:dict notify:YES];
}

- (BOOL)updatePropertiesWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict notify:(BOOL)notify
{
#if DEBUG
//    NSLog(@"updateProperties: %@ notify: %@", dict, notify ? @"YES" : @"NO" );
#endif

    // Merge existing properties with new properties dict (conflicts default overwrite)
    // If incoming dictionary is lacking a key that is stored locally, preserve the entry

    BOOL cueUpdated = NO;

    // update values in cue, if needed
    for (NSString *key in dict)
    {
        NSObject<NSCopying> *value = dict[key];

        if ([key isEqualToString:QLKOSCCuesKey])
        {
            if ([value isKindOfClass:[NSArray class]] == NO)
                continue;

            [self updateChildCuesWithPropertiesArray:(NSArray *)value removeUnused:NO];
        }
        else
        {
            BOOL didSetProperty = [self setProperty:value forKey:key tellQLab:NO];
            if (didSetProperty)
                cueUpdated = YES;
        }
    }

    if (!cueUpdated)
        return NO;

    if (notify)
        [self enqueueCueUpdatedNotification];

    return YES;
}

- (void)enqueueCueUpdatedNotification
{
    __weak typeof(self) weakSelf = self;
    dispatch_block_t block = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        // reset internal flag
        strongSelf.needsNotifyCueUpdated = NO;

        NSNotification *notification = [NSNotification notificationWithName:QLKCueUpdatedNotification object:strongSelf userInfo:nil];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                   postingStyle:NSPostASAP
                                                   coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                       forModes:@[NSRunLoopCommonModes]];
    };

    if ([NSThread currentThread].isMainThread)
        block();
    else
        dispatch_async(dispatch_get_main_queue(), block);
}

- (void)updateChildCuesWithPropertiesArray:(NSArray<NSDictionary *> *)data removeUnused:(BOOL)removeUnused
{
    // `data` contains an array of dictionary items, one item per cue in the group cue, meaning it can have 100s of entries, esp. when the group cue is a cue list of a large workspace
    // - so we process child cue updates on a separate queue to avoid blocking the main thread
    // because all of this processing happens in the background, it's not possible to return a BOOL from this update method like we do in `updatePropertiesWithDictionary:notify:`
    // - instead, we track whether any child cues were updated and whether the sort order of child cues needs updating. After scheduling all update blocks on cuePropertiesQueue, we then do a final update on the same serial queue checking the `needsSortChildCues` and `needsNotifyCueUpdated` flags.

    if (!self.workspace.connected)
        return;

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.cuePropertiesQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        NSMutableArray<NSString *> *previousUids = nil;
        if (removeUnused)
            previousUids = [NSMutableArray arrayWithArray:[strongSelf allChildCueUids]];

        NSUInteger index = 0;
        for (NSDictionary<NSString *, NSObject<NSCopying> *> *dict in data)
        {
            NSString *uid = (NSString *)dict[QLKOSCUIDKey];
            if (!uid)
                continue;

            if (removeUnused)
                [previousUids removeObject:uid];

            // if we have a child matching this UID, then update; otherwise, insert.
            // if the cue is no longer there, then it is lost locally too.
            QLKCue *child = [strongSelf cueWithID:uid includeChildren:NO];
            if (child)
            {
                BOOL didUpdateProperties = [child updatePropertiesWithDictionary:dict];
                if (didUpdateProperties)
                    strongSelf.needsNotifyCueUpdated = YES;

                // mark for a re-sort if the order of this cue within the parent group has changed
                if (child.sortIndex != index)
                {
                    child.sortIndex = index;

                    strongSelf.needsSortChildCues = YES;
                    strongSelf.needsNotifyCueUpdated = YES;
                }
            }
            else
            {
                child = [[[self class] alloc] initWithDictionary:dict workspace:strongSelf.workspace];
                child.sortIndex = index;
                [strongSelf addChildCue:child withID:uid]; // NOTE: resets needsSortChildCues to NO

                if (strongSelf.workspace.defaultDeferFetchingPropertiesForNewCues)
                    [strongSelf.workspace deferFetchingPropertiesForCue:child];

                strongSelf.needsNotifyCueUpdated = YES;

                // NOTE: we serialize the enqueing of these "needs update" notifications to ensure they not posted until after we finish processing this dictionary.
                // - this way, we do not have to deal with the followup responses the notifications might trigger until after we have finished adding all of these new child cues first.
                dispatch_async(strongSelf.cuePropertiesQueue, ^{
                    // NSNotifications should be sent on the main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSNotification *notification = [NSNotification notificationWithName:QLKCueNeedsUpdateNotification
                                                                                     object:child];
                        [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                                   postingStyle:NSPostASAP
                                                                   coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                                       forModes:@[NSRunLoopCommonModes]];
                    });
                });
            }

            index++;
        }

        if (previousUids.count)
        {
            [strongSelf removeChildCuesWithIDs:previousUids];
            [strongSelf enqueueCueUpdatedNotification];
        }

        if (strongSelf.needsSortChildCues)
        {
            dispatch_barrier_async(strongSelf.dataQueue, ^{
                [weakSelf.childCues sortUsingSelector:@selector(compare:)];
                weakSelf.needsSortChildCues = NO;

                [weakSelf enqueueCueUpdatedNotification];
            });
        }

        if (strongSelf.needsNotifyCueUpdated)
            [strongSelf enqueueCueUpdatedNotification];
    });
}


#pragma mark - Children cues

- (NSArray<NSString *> *)allChildCueUids
{
    __block NSArray *allChildCueUids = nil;
    dispatch_sync(self.dataQueue, ^{
        allChildCueUids = self.childCuesUIDMap.keyEnumerator.allObjects;
    });

    if (!allChildCueUids)
        allChildCueUids = @[];

    return allChildCueUids;
}

- (nullable QLKCue *)cueAtIndex:(NSInteger)index
{
    NSArray *cues = self.cues;
    if (index < 0 || (NSUInteger)index >= cues.count)
        return nil;

    return cues[index];
}

// Recursively search for a cue with a matching id
- (nullable QLKCue *)cueWithID:(NSString *)uid
{
    return [self cueWithID:uid includeChildren:YES];
}

- (nullable QLKCue *)cueWithID:(NSString *)uid includeChildren:(BOOL)includeChildren
{
    __block QLKCue *cue = nil;
    dispatch_sync(self.dataQueue, ^{
        cue = [self.childCuesUIDMap objectForKey:uid];
    });

    if (cue)
        return cue;

    if (!includeChildren)
        return nil;

    NSArray<QLKCue *> *cues = self.cues;
    for (QLKCue *aCue in cues)
    {
        if (!aCue.isGroup)
            continue;

        QLKCue *childCue = [aCue cueWithID:uid includeChildren:includeChildren];
        if (childCue)
            return childCue;
    }

    // all else
    return nil;
}

- (nullable QLKCue *)cueWithNumber:(NSString *)number
{
    NSArray<QLKCue *> *cues = self.cues;
    for (QLKCue *cue in cues)
    {
        if ([cue.number isEqualToString:number])
            return cue;

        if (cue.isGroup)
        {
            QLKCue *childCue = [cue cueWithNumber:number];
            if (childCue)
                return childCue;
        }
    }

    // all else
    return nil;
}

- (nullable id)propertyForKey:(NSString *)key
{
    // retrieve the value
    if ([key isEqualToString:QLKOSCCuesKey])
    {
        __block NSArray *cues = nil;
        dispatch_sync(self.dataQueue, ^{
            cues = [self.childCues copy];
        });
        return cues;
    }
    else if ([key isEqualToString:@"color"])
    {
        __block NSString *colorName = nil;
        dispatch_sync(self.dataQueue, ^{
            colorName = self.cueData[QLKOSCColorNameKey];
        });
        if (!colorName)
            return nil;

        return [QLKColor colorWithName:colorName];
    }
    else if ([key isEqualToString:@"color/live"])
    {
        __block NSString *colorName = nil;
        dispatch_sync(self.dataQueue, ^{
            colorName = self.cueData[QLKOSCLiveColorNameKey];
        });
        if (!colorName)
            return nil;

        return [QLKColor colorWithName:colorName];
    }
    else
    {
        __block id property = nil;
        dispatch_sync(self.dataQueue, ^{
            property = self.cueData[key];
        });
        return property;
    }
}

- (BOOL)setProperty:(nullable id)value forKey:(NSString *)key
{
    return [self setProperty:value
                      forKey:key
                    tellQLab:self.workspace.defaultSendUpdatesOSC];
}

- (BOOL)setProperty:(nullable id)value forKey:(NSString *)key tellQLab:(BOOL)osc
{
    // exit if the value is unchanged
    __block id existingValue = nil;
    dispatch_sync(self.dataQueue, ^{
        existingValue = self.cueData[key];
    });
    if (existingValue == value)
        return NO;
    if ([existingValue isEqual:value])
        return NO;


    // NOTE: special case when connected to QLab 3:
    // - cue list cues in v4 have type "Cue List", but in v3 they are type "Group"
    // - for compatibility when connected to a v3 workspace, QLKWorkspace manually sets the QLKCue type for cue list cues to "Cue List" when adding new cue lists
    // - so here, we also then prevent the incoming v3 cue type value from overwriting our local QLKCue type when it is already "Cue List", i.e. in the course of processing any normal cue updated message for a cue list cue
    if (self.workspace.connectedToQLab3 &&
        [key isEqualToString:QLKOSCTypeKey] &&
        [existingValue isEqualToString:QLKCueTypeCueList] &&
        [value isEqualToString:QLKCueTypeGroup])
    {
        return NO;
    }


    // update with new value
    if ([key isEqualToString:QLKOSCCuesKey])
    {
        if ([value isKindOfClass:[NSArray class]] == NO)
            return NO;

        NSMapTable *newChildCuesUIDMap = [NSMapTable weakToWeakObjectsMapTable];

        NSUInteger index = 0;
        NSString *uid = nil;
        for (QLKCue *aCue in (NSArray *)value)
        {
            uid = aCue.uid;
            if (!uid)
                continue;

            aCue.sortIndex = index;
            [newChildCuesUIDMap setObject:aCue forKey:(NSString *_Nonnull)uid];

            index++;
        }

        __weak typeof(self) weakSelf = self;
        BOOL isMainThread = [NSThread currentThread].isMainThread;
        if (isMainThread)
            [self willChangeValueForKey:key];
        else
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf willChangeValueForKey:key];
            });

        // NOTE: using sync here guarantees the value is updated before didChangeValueForKey: is called
        // - dispatch(_*)_sync() also does not copy or retain the block so no weakSelf is needed
        dispatch_barrier_sync(self.dataQueue, ^{
            self->_childCues = [(NSArray *)value mutableCopy];
            self->_childCuesUIDMap = newChildCuesUIDMap;
        });

        if (isMainThread)
            [self didChangeValueForKey:key];
        else
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf didChangeValueForKey:key];
            });
    }
    else if ([key isEqualToString:QLKOSCPlaybackPositionIDKey] ||
             [key isEqualToString:QLKOSCV4PlaybackPositionIdKey])
    {
        if (!self.isCueList)
            return NO;

        if (value && [value isKindOfClass:[NSString class]] == NO)
            return NO;

        // set to nil if QLab returns "none"
        if ([(NSString *)value isEqualToString:@"none"])
            value = nil;


        __weak typeof(self) weakSelf = self;
        BOOL isMainThread = [NSThread currentThread].isMainThread;
        if (isMainThread)
            [self willChangeValueForKey:key];
        else
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf willChangeValueForKey:key];
            });

        // NOTE: using sync here guarantees the value is updated before didChangeValueForKey: is called
        // - dispatch(_*)_sync() also does not copy or retain the block so no weakSelf is needed
        dispatch_barrier_sync(self.dataQueue, ^{
            if (value)
                self.cueData[key] = value;
            else
                [self.cueData removeObjectForKey:key];
        });

        dispatch_block_t didChangeBlock = ^{
            [weakSelf didChangeValueForKey:key];

            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf)
                return;

            NSDictionary *userInfo = nil;
            if (existingValue && value)
                userInfo = @{NSKeyValueChangeOldKey: existingValue, NSKeyValueChangeNewKey: value}; // changing
            else if (existingValue)
                userInfo = @{NSKeyValueChangeOldKey: existingValue}; // unsetting
            else if (value)
                userInfo = @{NSKeyValueChangeNewKey: value}; // setting for first time

            NSNotification *notification = [NSNotification notificationWithName:QLKCueListDidChangePlaybackPositionIDNotification object:strongSelf userInfo:userInfo];
            [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                       postingStyle:NSPostASAP
                                                       coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                           forModes:@[NSRunLoopCommonModes]];
        };

        if (isMainThread)
            didChangeBlock();
        else
            dispatch_async(dispatch_get_main_queue(), didChangeBlock);
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        BOOL isMainThread = [NSThread currentThread].isMainThread;
        if (isMainThread)
            [self willChangeValueForKey:key];
        else
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf willChangeValueForKey:key];
            });

        // NOTE: using sync here guarantees the value is updated before didChangeValueForKey: is called
        // - dispatch(_*)_sync() also does not copy or retain the block so no weakSelf is needed
        dispatch_barrier_sync(self.dataQueue, ^{
            if (value)
                self.cueData[key] = value;
            else
                [self.cueData removeObjectForKey:key];
        });

        if (isMainThread)
            [self didChangeValueForKey:key];
        else
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf didChangeValueForKey:key];
            });
    }

    // update cached properties
    if ([key isEqualToString:QLKOSCTypeKey])
    {
        NSString *iconName = nil;
        BOOL isAudio = NO;
        BOOL isVideo = NO;
        BOOL isGroup = NO;
        BOOL isCueList = NO;
        BOOL isCueCart = NO;

        if (value)
        {
            iconName = [[self class] iconForType:(NSString *)value];
            isAudio = [[self class] cueTypeIsAudio:(NSString *)value];
            isVideo = [[self class] cueTypeIsVideo:(NSString *)value];
            isGroup = [[self class] cueTypeIsGroup:(NSString *)value];
            isCueList = [[self class] cueTypeIsCueList:(NSString *)value];
            isCueCart = [[self class] cueTypeIsCueCart:(NSString *)value];
        }

        // NOTE: we don't need to synchronize using the dataQueue to set values here
        // - we get thread-safety on these simple data types by using atomic operations for these properties
        self.iconName = iconName;
        self.audio = isAudio;
        self.video = isVideo;
        self.group = isGroup;
        self.cueList = isCueList;
        self.cueCart = isCueCart;
    }

    // send network update
    if (osc)
    {
        // if playbackPositionID value is nil, transmit "none" to QLab to unset playhead - NOTE: requires QLab 4.2 or later
        if (!value && [key isEqualToString:QLK_OSC_KEY_PLAYBACK_POSITION_ID] && [self.workspace.workspaceQLabVersion isOlderThanVersion:@"4.2.0"] == NO)
            value = @"none";

        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf)
                return;

            [strongSelf.workspace cue:strongSelf updatePropertySend:value forKey:key];
        });
    }

    return YES;
}

- (void)sendAllPropertiesToQLab
{
    NSArray<NSString *> *allPropertyKeys = self.propertyKeys;
    for (NSString *key in allPropertyKeys)
    {
        id property = [self propertyForKey:key];
        if ([key isEqualToString:QLKOSCCuesKey])
        {
            for (QLKCue *cue in (NSArray<QLKCue *> *)property)
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

- (void)pullDownPropertyForKey:(NSString *)key block:(nullable QLKMessageReplyBlock)block
{
    __weak typeof(self) weakSelf = self;
    [self.workspace cue:self
            valueForKey:key
                  block:^(NSString *status, id _Nullable data) {
                      __strong typeof(weakSelf) strongSelf = weakSelf;
                      if (!strongSelf)
                          return;

                      [strongSelf setProperty:data
                                       forKey:key
                                     tellQLab:NO];

                      if (block)
                          block(status, data);
                  }];
}

- (BOOL)setPlaybackPositionID:(nullable NSString *)cueID tellQLab:(BOOL)osc
{
    return [self setProperty:cueID forKey:QLK_OSC_KEY_PLAYBACK_POSITION_ID tellQLab:osc];
}

#pragma mark - Actions

- (void)start
{
    [self.workspace startCue:self];
}

- (void)stop
{
    [self.workspace stopCue:self];
}

- (void)pause
{
    [self.workspace pauseCue:self];
}

- (void)reset
{
    [self.workspace resetCue:self];
}

- (void)load
{
    [self.workspace loadCue:self];
}

- (void)resume
{
    [self.workspace resumeCue:self];
}

- (void)hardStop
{
    [self.workspace hardStopCue:self];
}

- (void)hardPause
{
    [self.workspace hardPauseCue:self];
}

- (void)togglePause
{
    [self.workspace togglePauseCue:self];
}

- (void)preview
{
    [self.workspace previewCue:self];
}

- (void)auditionPreview
{
    [self.workspace auditionPreviewCue:self];
}

- (void)panic
{
    [self.workspace panicCue:self];
}

@end

NS_ASSUME_NONNULL_END
