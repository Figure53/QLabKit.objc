//
//  QLKServer.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2018 Figure 53 LLC, http://figure53.com
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

@import Foundation;

#import "QLKDefines.h"
#import "F53OSC.h"


NS_ASSUME_NONNULL_BEGIN

@class F53OSCClient, QLKBrowser, QLKServer, QLKClient, QLKWorkspace;
@protocol QLKServerDelegate;


@interface QLKServer : NSObject

// Create a server with the host and port to connect.
// Host should almost always be either @"localhost" or IP address, e.g. @"10.0.1.1".
// Pass in port 0 to use default port (53000).
- (instancetype) initWithHost:(NSString *)host port:(NSInteger)port;

// Create a server with the host, port, and custom QLKClient instance to connect.
- (instancetype) initWithHost:(NSString *)host port:(NSInteger)port client:(QLKClient *)client;

@property (nonatomic, weak, nullable)               id<QLKServerDelegate> delegate;

// Host address of the server.
@property (nonatomic, strong, readonly)             NSString *host;

// Port to connect to on the server, 53000 by default.
@property (nonatomic, readonly)                     NSInteger port;

// Name of the machine running QLab.
@property (nonatomic, strong)                       NSString *name;

// The netservice used to discover this server (if any). You probably don't need this.
@property (nonatomic, strong, nullable)             NSNetService *netService;

// The app version of the connected host, i.e. the value returned by OSC command "/version".
@property (nonatomic, strong, readonly, nullable)   NSString *hostVersion;

// Array of QLKWorkspace objects that belong to this server.
@property (nonatomic, copy, readonly)               NSArray<QLKWorkspace *> *workspaces;

@property (nonatomic, strong, readonly)             QLKClient *client;

@property (nonatomic, getter=isConnected, readonly) BOOL connected;

- (nullable QLKWorkspace *) workspaceWithID:(NSString *)uniqueID;
- (QLKWorkspace *) newWorkspaceWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict; // subclasses can override to customize QLKWorkspace created if desired

- (void) refreshWorkspaces;
- (void) refreshWorkspacesWithCompletion:(nullable void (^)(NSArray<QLKWorkspace *> *workspaces))completion;
- (void) enableAutoRefreshWithInterval:(NSTimeInterval)interval;
- (void) disableAutoRefresh;
- (void) stop;

- (void) sendOscMessage:(F53OSCMessage *)message;
- (void) sendOscMessage:(F53OSCMessage *)message block:(nullable QLKMessageHandlerBlock)block;

@end


@protocol QLKServerDelegate <NSObject>

// A server updated its workspaces.
- (void) serverDidUpdateWorkspaces:(QLKServer *)server;

@optional
- (void) serverDidUpdateHostVersion:(QLKServer *)server;

@end


@interface QLKServer (DisallowedInits)

- (instancetype) init  __attribute__((unavailable("Use -initWithHost:port:client: or -initWithHost:port:")));

@end

NS_ASSUME_NONNULL_END
