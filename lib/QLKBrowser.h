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

// Servers were updated, a server may have been added or removed, or may have updated its workspaces
- (void)browserDidUpdateServers:(QLKBrowser *)browser;

@end

@interface QLKBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, F53OSCPacketDestination>

// array of QLKServer objects
@property (strong, nonatomic) NSMutableArray *servers;

// delegate object implementing QLKBrowserDelegate protocol
@property (unsafe_unretained, nonatomic) id<QLKBrowserDelegate> delegate;

- (void)refreshWorkspaces;

// Start discovery
- (void)start;

// Stop discovery
- (void)stop;

// Continuously poll workspaces of all servers with given interval (in seconds)
- (void)enableAutoRefreshWithInterval:(NSTimeInterval)interval;

// Stop auto refresh
- (void)disableAutoRefresh;

@end
