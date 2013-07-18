//
//  QLKServerSpec.m
//  QLabKit
//
//  Created by Zach Waugh on 7/18/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKServer.h"

SpecBegin(QLKServer)

describe(@"server", ^{
  __block QLKServer *server;
  
  beforeEach(^{
    server = [[QLKServer alloc] initWithHost:@"host" port:53000];
  });
  
  context(@"when created", ^{
    it(@"should not have a nil name", ^{
      expect(server.name).toNot.beNil();
    });
    
    it(@"should have a host name", ^{
      expect(server.host).to.equal(@"host");
    });
    
    it(@"should have a port", ^{
      expect(server.port).to.equal(53000);
    });
  });
  
  context(@"workspaces", ^{
    it(@"should have 0 workspaces", ^{
      expect(server.workspaces).to.haveCountOf(0);
    });
    
    it(@"should have 1 workspace", ^{
      [server addWorkspace:(QLKWorkspace *)@""];
      expect(server.workspaces).to.haveCountOf(1);
    });
  });
});

SpecEnd