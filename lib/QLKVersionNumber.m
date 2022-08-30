//
//  QLKVersionNumber.m
//  QLabKit
//
//  Created by Brent Lord on 6/1/14.
//  Copyright (c) 2014-2019 Figure 53 LLC, https://figure53.com
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

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "QLKVersionNumber.h"


NS_ASSUME_NONNULL_BEGIN

@implementation QLKVersionNumber

+ (instancetype)versionWithString:(NSString *)versionString
{
    return [[[self class] alloc] initWithString:versionString];
}

- (instancetype)init
{
    return [self initWithMajorVersion:0 minor:0 patch:0 build:nil];
}

- (instancetype)initWithString:(NSString *)versionString
{
    NSUInteger major = 0;
    NSUInteger minor = 0;
    NSUInteger patch = 0;
    NSString *build = nil;

    // parse the string into components
    NSArray<NSString *> *buildComponents = [versionString componentsSeparatedByString:@" "];
    if (buildComponents.count > 1)
    {
        build = [buildComponents.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];

        versionString = [versionString stringByReplacingOccurrencesOfString:(NSString *_Nonnull)buildComponents.lastObject
                                                                 withString:@""
                                                                    options:(NSBackwardsSearch | NSAnchoredSearch)
                                                                      range:NSMakeRange(0, versionString.length)];
        versionString = [versionString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }

    NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];
    for (NSUInteger i = 0; i < versionComponents.count; i++)
    {
        if (i == 0)
            major = (versionComponents[i].integerValue > 0 ? (NSUInteger)versionComponents[i].integerValue : 0);

        else if (i == 1)
            minor = (versionComponents[i].integerValue > 0 ? (NSUInteger)versionComponents[i].integerValue : 0);

        else if (i == 2)
            patch = (versionComponents[i].integerValue > 0 ? (NSUInteger)versionComponents[i].integerValue : 0);

        else if (i == 3)
            build = [versionComponents[i] stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];

        else
            break;
    }

    return [self initWithMajorVersion:major minor:minor patch:patch build:build];
}

- (instancetype)initWithMajorVersion:(NSUInteger)major minor:(NSUInteger)minor patch:(NSUInteger)patch
{
    return [self initWithMajorVersion:major minor:minor patch:patch build:nil];
}

- (instancetype)initWithMajorVersion:(NSUInteger)major minor:(NSUInteger)minor patch:(NSUInteger)patch build:(nullable NSString *)build
{
    self = [super init];
    if (self)
    {
        _majorVersion = major;
        _minorVersion = minor;
        _patchVersion = patch;
        _build = build;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[QLKVersionNumber class]] == NO)
        return NO;

    if (((QLKVersionNumber *)object).majorVersion != self.majorVersion)
        return NO;

    if (((QLKVersionNumber *)object).minorVersion != self.minorVersion)
        return NO;

    if (((QLKVersionNumber *)object).patchVersion != self.patchVersion)
        return NO;

    if ((((QLKVersionNumber *)object).build && !self.build) ||
        (!((QLKVersionNumber *)object).build && self.build) ||
        (((QLKVersionNumber *)object).build && self.build && [((QLKVersionNumber *)object).build isEqualToString:(NSString *_Nonnull)self.build] == NO))
        return NO;

    return YES;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ \"%@\"", super.debugDescription, [self stringValue]];
}

- (NSString *)description
{
    return [self stringValue];
}

- (NSComparisonResult)compare:(QLKVersionNumber *)otherVersion
{
    return [self compare:otherVersion ignoreBuild:NO];
}

- (NSComparisonResult)compare:(QLKVersionNumber *)otherVersion ignoreBuild:(BOOL)ignoreBuild
{
    // test major versions
    if (self.majorVersion < otherVersion.majorVersion)
        return NSOrderedAscending;

    if (self.majorVersion > otherVersion.majorVersion)
        return NSOrderedDescending;

    // major versions are equal

    // test minor versions
    if (self.minorVersion < otherVersion.minorVersion)
        return NSOrderedAscending;

    if (self.minorVersion > otherVersion.minorVersion)
        return NSOrderedDescending;

    // minor versions are equal

    // test patch versions
    if (self.patchVersion < otherVersion.patchVersion)
        return NSOrderedAscending;

    if (self.patchVersion > otherVersion.patchVersion)
        return NSOrderedDescending;

    // patch versions are equal

    // test build number, if requested
    if (!ignoreBuild)
    {
        if (!self.build && !otherVersion.build)
            return NSOrderedSame;

        if (self.build && !otherVersion.build)
            return NSOrderedAscending;

        if (!self.build && otherVersion.build)
            return NSOrderedDescending;

        return [self.build compare:(NSString *_Nonnull)otherVersion.build];
    }

    return NSOrderedSame;
}

- (BOOL)isOlderThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compare:[[self class] versionWithString:version]];
    return (result == NSOrderedAscending);
}

- (BOOL)isEqualToVersion:(NSString *)version
{
    NSComparisonResult result = [self compare:[[self class] versionWithString:version]];
    return (result == NSOrderedSame);
}

- (BOOL)isNewerThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compare:[[self class] versionWithString:version]];
    return (result == NSOrderedDescending);
}

- (NSString *)stringValue
{
    if (_build)
    {
        NSString *versionString = [NSString stringWithFormat:@"%ld.%ld.%ld (%@)",
                                                             (long)self.majorVersion,
                                                             (long)self.minorVersion,
                                                             (long)self.patchVersion,
                                                             self.build];
        return versionString;
    }
    else
    {
        NSString *versionString = [NSString stringWithFormat:@"%ld.%ld.%ld",
                                                             (long)self.majorVersion,
                                                             (long)self.minorVersion,
                                                             (long)self.patchVersion];
        return versionString;
    }
}

@end


@implementation NSString (QLKVersionNumber)

- (NSComparisonResult)compareVersion:(NSString *)version ignoreBuild:(BOOL)ignoreBuild
{
    QLKVersionNumber *appVersion = [[QLKVersionNumber alloc] initWithString:self];
    QLKVersionNumber *thisVersion = [[QLKVersionNumber alloc] initWithString:version];

    return [appVersion compare:thisVersion ignoreBuild:ignoreBuild];
}

- (BOOL)isOlderThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compareVersion:version ignoreBuild:NO];
    return (result == NSOrderedAscending);
}

- (BOOL)isEqualToOrOlderThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compareVersion:version ignoreBuild:NO];
    return (result == NSOrderedSame || result == NSOrderedAscending);
}

- (BOOL)isEqualToVersion:(NSString *)version
{
    NSComparisonResult result = [self compareVersion:version ignoreBuild:NO];
    return (result == NSOrderedSame);
}

- (BOOL)isEqualToOrNewerThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compareVersion:version ignoreBuild:NO];
    return (result == NSOrderedSame || result == NSOrderedDescending);
}
- (BOOL)isNewerThanVersion:(NSString *)version
{
    NSComparisonResult result = [self compareVersion:version ignoreBuild:NO];
    return (result == NSOrderedDescending);
}

@end

NS_ASSUME_NONNULL_END
