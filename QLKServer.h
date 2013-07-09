//
//  QLRServer.h
//  QLab for iPad
//
//  Created by Zach Waugh on 3/26/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>

@class F53OSCClient, QLKWorkspace;

@interface QLKServer : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *ip;
@property (strong, nonatomic) NSNetService *netService;
@property (strong, nonatomic) F53OSCClient *client;
@property (strong, nonatomic) NSMutableArray *workspaces;

- (void)addWorkspace:(QLKWorkspace *)workspace;
- (void)removeWorkspace:(QLKWorkspace *)workspace;
- (void)removeAllWorkspaces;

@end
