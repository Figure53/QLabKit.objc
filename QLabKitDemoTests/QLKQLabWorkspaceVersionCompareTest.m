//
//  QLKQLabWorkspaceVersionCompareTest.m
//  QLabKitDemoTests
//
//  Created by Brent Lord on 1/4/18.
//  Copyright © 2018 Figure 53. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "QLKWorkspace.h"


@interface QLabKitDemoTests : XCTestCase

@end


@implementation QLabKitDemoTests

- (void) setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testVersions
{
    // TESTS TO VERIFY VERSION COMPARISON WORKS
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedSame, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]]  == NSOrderedSame, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1.1"]]  == NSOrderedAscending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedSame, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]]  == NSOrderedSame, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1.1"]]  == NSOrderedAscending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.01"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedAscending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]]  == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedSame, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.2"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1.1"]]  == NSOrderedAscending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.11"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.2"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.2"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.2"]]  == NSOrderedSame, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.3"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.2"]]  == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.9"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedAscending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedSame, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]]  == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1"]]    == NSOrderedAscending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"2.1.1"]]  == NSOrderedAscending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.01"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.11"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.2"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.9"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.10"]] == NSOrderedDescending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedDescending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedDescending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedDescending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]]  == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1"]]    == NSOrderedDescending, @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    compare:[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]]  == NSOrderedDescending, @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isEqualToVersion:  @"1.0.0"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"1.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"1.1.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isEqualToVersion:  @"1.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]  isEqualToVersion:  @"1.1.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isNewerThanVersion:@"1.0.0"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"1.0.2"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"1.1.1"], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isEqualToVersion:  @"1.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isEqualToVersion:  @"1.0.0"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"1.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isNewerThanVersion:@"1.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isNewerThanVersion:@"1.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"1.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"1.1.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isEqualToVersion:  @"1.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isOlderThanVersion:@"1.1.1"], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isEqualToVersion:  @"1.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isNewerThanVersion:@"1.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"1.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"1.1"  ], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"2.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"2.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isOlderThanVersion:@"2.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isOlderThanVersion:@"2.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"2.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"2.1.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isOlderThanVersion:@"2.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isOlderThanVersion:@"2.1.1"], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"2.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"2.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"2.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"2.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"2.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"2.1.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"2.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"2.1.1"], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]    isOlderThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]  isOlderThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.01"] isOlderThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1"]  isOlderThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.2"]  isOlderThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.9"]  isOlderThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.11"] isNewerThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1"]    isNewerThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.0"]  isNewerThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.01"] isNewerThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.1"]  isNewerThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.2"]  isNewerThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.9"]  isNewerThanVersion:@"1.0.10"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"1.1.11"] isNewerThanVersion:@"1.0.10"], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    isNewerThanVersion:@"1.0"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    isNewerThanVersion:@"1.0.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    isNewerThanVersion:@"1.0"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    isNewerThanVersion:@"1.0.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    isNewerThanVersion:@"1.1"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0"]    isNewerThanVersion:@"1.1.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    isNewerThanVersion:@"1.1"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.1"]    isNewerThanVersion:@"1.1.1"  ], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  isNewerThanVersion:@"1.0"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  isNewerThanVersion:@"1.0.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  isNewerThanVersion:@"1.0"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  isNewerThanVersion:@"1.0.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  isNewerThanVersion:@"1.1"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.0"]  isNewerThanVersion:@"1.1.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  isNewerThanVersion:@"1.1"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"2.0.1"]  isNewerThanVersion:@"1.1.1"  ], @"" );
    
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isEqualToVersion:  @"3.0"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isEqualToVersion:  @"3.0.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.0"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.0.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.1"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.1.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.1.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.2"    ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.2.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"3.x"]    isOlderThanVersion:@"4.2.1"  ], @"" );
    
    // NOTE: QLKQLabWorkspaceVersion ignores build numbers, so test to be sure conversion of strings that include builds works correctly
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.0 b1"]   isEqualToVersion:  @"4.0.0"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.0.0 b1"] isEqualToVersion:  @"4.0.0"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.1.2 b1"] isEqualToVersion:  @"4.1.2"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.0.0 b1"] isOlderThanVersion:@"4.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.0.0 b1"] isOlderThanVersion:@"4.1"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.0.0 b1"] isOlderThanVersion:@"4.1.0"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.1 b1"]   isNewerThanVersion:@"4.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.1.0 b1"] isNewerThanVersion:@"4.0.1"], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.1.0 b1"] isNewerThanVersion:@"4.0"  ], @"" );
    XCTAssertTrue( [[QLKQLabWorkspaceVersion versionWithString:@"4.1.0 b1"] isNewerThanVersion:@"4.0.0"], @"" );
    
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (1)"]] == NSOrderedSame, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (1)"]] == NSOrderedSame, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1 (1)"]] == NSOrderedAscending, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.1 (1)"]] == NSOrderedAscending, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (1)"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (2)"]] == NSOrderedSame, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (2)"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (2)"]] == NSOrderedSame, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (3)"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (2)"]] == NSOrderedSame, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1 (2)"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.2 (1)"]] == NSOrderedAscending, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.2 (2)"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.2 (3)"]] == NSOrderedSame, @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.3 (1)"] compare:[QLKQLabWorkspaceVersion versionWithString:@"1.0.2 (2)"]] == NSOrderedDescending, @"" );
    
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       isEqualToVersion:  @"1.0.0 (1)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     isEqualToVersion:  @"1.0.0 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       isOlderThanVersion:@"1.0.0 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     isOlderThanVersion:@"1.0.0 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       isNewerThanVersion:@"1.0.0 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     isNewerThanVersion:@"1.0.0 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       isEqualToVersion:  @"1.0.1 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     isEqualToVersion:  @"1.0.1 (1)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       isOlderThanVersion:@"1.0.1 (1)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     isOlderThanVersion:@"1.0.1 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0"]       isNewerThanVersion:@"1.0.1 (1)"], @"" );
    XCTAssertFalse( [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0"]     isNewerThanVersion:@"1.0.1 (1)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (1)"] isEqualToVersion:  @"1.0.0 (2)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (2)"] isEqualToVersion:  @"1.0.0 (2)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.0 (3)"] isEqualToVersion:  @"1.0.0 (2)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.1 (2)"] isOlderThanVersion:@"1.0.2 (2)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.2 (2)"] isEqualToVersion:  @"1.0.2 (2)"], @"" );
    XCTAssertTrue(  [[QLKQLabWorkspaceVersion versionWithString:@"1.0.3 (2)"] isNewerThanVersion:@"1.0.2 (2)"], @"" );
}

@end
