//
//  QLKBrowser.h
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
#import "QLKDefines.h"

@class QLKBrowser, QLKServer;


@protocol QLKBrowserDelegate <NSObject>

// A server was added or removed.
- (void) browserDidUpdateServers:(QLKBrowser *)browser;

// A server updated its workspaces.
- (void) serverDidUpdateWorkspaces:(QLKServer *)server;

@end


@interface QLKBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

// delegate object implementing QLKBrowserDelegate protocol
@property (unsafe_unretained, nonatomic) id<QLKBrowserDelegate> delegate;

// array of QLKServer objects
@property (strong, nonatomic) NSMutableArray *servers;

// Start server discovery.
- (void) start;

// Stop server discovery.
- (void) stop;

// Refresh list of workspaces on all servers.
- (void) refreshAllWorkspaces;

// Continuously poll workspaces of all servers with given interval (in seconds).
- (void) enableAutoRefreshWithInterval:(NSTimeInterval)interval;

// Stop auto refresh of workspaces.
- (void) disableAutoRefresh;

@end
