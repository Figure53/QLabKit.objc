//
//  QLKServer.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013 Figure 53 LLC, http://figure53.com
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
