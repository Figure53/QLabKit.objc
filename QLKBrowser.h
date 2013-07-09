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

@class QLKWorkspace, QLKBrowser;

@protocol QLKBrowserDelegate <NSObject>

- (void)browserDidUpdateServers:(QLKBrowser *)browser;

@end

@interface QLKBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, F53OSCPacketDestination>

@property (strong, nonatomic) NSNetServiceBrowser *browser;
@property (strong, nonatomic) NSMutableArray *servers;
@property (copy) QLRWorkspaceHandlerBlock workspaceBlock;
@property (unsafe_unretained) id<QLKBrowserDelegate> delegate;

+ (QLKBrowser *)sharedManager;
- (void)refreshWorkspaces;
- (void)startServers;
- (void)stopServers;

@end
