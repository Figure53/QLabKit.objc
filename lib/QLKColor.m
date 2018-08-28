//
//  QLKColor.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2018 Figure 53 LLC, http://figure53.com
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

#define DEFAULT_NAME    @"- unknown -"

@implementation QLKColor

+ (void) initialize
{
    _colors = [NSSet setWithObjects:@"red", @"orange", @"blue", @"lightblue", @"yellow", @"green", @"purple", nil];
}

- (instancetype) init
{
    self = [super init];
    if ( self )
    {
        _name = DEFAULT_NAME;
    }
    return self;
}

- (nullable instancetype) initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if ( self )
    {
        id name = [decoder decodeObjectForKey:QLKOSCNameKey];
        if ( !name || [name isKindOfClass:[NSString class]] == NO )
            return nil;
        
        _name = (NSString * _Nonnull)name;
        _color = [decoder decodeObjectForKey:@"color"];
        _lightColor = [decoder decodeObjectForKey:@"lightColor"];
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
        [coder encodeObject:_lightColor forKey:@"lightColor"];
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

- (void) setName:(NSString *)name
{
    if ( [name isEqualToString:DEFAULT_NAME] )
        return;
    
    if ( _name != name )
    {
        [self willChangeValueForKey:@"name"];
        _name = name;
        [self didChangeValueForKey:@"name"];
    }
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
    color.lightColor    = [QLKColorClass colorWithHue:0.722 saturation:0.05 brightness:0.7 alpha:1];    // #ACAAB2
    color.color         = [QLKColorClass colorWithHue:0.722 saturation:0.1 brightness:0.6 alpha:1];     // #8F8A99
    color.darkColor     = [QLKColorClass colorWithHue:0.722 saturation:0.1 brightness:0.5 alpha:1];     // #77737F
    return color;
}

+ (QLKColor *) redColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"red";
    color.lightColor    = [QLKColorClass colorWithHue:0.028 saturation:0.8 brightness:1 alpha:1];       // #FC563C
    color.color         = [QLKColorClass colorWithHue:0.0 saturation:0.8 brightness:1 alpha:1];         // #FC363B
    color.darkColor     = [QLKColorClass colorWithHue:0.0 saturation:0.9 brightness:0.9 alpha:1];       // #E31C24
    return color;
}

+ (QLKColor *) orangeColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"orange";
    color.lightColor    = [QLKColorClass colorWithHue:0.11 saturation:1 brightness:1 alpha:1];          // #FFAA00
    color.color         = [QLKColorClass colorWithHue:0.097 saturation:1 brightness:1 alpha:1];         // #FF9500
    color.darkColor     = [QLKColorClass colorWithHue:0.07 saturation:1 brightness:1 alpha:1];          // #FF6A00
    return color;
}

+ (QLKColor *) yellowColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"yellow";
    color.lightColor    = [QLKColorClass colorWithHue:0.153 saturation:0.5 brightness:1 alpha:1];       // #FFF480
    color.color         = [QLKColorClass colorWithHue:0.153 saturation:0.9 brightness:0.97 alpha:1];    // #F7E519
    color.darkColor     = [QLKColorClass colorWithHue:0.139 saturation:1 brightness:1 alpha:1];         // #FFD500
    return color;
}

+ (QLKColor *) greenColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"green";
    color.lightColor    = [QLKColorClass colorWithHue:0.362 saturation:0.9 brightness:0.9 alpha:1];     // #17E639
    color.color         = [QLKColorClass colorWithHue:0.362 saturation:1 brightness:0.8 alpha:1];       // #00CC22
    color.darkColor     = [QLKColorClass colorWithHue:0.334 saturation:1 brightness:0.7 alpha:1];       // #00B300
    return color;
}

+ (QLKColor *) blueColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"blue";
    color.lightColor    = [QLKColorClass colorWithHue:0.639 saturation:0.6 brightness:0.9 alpha:1];     // #5C73E6
    color.color         = [QLKColorClass colorWithHue:0.639 saturation:0.7 brightness:0.85 alpha:1];    // #415AD9
    color.darkColor     = [QLKColorClass colorWithHue:0.639 saturation:0.8 brightness:0.8 alpha:1];     // #2944CC
    return color;
}

+ (QLKColor *) indigoColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"purple";
    color.lightColor    = [QLKColorClass colorWithHue:0.666 saturation:0.45 brightness:0.7 alpha:1];    // #3F388C
    color.color         = [QLKColorClass colorWithHue:0.681 saturation:0.45 brightness:0.6 alpha:1];    // #5A5499
    color.darkColor     = [QLKColorClass colorWithHue:0.681 saturation:0.6 brightness:0.55 alpha:1];    // #6262B3
    return color;
}

+ (QLKColor *) purpleColor
{
    QLKColor *color = [[QLKColor alloc] init];
    color.name = @"purple";
    color.lightColor    = [QLKColorClass colorWithHue:0.806 saturation:1 brightness:0.85 alpha:1];      // #B500D9
    color.color         = [QLKColorClass colorWithHue:0.806 saturation:1 brightness:0.7 alpha:1];       // #9500B3
    color.darkColor     = [QLKColorClass colorWithHue:0.792 saturation:1 brightness:0.6 alpha:1];       // #730099
    return color;
}

+ (QLKColor *) colorWithName:(NSString *)name
{
    QLKColor *color = nil;
    
    if ( [_colors containsObject:name.lowercaseString] )
        color = [QLKColor performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@Color", name.lowercaseString])];
    
    if ( !color )
    {
        color = [[QLKColor alloc] init];
        color.name = name;
    }
    
    return color;
}

@end

NS_ASSUME_NONNULL_END
