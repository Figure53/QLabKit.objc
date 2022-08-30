//
//  QLKVersionNumberCompareTest.m
//  QLabKitDemoTests
//
//  Created by Brent Lord on 6/1/14.
//  Copyright 2014-2019 Figure 53, LLC. All rights reserved.
//

@import XCTest;

#import "QLKVersionNumber.h"


@interface QLKVersionNumberCompareTest : XCTestCase
@end


@implementation QLKVersionNumberCompareTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testVersionObjectComparisons
{
    // TESTS TO VERIFY VERSION COMPARISON WORKS
    QLKVersionNumber *version;

    version = [[QLKVersionNumber alloc] initWithString:@"1.2.3"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:1 minor:2 patch:3 build:nil], @"");
    XCTAssertEqualObjects(version, [QLKVersionNumber versionWithString:@"1.2.3"], @"");
    XCTAssertTrue([version isEqual:[QLKVersionNumber versionWithString:@"1.2.3"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"1.2.3 (4)"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"1.2.3 (b4)"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"1.2.3 b4"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"1.2.3.4"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"1.2.3 4"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"1.2.3 0"]], @"");
    XCTAssertTrue([version compare:[QLKVersionNumber versionWithString:@"1.2.3"]] == NSOrderedSame, @"");
    XCTAssertTrue([version compare:[QLKVersionNumber versionWithString:@"1.2.3"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([version compare:[QLKVersionNumber versionWithString:@"1.2.3"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([version.stringValue isEqualToString:@"1.2.3"], @"");
    XCTAssertTrue(version.majorVersion == 1, @"");
    XCTAssertTrue(version.minorVersion == 2, @"");
    XCTAssertTrue(version.patchVersion == 3, @"");
    XCTAssertNil(version.build, @"");

    version = [[QLKVersionNumber alloc] initWithString:@"2.3.4 (5)"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:2 minor:3 patch:4 build:@"5"], @"");
    XCTAssertEqualObjects(version, [QLKVersionNumber versionWithString:@"2.3.4 (5)"], @"");
    XCTAssertTrue([version isEqual:[QLKVersionNumber versionWithString:@"2.3.4 (5)"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"2.3.4"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"2.3.4 (b5)"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"2.3.4 b5"]], @"");
    XCTAssertTrue([version isEqual:[QLKVersionNumber versionWithString:@"2.3.4.5"]], @"");
    XCTAssertTrue([version isEqual:[QLKVersionNumber versionWithString:@"2.3.4 5"]], @"");
    XCTAssertFalse([version isEqual:[QLKVersionNumber versionWithString:@"2.3.4 0"]], @"");
    XCTAssertTrue([version compare:[QLKVersionNumber versionWithString:@"2.3.4 (5)"]] == NSOrderedSame, @"");
    XCTAssertTrue([version compare:[QLKVersionNumber versionWithString:@"2.3.4 (5)"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([version compare:[QLKVersionNumber versionWithString:@"2.3.4 (5)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([version.stringValue isEqualToString:@"2.3.4 (5)"], @"");
    XCTAssertTrue(version.majorVersion == 2, @"");
    XCTAssertTrue(version.minorVersion == 3, @"");
    XCTAssertTrue(version.patchVersion == 4, @"");
    XCTAssertTrue([version.build isEqualToString:@"5"], @"");

    version = [[QLKVersionNumber alloc] initWithString:@"10"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:10 minor:0 patch:0 build:nil], @"");
    XCTAssertTrue(version.majorVersion == 10, @"");
    XCTAssertTrue(version.minorVersion == 0, @"");
    XCTAssertTrue(version.patchVersion == 0, @"");
    XCTAssertNil(version.build, @"");

    version = [[QLKVersionNumber alloc] initWithString:@"01.02.03"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:1 minor:2 patch:3 build:nil], @"");
    XCTAssertTrue(version.majorVersion == 1, @"");
    XCTAssertTrue(version.minorVersion == 2, @"");
    XCTAssertTrue(version.patchVersion == 3, @"");
    XCTAssertNil(version.build, @"");

    version = [[QLKVersionNumber alloc] initWithString:@"3.2"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:3 minor:2 patch:0 build:nil], @"");
    XCTAssertTrue(version.majorVersion == 3, @"");
    XCTAssertTrue(version.minorVersion == 2, @"");
    XCTAssertTrue(version.patchVersion == 0, @"");
    XCTAssertNil(version.build, @"");

    version = [[QLKVersionNumber alloc] initWithString:@".2"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:0 minor:2 patch:0 build:nil], @"");
    XCTAssertTrue(version.majorVersion == 0, @"");
    XCTAssertTrue(version.minorVersion == 2, @"");
    XCTAssertTrue(version.patchVersion == 0, @"");
    XCTAssertNil(version.build, @"");

    version = [[QLKVersionNumber alloc] initWithString:@"4.5 (6)"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:4 minor:5 patch:0 build:@"6"], @"");
    XCTAssertTrue(version.majorVersion == 4, @"");
    XCTAssertTrue(version.minorVersion == 5, @"");
    XCTAssertTrue(version.patchVersion == 0, @"");
    XCTAssertTrue([version.build isEqualToString:@"6"], @"");

    version = [[QLKVersionNumber alloc] initWithString:@"4.5 (b6)"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:4 minor:5 patch:0 build:@"b6"], @"");
    XCTAssertTrue(version.majorVersion == 4, @"");
    XCTAssertTrue(version.minorVersion == 5, @"");
    XCTAssertTrue(version.patchVersion == 0, @"");
    XCTAssertTrue([version.build isEqualToString:@"b6"], @"");

    version = [[QLKVersionNumber alloc] initWithString:@"4.5.6.7"];

    XCTAssertEqualObjects(version, [[QLKVersionNumber alloc] initWithMajorVersion:4 minor:5 patch:6 build:@"7"], @"");
    XCTAssertTrue(version.majorVersion == 4, @"");
    XCTAssertTrue(version.minorVersion == 5, @"");
    XCTAssertTrue(version.patchVersion == 6, @"");
    XCTAssertTrue([version.build isEqualToString:@"7"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (b1)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (b1)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (b1)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b1)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b3)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (b1)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (b1)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (b1)"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b1)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b3)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (b2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0"] isEqualToVersion:@"1.0.0 (b1)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isNewerThanVersion:@"1.0.0 (b1)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"1.0.2 (b1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] isEqualToVersion:@"1.0.0 (b2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b2)"] isEqualToVersion:@"1.0.0 (b2)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0 (b3)"] isEqualToVersion:@"1.0.0 (b2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (b2)"] isOlderThanVersion:@"1.0.2 (b2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (b2)"] isEqualToVersion:@"1.0.2 (b2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (b2)"] isNewerThanVersion:@"1.0.2 (b2)"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b1"] isEqualToVersion:@"1.0.0 (b1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0 1"] isEqualToVersion:@"1.0.0 (b1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0.1"] isEqualToVersion:@"1.0.0 (b1)"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 b1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1 b1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.1 b1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b1"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b2"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b2"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b3"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b2"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b2"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b2"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b2"] ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b1"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 b1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1 b1"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.1 b1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b1"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b3"] compare:[QLKVersionNumber versionWithString:@"1.0.0 b2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b2"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 b2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 b2"] ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0"] isEqualToVersion:@"1.0.0 b1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isNewerThanVersion:@"1.0.0 b1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"1.0.2 b1"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0 b1"] isEqualToVersion:@"1.0.0 b2"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 b2"] isEqualToVersion:@"1.0.0 b2"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0 b3"] isEqualToVersion:@"1.0.0 b2"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 b2"] isOlderThanVersion:@"1.0.2 b2"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 b2"] isEqualToVersion:@"1.0.2 b2"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 b2"] isNewerThanVersion:@"1.0.2 b2"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (1)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (1)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (1)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (1)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (1)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (2)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (2)"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (3)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (2)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (2)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (2)"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (2)"] ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (1)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (1)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (1)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1 (1)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (1)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (3)"] compare:[QLKVersionNumber versionWithString:@"1.0.0 (2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (2)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (2)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (2)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (2)"] ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isEqualToVersion:@"1.0.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"1.0.1"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0"] isEqualToVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0"] isEqualToVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isNewerThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isNewerThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0"] isEqualToVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0"] isEqualToVersion:@"1.0.1 (1)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0"] isNewerThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0"] isNewerThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0 (1)"] isEqualToVersion:@"1.0.0 (2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (2)"] isEqualToVersion:@"1.0.0 (2)"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0 (3)"] isEqualToVersion:@"1.0.0 (2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (2)"] isOlderThanVersion:@"1.0.2 (2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (2)"] isEqualToVersion:@"1.0.2 (2)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (2)"] isNewerThanVersion:@"1.0.2 (2)"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (10)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (10)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (10)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1 (10)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2 (10)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (10)"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3"] compare:[QLKVersionNumber versionWithString:@"1.0.2 (20)"] ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3 (10)"] isNewerThanVersion:@"1.0.2 (20)"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.3"] isNewerThanVersion:@"1.0.2 (20)"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.2"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b2"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b2"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b2"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b3"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b2"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b10"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b10"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b1"] ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b1"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b1"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b2"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b3"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b2"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b1"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b10"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b10"] compare:[QLKVersionNumber versionWithString:@"1.0.0.b1"] ignoreBuild:YES] == NSOrderedSame, @"");

    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0"] isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0.1"] isEqualToVersion:@"1.0.0.2"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0.1"] isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0.b1"] isEqualToVersion:@"1.0.0.b2"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0.b2"] isEqualToVersion:@"1.0.0.b2"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0.b3"] isEqualToVersion:@"1.0.0.b2"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0.b1"] isEqualToVersion:@"1.0.0.b10"], @"");
    XCTAssertFalse([[QLKVersionNumber versionWithString:@"1.0.0.b10"] isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (b1)"] isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (1)"] isEqualToVersion:@"1.0.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0 (12)"] isEqualToVersion:@"1.0.0.12"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isEqualToVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isEqualToVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isOlderThanVersion:@"1.1.1"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isEqualToVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isEqualToVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"1.1.1"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"2.1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isOlderThanVersion:@"2.1.1"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.0"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.0.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.1"] ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] compare:[QLKVersionNumber versionWithString:@"2.1.1"] ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"2.1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"2.1.1"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0"] isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.0"] isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.01"] isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.1"] isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.2"] isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.9"] isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.0.11"] isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1"] isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1.0"] isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1.01"] isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1.1"] isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1.2"] isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1.9"] isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"1.1.11"] isNewerThanVersion:@"1.0.10"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0"] isNewerThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.1"] isNewerThanVersion:@"1.1.1"], @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.0.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] compare:[QLKVersionNumber versionWithString:@"1.1.1"] ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.0"] isNewerThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([[QLKVersionNumber versionWithString:@"2.0.1"] isNewerThanVersion:@"1.1.1"], @"");
}

