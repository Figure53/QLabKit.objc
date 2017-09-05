//
//  QLKColor.m
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

#import "QLKColor.h"


static NSSet *_colors = nil;


NS_ASSUME_NONNULL_BEGIN

@implementation QLKColor

+ (void) initialize
{
    _colors = [NSSet setWithObjects:@"red", @"orange", @"blue", @"lightblue", @"yellow", @"green", @"purple", nil];
}

- (nullable instancetype) initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if ( self )
    {
        _name = [decoder decodeObjectForKey:QLKOSCNameKey];
        _color = [decoder decodeObjectForKey:@"color"];
        _darkColor = [decoder decodeObjectForKey:@"darkColor"];
        
        // compatibility with QLabKit.objc 0.0.2
        if ( [decoder containsValueForKey:@"startColor"] )
        {
            _color = [decoder decodeObjectForKey:@"startColor"];
        }
        if ( [decoder containsValueForKey:@"endColor"] )
        {
            _darkColor = [decoder decodeObjectForKey:@"endColor"];
        }
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    if ( coder.allowsKeyedCoding )
    {
        [coder encodeObject:_name forKey:QLKOSCNameKey];
        [coder encodeObject:_color forKey:@"color"];
        [coder encodeObject:_darkColor forKey:@"darkColor"];
    }
}

- (BOOL) isEqualToColor:(QLKColor *)color
{
    // Simplified comparison since we know the colors are limited
    return ( [self.name isEqualToString:color.name] );
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"QLKColor: %@", self.name];
}

- (nullable QLKColorClass *) startColor
{
    return _color;
}

- (nullable QLKColorClass *) endColor
{
    return _darkColor;
}



#pragma mark - Convenience class methods for predefined colors

+ (NSSet *) colors
{
    return _colors;
}

+ (QLKColor *) defaultColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"default";
#if TARGET_OS_IPHONE
    color.color = [UIColor colorWithRed:0.63f green:0.61f blue:0.66f alpha:1.0f];
    color.darkColor = [UIColor colorWithWhite:0.37f alpha:1.0f];
#else
    color.color = [NSColor colorWithCalibratedHue:0.71 saturation:0.1 brightness:0.61 alpha:1];
    color.darkColor = [NSColor colorWithCalibratedHue:0.71 saturation:.12 brightness:0.53 alpha:1];
#endif
    return color;
}

+ (QLKColor *) redColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"red";
#if TARGET_OS_IPHONE
    color.color = [UIColor colorWithRed:1.0f green:0.31f blue:0.28f alpha:1.0f];
    color.darkColor = [UIColor colorWithRed:0.92f green:0.2f blue:0.16f alpha:1.0f];
#else
    color.color = [NSColor colorWithCalibratedHue:0.02 saturation:0.89 brightness:1 alpha:1];
    color.darkColor = [NSColor colorWithCalibratedHue:0.02 saturation:1 brightness:0.83 alpha:1];
#endif
    return color;
}

+ (QLKColor *) orangeColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"orange";
#if TARGET_OS_IPHONE
    color.color = [UIColor colorWithRed:1.0f green:0.64f blue:0.15f alpha:1.0f];
    color.darkColor = [UIColor colorWithRed:1.0f green:0.5f blue:0.13f alpha:1.0f];
#else
    color.color = [NSColor colorWithCalibratedHue:0.1 saturation:1 brightness:1 alpha:1];
    color.darkColor = [NSColor colorWithCalibratedHue:0.08 saturation:1 brightness:0.93 alpha:1];
#endif
    return color;
}

+ (QLKColor *) yellowColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"yellow";
#if TARGET_OS_IPHONE
    color.color = [UIColor colorWithHue:55.0/360.0 saturation:1 brightness:1 alpha:1];
    color.darkColor = [UIColor colorWithHue:55.0/360.0 saturation:1 brightness:0.98 alpha:1];
#else
    color.color = [NSColor colorWithCalibratedHue:0.15 saturation:1 brightness:1 alpha:1];
    color.darkColor = [NSColor colorWithCalibratedHue:0.15 saturation:1 brightness:0.98 alpha:1];
#endif
    return color;
}

+ (QLKColor *) greenColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"green";
#if TARGET_OS_IPHONE
    color.color = [UIColor colorWithRed:0.0f green:0.81f blue:0.23f alpha:1.0f];
    color.darkColor = [UIColor colorWithRed:0.0f green:0.73f blue:0.12f alpha:1.0f];
#else
    color.color = [NSColor colorWithCalibratedHue:0.32 saturation:0.84 brightness:0.78 alpha:1];
    color.darkColor = [NSColor colorWithCalibratedHue:0.25 saturation:1 brightness:0.59 alpha:1];
#endif
    return color;
}

+ (QLKColor *) blueColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"blue";
#if TARGET_OS_IPHONE
    color.color = [UIColor colorWithRed:0.33f green:0.46f blue:0.87f alpha:1.0f];
    color.darkColor = [UIColor colorWithRed:0.22f green:0.38f blue:0.83f alpha:1.0f];
#else
    color.color = [NSColor colorWithCalibratedHue:0.62 saturation:0.72 brightness:0.9 alpha:1];
    color.darkColor = [NSColor colorWithCalibratedHue:0.62 saturation:0.9 brightness:0.79 alpha:1];
#endif
    return color;
}

+ (QLKColor *) purpleColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"purple";
#if TARGET_OS_IPHONE
    color.color = [UIColor colorWithRed:0.65f green:0.2f blue:0.74f alpha:1.0f];
    color.darkColor = [UIColor colorWithRed:0.53f green:0.17f blue:0.65f alpha:1.0f];
#else
    color.color = [NSColor colorWithCalibratedHue:0.83 saturation:0.46 brightness:0.71 alpha:1];
    color.darkColor = [NSColor colorWithCalibratedHue:0.82 saturation:0.58 brightness:0.56 alpha:1];
#endif
    return color;
}

+ (nullable QLKColor *) colorWithName:(NSString *)name
{
    QLKColor *color = nil;
    
    if ( [_colors containsObject:name.lowercaseString] )
    {
        color = [QLKColor performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@Color", name.lowercaseString])];
    }
    
    return color;
}



#pragma mark - Deprecated

+ (QLKColor *) lightblueColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"lightblue";
    color.color = [self.class colorWithRed:0.710 green:0.835 blue:0.914 alpha:1.000];
    color.darkColor = [self.class colorWithRed:0.541 green:0.667 blue:0.745 alpha:1.000];
    
    return color;
}

+ (QLKColorClass *) panelColor
{
    return [self.class colorWithRed:0.282 green:0.282 blue:0.282 alpha:1];
}

+ (QLKColorClass *) navBarColor
{
    return [self.class colorWithRed:0.150 green:0.150 blue:0.150 alpha:1];
}

+ (QLKColorClass *) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
#if TARGET_OS_IPHONE
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
#else
    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
#endif
}

+ (QLKColorClass *) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
#if TARGET_OS_IPHONE
    return [UIColor colorWithWhite:white alpha:alpha];
#else
    return [NSColor colorWithCalibratedWhite:white alpha:alpha];
#endif
}

@end

NS_ASSUME_NONNULL_END
