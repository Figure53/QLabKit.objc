//
//  QLKConnectionManager.h
//  QLab for iPad
//
//  Created by Zach Waugh on 3/23/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "F53OSC.h"
#import "QLKDefines.h"

@class QLKWorkspace, QLKBrowser;

@protocol QLKBrowserDelegate <NSObject>

- (void)browserDidUpdateServers:(QLKBrowser *)browser;

@end

@interface QLKBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, F53OSCPacketDestination>

@property (strong, nonatomic) NSMutableArray *servers;
@property (copy, nonatomic) QLKWorkspaceHandlerBlock workspaceBlock;
@property (unsafe_unretained, nonatomic) id<QLKBrowserDelegate> delegate;

- (void)refreshWorkspaces;
- (void)start;
- (void)stop;

// Auto refresh workspaces of all servers with given interval (in seconds)
- (void)enableAutoRefreshWithInterval:(NSTimeInterval)interval;
- (void)disableAutoRefresh;

@end
