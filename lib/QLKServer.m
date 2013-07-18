//
//  QLKServer.m
//  QLab for iPad
//
//  Created by Zach Waugh on 3/26/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import "QLKServer.h"
#import "QLKWorkspace.h"
#import "F53OSC.h"

@interface QLKServer ()

@property (strong, nonatomic) F53OSCClient *client;

@end

@implementation QLKServer

- (id)initWithHost:(NSString *)host port:(NSInteger)port
{
  self = [super init];
  if (!self) return nil;
  
  _host = host;
  _port = port;
  _workspaces = [[NSMutableArray alloc] init];
  
  _client = [[F53OSCClient alloc] init];
  _client.host = host;
  _client.port = port;
  
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ - %@ - %@:%ld", [super description], self.name, self.host, self.port];
}

#pragma mark - Workspaces

- (void)refreshWorkspaces
{
  [self.client sendPacket:[F53OSCMessage messageWithAddressPattern:@"/workspaces" arguments:nil]];
}

- (void)updateWorkspaces:(NSArray *)workspaces
{
  [self removeAllWorkspaces];
  
  for (NSDictionary *dict in workspaces) {
    QLKWorkspace *workspace = [[QLKWorkspace alloc] initWithDictionary:dict server:self];
    [self addWorkspace:workspace];
  }
}

- (void)addWorkspace:(QLKWorkspace *)workspace
{
  [self.workspaces addObject:workspace];
}

- (void)removeWorkspace:(QLKWorkspace *)workspace
{
  [self.workspaces removeObject:workspace];
}

- (void)removeAllWorkspaces
{
  [self.workspaces removeAllObjects];
}

@end
