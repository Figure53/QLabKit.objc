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
  it(@"should not have a nil name", ^{
    QLKServer *server = [[QLKServer alloc] initWithHost:nil port:0];
    expect(server.name).toNot.beNil();
  });
});

SpecEnd