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
