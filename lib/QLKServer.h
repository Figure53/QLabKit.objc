//
//  QLKServer.h
//  QLab for iPad
//
//  Created by Zach Waugh on 3/26/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>

@class F53OSCClient, QLKWorkspace;

@interface QLKServer : NSObject

// Name of the machine running QLab
@property (strong, nonatomic) NSString *name;

// Host should almost always be IP address, i.e. @"10.0.1.1"
@property (strong, nonatomic) NSString *host;

// Port to connect to on the server, 53000 by default
@property (assign, nonatomic) NSInteger port;

// The netservice used to discover this server (you don't have to worry about this)
@property (strong, nonatomic) NSNetService *netService;

// Array of QLKWorkspace objects that belong to this server
@property (strong, nonatomic) NSMutableArray *workspaces;

// Create a server with the host and port to connect
- (id)initWithHost:(NSString *)host port:(NSInteger)port;

// Send a message to this server to update the list of workspaces
- (void)refreshWorkspaces;

// Update the server
- (void)updateWorkspaces:(NSArray *)workspaces;

// Add a workspace to the 
- (void)addWorkspace:(QLKWorkspace *)workspace;
- (void)removeWorkspace:(QLKWorkspace *)workspace;
- (void)removeAllWorkspaces;

@end
