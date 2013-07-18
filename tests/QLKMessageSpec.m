//
//  QLKMessageSpec.m
//  QLabKit
//
//  Created by Zach Waugh on 7/17/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKMessage.h"
#import "F53OSCMessage.h"

SpecBegin(QLKMessage)

describe(@"message", ^{
  __block F53OSCMessage *osc = nil;
  
  beforeEach(^{
    osc = [[F53OSCMessage alloc] init];
  });
  
  it(@"can be created with an OSC Message", ^{
    QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
    expect(message).toNot.beNil();
  });
  
  specify(@"address parts", ^{
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
  });
  
  context(@"reply", ^{
    it(@"should be a reply", ^{
      osc.addressPattern = @"/reply/workspace/IDDQD-IDKFA/cueLists";
      QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
      expect([message isReply]).to.beTruthy();
    });
  });
  
  context(@"update", ^{
    it(@"should be an update", ^{
      osc.addressPattern = @"/update/workspace/{workspace_id}";
      QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
      expect([message isUpdate]).to.beTruthy();
    });
    
    it(@"should not be a reply", ^{
      osc.addressPattern = @"/update/workspace/{workspace_id}";
      QLKMessage *message = [QLKMessage messageWithOSCMessage:osc];
      expect([message isReply]).to.beFalsy();
    });
    
    context(@"cue update", ^{
      __block QLKMessage *message;
      beforeEach(^{
        osc.addressPattern = @"/update/workspace/{workspace_id}/cue_id/12345";
        message = [QLKMessage messageWithOSCMessage:osc];
      });
      
      it(@"should be a cue update", ^{
        expect([message isCueUpdate]).to.beTruthy();
      });
      
      it(@"should not be a workspace update", ^{
        expect(message.isWorkspaceUpdate).to.beFalsy();
      });
      
      it(@"should not be a playback position update", ^{
        expect(message.isPlaybackPositionUpdate).to.beFalsy();
      });
      
      it(@"should have a cue id", ^{
        expect(message.cueID).to.equal(@"12345");
      });
    });
    
    context(@"workspace update", ^{
      __block QLKMessage *message;
      beforeEach(^{
        osc.addressPattern = @"/update/workspace/{workspace_id}";
        message = [QLKMessage messageWithOSCMessage:osc];
      });
      
      it(@"should be a workspace update", ^{
        expect(message.isWorkspaceUpdate).to.beTruthy();
      });
      
      it(@"should not be a cue update", ^{
        expect([message isCueUpdate]).to.beFalsy();
      });
      
      it(@"should not be a playback position update", ^{
        expect(message.isPlaybackPositionUpdate).to.beFalsy();
      });
    });
    
    context(@"playback position update", ^{
      __block QLKMessage *message;
      beforeEach(^{
        osc.addressPattern = @"/update/workspace/{workspace_id}/cueList/{cue_list_id}/playbackPosition";
        message = [QLKMessage messageWithOSCMessage:osc];
      });
      
      it(@"should not be a workspace update", ^{
        expect(message.isWorkspaceUpdate).to.beFalsy();
      });
      
      it(@"should not be a cue update", ^{
        expect([message isCueUpdate]).to.beFalsy();
      });
      
      it(@"should be a playback position update", ^{
        expect(message.isPlaybackPositionUpdate).to.beTruthy();
      });
    });
  });
});

SpecEnd