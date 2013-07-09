//
//  QLRConnectionManager.h
//  QLab for iPad
//
//  Created by Zach Waugh on 3/23/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "F53OSC.h"
#import "QLKDefines.h"

extern NSString * const QLRServersUpdatedNotification;
extern NSString * const QLabServiceType;
extern NSString * const QLabServiceDomain;

@class QLRWorkspace;

@interface QLKBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, F53OSCPacketDestination>

@property (strong, nonatomic) NSNetServiceBrowser *browser;
@property (strong, nonatomic) NSMutableArray *servers;
@property (strong, nonatomic) F53OSCServer *server;
@property (strong, nonatomic) QLRWorkspace *activeWorkspace;
@property (copy) QLRWorkspaceHandlerBlock workspaceBlock;

+ (QLKBrowser *)sharedManager;
- (void)refreshWorkspaces;
- (void)startServers;
- (void)stopServers;

@end
