//
//  QLKMessage.m
//  QLabKit
//
//  Created by Zach Waugh on 7/17/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKMessage.h"
#import "F53OSCMessage.h"

@interface QLKMessage ()

@property (strong) F53OSCMessage *OSCMessage;

- (NSArray *)addressParts;

@end

@implementation QLKMessage

+ (QLKMessage *)messageWithOSCMessage:(F53OSCMessage *)message
{
  return [[QLKMessage alloc] initWithOSCMessage:message];
}

- (id)initWithOSCMessage:(F53OSCMessage *)message
{
  self = [super init];
  if (!self) return nil;
  
  _OSCMessage = message;
  
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"address: %@, arguments: %@", self.address, [self.arguments componentsJoinedByString:@" - "]];
}

- (BOOL)isReply
{
  return [self.OSCMessage.addressPattern hasPrefix:@"/reply"];
}

- (BOOL)isUpdate
{
  return [self.OSCMessage.addressPattern hasPrefix:@"/update"];
}

- (BOOL)isWorkspaceUpdate
{
  // /update/workspace/{workspace_id}
  NSArray *parts = self.addressParts;
  
  return (parts.count == 4 && [parts[1] isEqualToString:@"workspace"]);
}

- (BOOL)isCueUpdate
{
  // /update/workspace/{workspace_id}/cue_id/{cue_id}
  NSArray *parts = self.addressParts;
  
  return (parts.count == 6 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"cue_id"]);
}

- (BOOL)isPlaybackPositionUpdate
{
  // /update/workspace/{workspace_id}/cueList/{cue_list_id}/playbackPosition {cue_id}
  NSArray *parts = self.addressParts;
  
  return (parts.count == 7 && [self.address hasSuffix:@"/playbackPosition"]);
}

- (BOOL)isDisconnect
{
  return [self.address hasSuffix:@"/disconnect"];
}

- (NSString *)cueID
{
  if ([self isCueUpdate]) {
    return self.addressParts[5];
  } else if ([self isPlaybackPositionUpdate]) {
    return self.arguments[0];
  } else {
    return nil;
  }
}

- (NSArray *)arguments
{
  return self.OSCMessage.arguments;
}

- (NSString *)address
{
  return self.OSCMessage.addressPattern;
}

- (NSString *)replyAddress
{
  return [self.address substringFromIndex:@"/reply".length];
}

- (NSString *)addressWithoutWorkspace:(NSString *)workspaceID
{
  NSString *workspacePrefix = [NSString stringWithFormat:@"/workspace/%@", workspaceID];
  NSString *address = self.replyAddress;
  
  if ([address hasPrefix:workspacePrefix]) {
    return [address substringFromIndex:workspacePrefix.length];
  } else {
    return address;
  }
}

- (NSArray *)addressParts
{
  return [self.address pathComponents];
}

- (NSString *)body
{
  return self.OSCMessage.arguments[0];
}

- (id)response
{
  NSString *body = self.body;
  NSError *error = nil;
  NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
  
  if (error) {
    NSLog(@"error decoding JSON: %@, %@", error, self.OSCMessage.arguments);
  }
  
  return dict[@"data"];
}

@end
