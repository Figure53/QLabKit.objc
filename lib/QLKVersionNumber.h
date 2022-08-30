//
//  QLKVersionNumber.h
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

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface QLKVersionNumber : NSObject

@property (nonatomic, readonly) NSUInteger majorVersion;
@property (nonatomic, readonly) NSUInteger minorVersion;
@property (nonatomic, readonly) NSUInteger patchVersion;
@property (nonatomic, readonly, nullable) NSString *build;

+ (instancetype)versionWithString:(NSString *)versionString;
- (instancetype)initWithString:(NSString *)versionString;
- (instancetype)initWithMajorVersion:(NSUInteger)major minor:(NSUInteger)minor patch:(NSUInteger)patch;
- (instancetype)initWithMajorVersion:(NSUInteger)major minor:(NSUInteger)minor patch:(NSUInteger)patch build:(nullable NSString *)build;

@property (nonatomic, readonly, copy) NSString *stringValue;

- (NSComparisonResult)compare:(QLKVersionNumber *)otherVersion;
- (NSComparisonResult)compare:(QLKVersionNumber *)otherVersion ignoreBuild:(BOOL)ignoreBuild;

- (BOOL)isOlderThanVersion:(NSString *)version;
- (BOOL)isEqualToVersion:(NSString *)version;
- (BOOL)isNewerThanVersion:(NSString *)version;

@end


@interface NSString (QLKVersionNumber)

- (NSComparisonResult)compareVersion:(NSString *)version ignoreBuild:(BOOL)ignoreBuild;

- (BOOL)isOlderThanVersion:(NSString *)version;
- (BOOL)isEqualToOrOlderThanVersion:(NSString *)version;
- (BOOL)isEqualToVersion:(NSString *)version;
- (BOOL)isEqualToOrNewerThanVersion:(NSString *)version;
- (BOOL)isNewerThanVersion:(NSString *)version;

@end

NS_ASSUME_NONNULL_END
