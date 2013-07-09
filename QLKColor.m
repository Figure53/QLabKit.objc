//
//  QCartColor.m
//  QCart
//
//  Created by Zach Waugh on 7/1/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "QLKColor.h"

static NSSet *_colors = nil;

@implementation QLKColor

+ (void)initialize
{
  _colors = [NSSet setWithObjects:@"red", @"orange", @"blue", @"lightblue", @"yellow", @"green", @"purple", nil];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) return nil;
  
  _name = [decoder decodeObjectForKey:@"name"];
  _startColor = [decoder decodeObjectForKey:@"startColor"];
  _endColor = [decoder decodeObjectForKey:@"endColor"];
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_startColor forKey:@"startColor"];
    [coder encodeObject:_endColor forKey:@"endColor"];
  }
}

- (BOOL)isEqualToColor:(QLKColor *)color
{
  // Simplified comparison since we know the colors are limited
  return ([self.name isEqualToString:color.name]);
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"QLRColor: %@", self.name];
}

#pragma mark - Convenience class methods for predefined colors

+ (NSSet *)colors
{
  return _colors;
}

+ (QLKColor *)defaultColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"none";
  color.startColor = [self.class colorWithWhite:0.25 alpha:1.0];
  color.endColor = [self.class colorWithWhite:0.22 alpha:1.0];
  
  return color;
}

+ (QLKColor *)redColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"red";
  color.startColor = [self.class colorWithRed:0.945 green:0.482 blue:0.482 alpha:1.000];
  color.endColor = [self.class colorWithRed:0.776 green:0.314 blue:0.314 alpha:1.000];

  return color;
}

+ (QLKColor *)blueColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"blue";
  color.startColor = [self.class colorWithRed:0.467 green:0.6 blue:0.737 alpha:1.000];
  color.endColor = [self.class colorWithRed:0.282 green:0.416 blue:0.553 alpha:1.000];
  
  return color;
}

+ (QLKColor *)lightblueColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"lightblue";
  color.startColor = [self.class colorWithRed:0.710 green:0.835 blue:0.914 alpha:1.000];
  color.endColor = [self.class colorWithRed:0.541 green:0.667 blue:0.745 alpha:1.000];
  
  return color;
}

+ (QLKColor *)orangeColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"orange";
  color.startColor = [self.class colorWithRed:0.929 green:0.737 blue:0.365 alpha:1.000];
  color.endColor = [self.class colorWithRed:0.765 green:0.573 blue:0.200 alpha:1.000];

  return color;
}

+ (QLKColor *)yellowColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"yellow";
  color.startColor = [self.class colorWithRed:0.969 green:0.973 blue:0.678 alpha:1.000];
  color.endColor = [self.class colorWithRed:0.804 green:0.808 blue:0.514 alpha:1.000];

  return color;
}

+ (QLKColor *)greenColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"green";
  color.startColor = [self.class colorWithRed:0.655 green:0.796 blue:0.616 alpha:1.000];
  color.endColor = [self.class colorWithRed:0.486 green:0.627 blue:0.447 alpha:1.000];

  return color;
}

+ (QLKColor *)purpleColor
{
  QLKColor *color = [[QLKColor alloc] init];
  color.name = @"purple";
  color.startColor = [self.class colorWithRed:0.863 green:0.612 blue:0.910 alpha:1.000];
  color.endColor = [self.class colorWithRed:0.694 green:0.443 blue:0.741 alpha:1.000];

  return color;
}

+ (QLKColor *)colorWithName:(NSString *)name
{	
  QLKColor *color;

  if ([_colors containsObject:[name lowercaseString]]) {
    color = [QLKColor performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@Color", [name lowercaseString]])];
  } else {
    color = [QLKColor defaultColor];
  }
	  
  return color;
}

#pragma mark - Colors

+ (QLKColorClass *)panelColor
{
  return [self.class colorWithRed:0.282 green:0.282 blue:0.282 alpha:1];
}

+ (QLKColorClass *)navBarColor
{
  return [self.class colorWithRed:0.150 green:0.150 blue:0.150 alpha:1];
}

#pragma mark - Helper

+ (QLKColorClass *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
#if TARGET_OS_IPHONE
  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
#else
  return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
#endif
}

+ (QLKColorClass *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
#if TARGET_OS_IPHONE
  return [UIColor colorWithWhite:white alpha:alpha];
#else
  return [NSColor colorWithCalibratedWhite:white alpha:alpha];
#endif
}

@end
