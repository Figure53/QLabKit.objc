//
//  QCartColor.h
//  QCart
//
//  Created by Zach Waugh on 7/1/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QLKDefines.h"

@interface QLKColor : NSObject <NSCoding>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) QLKColorClass *startColor;
@property (strong, nonatomic) QLKColorClass *endColor;

+ (NSSet *)colors;
+ (QLKColor *)defaultColor;
+ (QLKColor *)redColor;
+ (QLKColor *)orangeColor;
+ (QLKColor *)lightblueColor;
+ (QLKColor *)blueColor;
+ (QLKColor *)yellowColor;
+ (QLKColor *)greenColor;
+ (QLKColor *)purpleColor;
+ (QLKColor *)colorWithName:(NSString *)name;
- (BOOL)isEqualToColor:(QLKColor *)color;

+ (QLKColor *)panelColor;
+ (QLKColor *)navBarColor;

+ (QLKColorClass *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (QLKColorClass *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;

@end
