//
//  QLKServer.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2014 Figure 53 LLC, http://figure53.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "QLKDefines.h"
#import "F53OSC.h"

@class F53OSCClient, QLKBrowser, QLKServer, QLKWorkspace;


@protocol QLKServerDelegate <NSObject>

// A server updated its workspaces.
- (void) serverDidUpdateWorkspaces:(QLKServer *)server;

@end


@interface QLKServer : NSObject

// Create a server with the host and port to connect.
// Host should almost always be either @"localhost" or IP address, e.g. @"10.0.1.1".
// Pass in port 0 to use default port (53000).
- (id) initWithHost:(NSString *)host port:(NSInteger)port;

// delegate object implementing QLKServerDelegate protocol
@property (unsafe_unretained, nonatomic) id<QLKServerDelegate> delegate;

// Host address of the server.
@property (strong, nonatomic, readonly) NSString *host;

// Port to connect to on the server, 53000 by default.
@property (assign, nonatomic, readonly) NSInteger port;

// Name of the machine running QLab.
@property (strong, nonatomic) NSString *name;

// The browser that owns this server (if any). You probably don't need this.
@property (weak, nonatomic) QLKBrowser *browser;

// The netservice used to discover this server (if any). You probably don't need this.
@property (strong, nonatomic) NSNetService *netService;

// Array of QLKWorkspace objects that belong to this server.
@property (strong, nonatomic, readonly) NSMutableArray *workspaces;

- (void) refreshWorkspaces;
- (void) refreshWorkspacesWithCompletion:(void (^)(NSArray *workspaces))block;
- (void) enableAutoRefreshWithInterval:(NSTimeInterval)interval;
- (void) disableAutoRefresh;
- (BOOL) isConnected;

- (void) sendOscMessage:(F53OSCMessage *)message;
- (void) sendOscMessage:(F53OSCMessage *)message block:(QLKMessageHandlerBlock)block;

@end
