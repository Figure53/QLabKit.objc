//
//  QLKMessageTest.h
//  QLabKit
//
//  Created by Zach Waugh on 7/17/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface QLKMessageTest : SenTestCase

- (void)testMessageWithOSCMessage;
- (void)testAddressParts;
- (void)testIsUpdate;
- (void)testIsNotCueUpdate;
- (void)testIsReply;
- (void)testIsCueUpdate;
- (void)testIsWorkspaceUpdate;
- (void)testIsPlaybackPositionUpdate;

@end
