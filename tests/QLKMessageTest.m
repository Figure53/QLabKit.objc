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

- (void)testMessageWithOSCMessage
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  expect(message).toNot.beNil();
}

- (void)testAddressParts
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/update/workspace/{workspace_id}/cue_id/{cue_id}";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  NSArray *parts = message.addressParts;
  
  expect(parts.count).to.beGreaterThan(0);
  expect(parts[0]).toNot.equal(@"/");
  expect(parts.count).to.equal(5);
  expect(parts[0]).to.equal(@"update");
  expect(parts[1]).to.equal(@"workspace");
  expect(parts[2]).to.equal(@"{workspace_id}");
  expect(parts[3]).to.equal(@"cue_id");
  expect(parts[4]).to.equal(@"{cue_id}");
}

- (void)testIsUpdate
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/update/workspace/{workspace_id}";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  expect([message isUpdate]).to.beTruthy();
}

- (void)testIsReply
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/reply/workspace/IDDQD-IDKFA/cueLists";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  expect([message isReply]).to.beTruthy();
}

- (void)testIsCueUpdate
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/update/workspace/{workspace_id}/cue_id/{cue_id}";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  expect([message isCueUpdate]).to.beTruthy();
  expect(message.isPlaybackPositionUpdate).to.beFalsy();
  expect(message.isWorkspaceUpdate).to.beFalsy();
}

- (void)testIsNotCueUpdate
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/foo/bar/{workspace_id}/cue_id/{cue_id}";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  expect([message isCueUpdate]).to.beFalsy();
}

- (void)testIsWorkspaceUpdate
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/update/workspace/{workspace_id}";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  expect(message.isWorkspaceUpdate).to.beTruthy();
  expect(message.isCueUpdate).to.beFalsy();
}

- (void)testIsPlaybackPositionUpdate
{
  F53OSCMessage *osc = [[F53OSCMessage alloc] init];
  osc.addressPattern = @"/update/workspace/{workspace_id}/cueList/{cue_list_id}/playbackPosition";
  QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
  
  expect(message.isPlaybackPositionUpdate).to.beTruthy();
  expect(message.isWorkspaceUpdate).to.beFalsy();
  expect(message.isCueUpdate).to.beFalsy();
}

@end
