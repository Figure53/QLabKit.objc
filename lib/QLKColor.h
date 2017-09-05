//
//  QLKColor.h
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

@import Foundation;

#import "QLKDefines.h"


NS_ASSUME_NONNULL_BEGIN

@interface QLKColor : NSObject <NSCoding>

@property (strong, nonatomic, nullable)             NSString *name;
@property (strong, nonatomic, nullable)             QLKColorClass *color;
@property (strong, nonatomic, nullable)             QLKColorClass *darkColor;

+ (NSSet *) colors;
+ (QLKColor *) defaultColor;
+ (QLKColor *) redColor;
+ (QLKColor *) orangeColor;
+ (QLKColor *) yellowColor;
+ (QLKColor *) greenColor;
+ (QLKColor *) blueColor;
+ (QLKColor *) purpleColor;
+ (nullable QLKColor *) colorWithName:(NSString *)name;
- (BOOL) isEqualToColor:(QLKColor *)color;


// Deprecated in 0.0.3 - leaving for compatibility with QLabKit.objc 0.0.2
@property (strong, nonatomic, readonly, nullable)   QLKColorClass *startColor DEPRECATED_MSG_ATTRIBUTE("Use lightColor instead");  // returns lightColor
@property (strong, nonatomic, readonly, nullable)   QLKColorClass *endColor DEPRECATED_MSG_ATTRIBUTE("Use darkColor instead");    // returns darkColor

+ (QLKColor *) lightblueColor DEPRECATED_ATTRIBUTE;
+ (QLKColorClass *) panelColor DEPRECATED_ATTRIBUTE;
+ (QLKColorClass *) navBarColor DEPRECATED_ATTRIBUTE;
+ (QLKColorClass *) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha DEPRECATED_ATTRIBUTE;
+ (QLKColorClass *) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha DEPRECATED_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
