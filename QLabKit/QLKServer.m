//
//  QLRServer.m
//  QLab for iPad
//
//  Created by Zach Waugh on 3/26/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import "QLKServer.h"
#import "F53OSCClient.h"

@implementation QLKServer

- (id)init
{
  self = [super init];
  if (!self) return nil;
  
  _workspaces = [[NSMutableArray alloc] init];
  
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ - %@ - %@", [super description], self.name, self.ip];
}

#pragma mark - 

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
