//
//  QLKBrowserSpec.m
//  QLabKit
//
//  Created by Zach Waugh on 7/18/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKBrowser.h"
#import "QLKServer.h"

@interface QLKBrowser (Private)

@property (strong) NSMutableArray *services;
@property (strong) NSNetServiceBrowser *browser;
@property (strong) F53OSCServer *server;
@property (strong) NSTimer *refreshTimer;
@property (assign) BOOL running;

- (QLKServer *)serverForHost:(NSString *)host;

@end

SpecBegin(QLKBrowser)

describe(@"browser", ^{
  __block QLKBrowser *browser;
  
  beforeEach(^{
    browser = [[QLKBrowser alloc] init];
  });
  
  context(@"when created", ^{
    it(@"should not be nil", ^{
      expect(browser).toNot.beNil();
    });
    
    it(@"should have no services", ^{
      expect(browser.services).to.haveCountOf(0);
    });
    
    it(@"should not be running", ^{
      expect(browser.running).to.beFalsy();
    });
  });
  
  context(@"when started", ^{
    beforeEach(^{
      [browser start];
    });
    
    it(@"should be running", ^{
      expect(browser.running).to.beTruthy();
    });
    
    it(@"should have a browser", ^{
      expect(browser.browser).toNot.beNil();
    });
        
    it(@"should have an osc server", ^{
      expect(browser.server).toNot.beNil();
    });
  });
});

SpecEnd