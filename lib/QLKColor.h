//
//  QLKColor.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013 Figure 53 LLC, http://figure53.com
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


#import <Foundation/Foundation.h>
#import "QLKDefines.h"

@interface QLKColor : NSObject <NSCoding>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) QLKColorClass *startColor;
@property (strong, nonatomic) QLKColorClass *endColor;

+ (NSSet *) colors;
+ (QLKColor *) defaultColor;
+ (QLKColor *) redColor;
+ (QLKColor *) orangeColor;
+ (QLKColor *) lightblueColor;
+ (QLKColor *) blueColor;
+ (QLKColor *) yellowColor;
+ (QLKColor *) greenColor;
+ (QLKColor *) purpleColor;
+ (QLKColor *) colorWithName:(NSString *)name;
- (BOOL) isEqualToColor:(QLKColor *)color;

+ (QLKColorClass *) panelColor;
+ (QLKColorClass *) navBarColor;

+ (QLKColorClass *) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (QLKColorClass *) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;

@end
