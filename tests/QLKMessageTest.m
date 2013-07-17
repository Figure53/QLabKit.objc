//
//  QLKMessageTest.m
//  QLabKit
//
//  Created by Zach Waugh on 7/17/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKMessageTest.h"
#import "QLKMessage.h"
#import "F53OSCMessage.h"

@implementation QLKMessageTest

- (void)testIsUpdate
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/update/workspace/{workspace_id}";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  expect(message).toNot.beNil();
  expect([message isUpdate]).to.beTruthy();
}

- (void)testIsReply
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/reply/workspace/IDDQD-IDKFA/cueLists";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  expect(message).toNot.beNil();
  expect([message isReply]).to.beTruthy();
}


@end