- (void)testVersionStringComparisons
{
    // TESTS TO VERIFY VERSION COMPARISON WORKS

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0 (b1)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.0 (b1)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.0 (b1)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1 (b1)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.1 (b1)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.1 (b1)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.2 (b1)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 (b1)" compareVersion:@"1.0.0 (b2)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 (b2)" compareVersion:@"1.0.0 (b2)" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 (b3)" compareVersion:@"1.0.0 (b2)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1 (b2)" compareVersion:@"1.0.2 (b2)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 (b2)" compareVersion:@"1.0.2 (b2)" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.3 (b2)" compareVersion:@"1.0.2 (b2)" ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0 (b1)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.0 (b1)" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.0 (b1)" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1 (b1)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.1 (b1)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.1 (b1)" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.2 (b1)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 (b1)" compareVersion:@"1.0.0 (b2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 (b2)" compareVersion:@"1.0.0 (b2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 (b3)" compareVersion:@"1.0.0 (b2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.1 (b2)" compareVersion:@"1.0.2 (b2)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 (b2)" compareVersion:@"1.0.2 (b2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.3 (b2)" compareVersion:@"1.0.2 (b2)" ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertFalse([@"1.0.0" isEqualToVersion:@"1.0.0 (b1)"], @"");
    XCTAssertTrue([@"1.0.1" isNewerThanVersion:@"1.0.0 (b1)"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"1.0.2 (b1)"], @"");
    XCTAssertFalse([@"1.0.0 (b1)" isEqualToVersion:@"1.0.0 (b2)"], @"");
    XCTAssertTrue([@"1.0.0 (b2)" isEqualToVersion:@"1.0.0 (b2)"], @"");
    XCTAssertFalse([@"1.0.0 (b3)" isEqualToVersion:@"1.0.0 (b2)"], @"");
    XCTAssertTrue([@"1.0.1 (b2)" isOlderThanVersion:@"1.0.2 (b2)"], @"");
    XCTAssertTrue([@"1.0.2 (b2)" isEqualToVersion:@"1.0.2 (b2)"], @"");
    XCTAssertTrue([@"1.0.3 (b2)" isNewerThanVersion:@"1.0.2 (b2)"], @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0 b1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.0 b1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.0 b1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1 b1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.1 b1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.1 b1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.2 b1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 b1" compareVersion:@"1.0.0 b2" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 b2" compareVersion:@"1.0.0 b2" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 b3" compareVersion:@"1.0.0 b2" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1 b2" compareVersion:@"1.0.2 b2" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 b2" compareVersion:@"1.0.2 b2" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.3 b2" compareVersion:@"1.0.2 b2" ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0 b1" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.0 b1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.0 b1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1 b1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.1 b1" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.1 b1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.2 b1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 b1" compareVersion:@"1.0.0 b2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 b2" compareVersion:@"1.0.0 b2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 b3" compareVersion:@"1.0.0 b2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.1 b2" compareVersion:@"1.0.2 b2" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 b2" compareVersion:@"1.0.2 b2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.3 b2" compareVersion:@"1.0.2 b2" ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertFalse([@"1.0.0" isEqualToVersion:@"1.0.0 b1"], @"");
    XCTAssertTrue([@"1.0.1" isNewerThanVersion:@"1.0.0 b1"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"1.0.2 b1"], @"");
    XCTAssertFalse([@"1.0.0 b1" isEqualToVersion:@"1.0.0 b2"], @"");
    XCTAssertTrue([@"1.0.0 b2" isEqualToVersion:@"1.0.0 b2"], @"");
    XCTAssertFalse([@"1.0.0 b3" isEqualToVersion:@"1.0.0 b2"], @"");
    XCTAssertTrue([@"1.0.1 b2" isOlderThanVersion:@"1.0.2 b2"], @"");
    XCTAssertTrue([@"1.0.2 b2" isEqualToVersion:@"1.0.2 b2"], @"");
    XCTAssertTrue([@"1.0.3 b2" isNewerThanVersion:@"1.0.2 b2"], @"");

    XCTAssertTrue([@"1.0" compareVersion:@"1.0.0" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.0 (1)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0 (1)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.1 (1)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1 (1)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 (1)" compareVersion:@"1.0.0 (2)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 (2)" compareVersion:@"1.0.0 (2)" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 (3)" compareVersion:@"1.0.0 (2)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1 (2)" compareVersion:@"1.0.2 (2)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 (2)" compareVersion:@"1.0.2 (2)" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.3 (2)" compareVersion:@"1.0.2 (2)" ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([@"1.0" compareVersion:@"1.0.0" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.0 (1)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0 (1)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.1 (1)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1 (1)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0 (1)" compareVersion:@"1.0.0 (2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 (2)" compareVersion:@"1.0.0 (2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0 (3)" compareVersion:@"1.0.0 (2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.1 (2)" compareVersion:@"1.0.2 (2)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 (2)" compareVersion:@"1.0.2 (2)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.3 (2)" compareVersion:@"1.0.2 (2)" ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([@"1.0" isEqualToVersion:@"1.0.0"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"1.0.1"], @"");
    XCTAssertFalse([@"1.0" isEqualToVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([@"1.0.0" isEqualToVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([@"1.0" isOlderThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([@"1.0.0" isOlderThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertTrue([@"1.0" isNewerThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertTrue([@"1.0.0" isNewerThanVersion:@"1.0.0 (1)"], @"");
    XCTAssertFalse([@"1.0" isEqualToVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([@"1.0.0" isEqualToVersion:@"1.0.1 (1)"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([@"1.0" isNewerThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([@"1.0.0" isNewerThanVersion:@"1.0.1 (1)"], @"");
    XCTAssertFalse([@"1.0.0 (1)" isEqualToVersion:@"1.0.0 (2)"], @"");
    XCTAssertTrue([@"1.0.0 (2)" isEqualToVersion:@"1.0.0 (2)"], @"");
    XCTAssertFalse([@"1.0.0 (3)" isEqualToVersion:@"1.0.0 (2)"], @"");
    XCTAssertTrue([@"1.0.1 (2)" isOlderThanVersion:@"1.0.2 (2)"], @"");
    XCTAssertTrue([@"1.0.2 (2)" isEqualToVersion:@"1.0.2 (2)"], @"");
    XCTAssertTrue([@"1.0.3 (2)" isNewerThanVersion:@"1.0.2 (2)"], @"");

    XCTAssertTrue([@"1.0.1 (10)" compareVersion:@"1.0.2 (20)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.2 (20)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 (10)" compareVersion:@"1.0.2 (20)" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.2 (20)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.3 (10)" compareVersion:@"1.0.2 (20)" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.3" compareVersion:@"1.0.2 (20)" ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([@"1.0.1 (10)" compareVersion:@"1.0.2 (20)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.2 (20)" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.2 (10)" compareVersion:@"1.0.2 (20)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.2" compareVersion:@"1.0.2 (20)" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.3 (10)" compareVersion:@"1.0.2 (20)" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.3" compareVersion:@"1.0.2 (20)" ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([@"1.0.3 (10)" isNewerThanVersion:@"1.0.2 (20)"], @"");
    XCTAssertTrue([@"1.0.3" isNewerThanVersion:@"1.0.2 (20)"], @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0.b1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.0.1" compareVersion:@"1.0.0.2" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0.1" compareVersion:@"1.0.0.b1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0.b1" compareVersion:@"1.0.0.b2" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0.b2" compareVersion:@"1.0.0.b2" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.b3" compareVersion:@"1.0.0.b2" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.0.b1" compareVersion:@"1.0.0.b10" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0.b10" compareVersion:@"1.0.0.b1" ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.0.b1" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.1" compareVersion:@"1.0.0.2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.1" compareVersion:@"1.0.0.b1" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.b1" compareVersion:@"1.0.0.b2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.b2" compareVersion:@"1.0.0.b2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.b3" compareVersion:@"1.0.0.b2" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.b1" compareVersion:@"1.0.0.b10" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0.b10" compareVersion:@"1.0.0.b1" ignoreBuild:YES] == NSOrderedSame, @"");

    XCTAssertFalse([@"1.0.0" isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertFalse([@"1.0.0.1" isEqualToVersion:@"1.0.0.2"], @"");
    XCTAssertFalse([@"1.0.0.1" isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertFalse([@"1.0.0.b1" isEqualToVersion:@"1.0.0.b2"], @"");
    XCTAssertTrue([@"1.0.0.b2" isEqualToVersion:@"1.0.0.b2"], @"");
    XCTAssertFalse([@"1.0.0.b3" isEqualToVersion:@"1.0.0.b2"], @"");
    XCTAssertFalse([@"1.0.0.b1" isEqualToVersion:@"1.0.0.b10"], @"");
    XCTAssertFalse([@"1.0.0.b10" isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertTrue([@"1.0.0 (b1)" isEqualToVersion:@"1.0.0.b1"], @"");
    XCTAssertTrue([@"1.0.0 (1)" isEqualToVersion:@"1.0.0.1"], @"");
    XCTAssertTrue([@"1.0.0 (12)" isEqualToVersion:@"1.0.0.12"], @"");

    XCTAssertTrue([@"1.0" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0" isEqualToVersion:@"1.0"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"1.1" isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([@"1.1" isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"1.1"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([@"1.1" isEqualToVersion:@"1.1"], @"");
    XCTAssertTrue([@"1.1" isOlderThanVersion:@"1.1.1"], @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedSame, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0.0" isEqualToVersion:@"1.0"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"1.0.1" isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([@"1.0.1" isEqualToVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"1.1"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"1.1"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"1.1.1"], @"");

    XCTAssertTrue([@"1.0" compareVersion:@"2.0" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"2.0.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.0" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.0.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"2.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"2.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0" compareVersion:@"2.0" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"2.0.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.0" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.0.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"2.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0" compareVersion:@"2.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.1" compareVersion:@"2.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0" isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([@"1.1" isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([@"1.1" isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([@"1.0" isOlderThanVersion:@"2.1.1"], @"");
    XCTAssertTrue([@"1.1" isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([@"1.1" isOlderThanVersion:@"2.1.1"], @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"2.0" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"2.0.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.0" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.0.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"2.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"2.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.1" ignoreBuild:NO] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.1.1" ignoreBuild:NO] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0.0" compareVersion:@"2.0" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"2.0.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.0" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.0.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"2.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.0" compareVersion:@"2.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.1" ignoreBuild:YES] == NSOrderedAscending, @"");
    XCTAssertTrue([@"1.0.1" compareVersion:@"2.1.1" ignoreBuild:YES] == NSOrderedAscending, @"");

    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"2.0"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"2.0.1"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"2.1.1"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"2.1"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"2.1.1"], @"");

    XCTAssertTrue([@"1.0" isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.0.0" isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.0.01" isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.0.1" isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.0.2" isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.0.9" isOlderThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.0.11" isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.1" isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.1.0" isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.1.01" isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.1.1" isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.1.2" isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.1.9" isNewerThanVersion:@"1.0.10"], @"");
    XCTAssertTrue([@"1.1.11" isNewerThanVersion:@"1.0.10"], @"");

    XCTAssertTrue([@"2.0" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([@"2.0" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.1" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([@"2.0" isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([@"2.0" isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"2.1" isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([@"2.1" isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"2.0" isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([@"2.0" isNewerThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([@"2.1" isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([@"2.1" isNewerThanVersion:@"1.1.1"], @"");

    XCTAssertTrue([@"2.0.0" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.0" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.0" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.0.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.0" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.0" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.1" ignoreBuild:NO] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.1.1" ignoreBuild:NO] == NSOrderedDescending, @"");

    XCTAssertTrue([@"2.0.0" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.0" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.0" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.0.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.0" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.0" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.1" ignoreBuild:YES] == NSOrderedDescending, @"");
    XCTAssertTrue([@"2.0.1" compareVersion:@"1.1.1" ignoreBuild:YES] == NSOrderedDescending, @"");

    XCTAssertTrue([@"2.0.0" isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([@"2.0.0" isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"2.0.1" isNewerThanVersion:@"1.0"], @"");
    XCTAssertTrue([@"2.0.1" isNewerThanVersion:@"1.0.1"], @"");
    XCTAssertTrue([@"2.0.0" isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([@"2.0.0" isNewerThanVersion:@"1.1.1"], @"");
    XCTAssertTrue([@"2.0.1" isNewerThanVersion:@"1.1"], @"");
    XCTAssertTrue([@"2.0.1" isNewerThanVersion:@"1.1.1"], @"");
}

@end
