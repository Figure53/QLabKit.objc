//
//  QLKServer.m
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


#import "QLKServer.h"
#import "QLKBrowser.h"
#import "QLKClient.h"
#import "QLKMessage.h"
#import "QLKWorkspace.h"


@interface QLKBrowser (QLKServerAccess)

- (void) serverDidUpdateWorkspaces:(QLKServer *)server;

@end


@interface QLKServer ()

@property (strong, nonatomic) QLKClient *client;
@property (strong) NSTimer *refreshTimer;

- (void) updateWorkspaces:(NSArray *)workspaces;

@end

@implementation QLKServer

- (id) initWithHost:(NSString *)host port:(NSInteger)port
{
    self = [super init];
    if ( !self )
        return nil;
    
    if ( port == 0 )
        port = 53000;

    _host = host;
    _port = port;
    _name = host;
    _browser = nil;
    _netService = nil;
    _workspaces = [[NSMutableArray alloc] init];
    
    // Create a private client that we'll use for querying the list of workspaces on the QLab server.
    // (Usually these clients are associated with a specific workspace, but not in this case.)
    self.client = [[QLKClient alloc] initWithHost:host port:port];
    self.client.useTCP = YES;

    return self;
}

- (void) dealloc
{
    [self disableAutoRefresh];
    [self.client disconnect];
    [self.workspaces removeAllObjects];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ - %@ - %@:%ld", [super description], self.name, self.host, (long)self.port];
}

- (BOOL) isConnected
{
    return ([self.client isConnected]);
}

#pragma mark - Workspaces

- (void) updateWorkspaces:(NSArray *)workspaces
{
    [self.workspaces removeAllObjects];
    
    for ( NSDictionary *dict in workspaces )
    {
        QLKWorkspace *workspace = [[QLKWorkspace alloc] initWithDictionary:dict server:self];
        [self.workspaces addObject:workspace];
    }
    
    [self.browser serverDidUpdateWorkspaces:self];
    [self.delegate serverDidUpdateWorkspaces:self];
}

- (void) refreshWorkspaces
{
    if ( !self.client.isConnected )
    {
        if ( ![self.client connect] )
        {
            NSLog( @"Error: QLKServer unable to connect to QLab server: %@:%ld", self.host, (long)self.port );
            return;
        }
    }
    
    [self.client sendMessagesWithArguments:nil toAddress:@"/workspaces" workspace:NO block:^(NSArray *data)
    {
        [self updateWorkspaces:data];
    }];
}

- (void) refreshWorkspacesWithCompletion:(void (^)(NSArray *workspaces))block
{
    if ( !self.client.isConnected )
    {
        if ( ![self.client connect] )
        {
            NSLog( @"Error: QLKServer unable to connect to QLab server: %@:%ld", self.host, (long)self.port );
            return;
        }
    }

    [self.client sendMessagesWithArguments:nil toAddress:@"/workspaces" workspace:NO block:^(NSArray *data)
    {
        [self updateWorkspaces:data];
        
        if ( block )
            block( self.workspaces );
    }];
}

- (void) enableAutoRefreshWithInterval:(NSTimeInterval)interval
{
    if ( !self.refreshTimer )
    {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector( refreshWorkspaces )
                                                           userInfo:nil
                                                            repeats:YES];
    }
}

- (void) disableAutoRefresh
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void) sendOscMessage:(F53OSCMessage *)message
{
    [self sendOscMessage:message block:nil];
}

- (void) sendOscMessage:(F53OSCMessage *)message block:(QLKMessageHandlerBlock)block
{
    [self.client sendOscMessage:message block:block];
}

@end
