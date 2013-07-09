//
//  QCartColor.h
//  QCart
//
//  Created by Zach Waugh on 7/1/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QLKDefines.h"

@interface QLRColor : NSObject <NSCoding>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) QLKColor *startColor;
@property (strong, nonatomic) QLKColor *endColor;

+ (NSSet *)colors;
+ (QLRColor *)defaultColor;
+ (QLRColor *)redColor;
+ (QLRColor *)orangeColor;
+ (QLRColor *)lightblueColor;
+ (QLRColor *)blueColor;
+ (QLRColor *)yellowColor;
+ (QLRColor *)greenColor;
+ (QLRColor *)purpleColor;
+ (QLRColor *)colorWithName:(NSString *)name;
- (BOOL)isEqualToColor:(QLRColor *)color;

+ (QLKColor *)panelColor;
+ (QLKColor *)navBarColor;

+ (QLKColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (QLKColor *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;

@end
