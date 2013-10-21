//
//  QLKMessageSpec.m
//  QLabKit
//
//  Created by Zach Waugh on 7/17/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKWorkspace.h"
#import "QLKCue.h"

SpecBegin(QLKWorkspace)

describe(@"server", ^{
  __block QLKWorkspace *workspace;
  
  beforeEach(^{
    workspace = [[QLKWorkspace alloc] initWithDictionary:@{ @"displayName": @"Workspace", @"uniqueID": @"ABC123"} server:nil];
  });
  
  it(@"can be created with a dictionary", ^{
    NSDictionary *dict = @{ @"uniqueID": @"123", @"displayName": @"Test Workspace", @"hasPasscode": @NO };
    QLKWorkspace *workspace = [[QLKWorkspace alloc] initWithDictionary:dict server:nil];
    expect(workspace.name).to.equal(@"Test Workspace");
    expect(workspace.uniqueId).to.equal(@"123");
    expect(workspace.hasPasscode).to.equal(NO);
  });
  
  context(@"addresses", ^{
    specify(@"addressForCue:action:", ^{
      QLKCue *cue = [[QLKCue alloc] initWithDictionary:@{ @"uniqueID": @"1" }];
      expect([workspace addressForCue:cue action:@"start"]).to.equal(@"/cue_id/1/start");
    });
    
    specify(@"workspacePrefix", ^{
      expect(workspace.workspacePrefix).to.equal(@"/workspace/ABC123");
    });
  });
});

SpecEnd