//
//  QLKClient.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKClient.h"
#import "F53OSC.h"
#import "QLKDefines.h"

@interface QLKClient ()

@property (strong) F53OSCClient *oscClient;
@property (strong) NSMutableDictionary *callbacks;

@end

@implementation QLKClient

- (id)init
{
  self = [super init];
  if (!self) return nil;
  
  _callbacks = [[NSMutableDictionary alloc] init];
  
  return self;
}

- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address
{
  [self sendMessage:message toAddress:address block:nil];
}

- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address block:(QLRMessageHandlerBlock)block
{
  NSArray *messages = (message != nil) ? @[message] : nil;
  [self sendMessages:messages toAddress:address block:block];
}

- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address
{
  [self sendMessages:messages toAddress:address block:nil];
}

- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address block:(QLRMessageHandlerBlock)block
{
  if (block) {
    self.callbacks[address] = block;
  }
  
  // FIXME: need to use workspace prefix
  NSString *fullAddress = address; //[NSString stringWithFormat:@"%@%@", [self workspacePrefix], address];
  
#if DEBUG_OSC
  NSLog(@"[OSC ->] to: %@, data: %@", fullAddress, messages);
#endif
  
  F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:fullAddress arguments:messages];
  [self.oscClient sendPacket:message];
}

@end
