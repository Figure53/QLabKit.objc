//
//  QLKServer.m
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


#import "QLKServer.h"
#import "QLKWorkspace.h"
#import "QLKClient.h"

@interface QLKServer ()

@property (strong, nonatomic) QLKClient *client;

- (void) addWorkspace:(QLKWorkspace *)workspace;
- (void) removeWorkspace:(QLKWorkspace *)workspace;
- (void) removeAllWorkspaces;

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
    _workspaces = [[NSMutableArray alloc] init];
    _client = [[QLKClient alloc] initWithHost:host port:port];

    return self;
}

- (NSString *) description
{
  return [NSString stringWithFormat:@"%@ - %@ - %@:%ld", [super description], self.name, self.host, (long)self.port];
}

#pragma mark - Workspaces

- (void) refreshWorkspaces
{
    [self.client sendMessage:[F53OSCMessage messageWithAddressPattern:@"/workspaces" arguments:nil]];
}

- (void) refreshWorkspacesWithCompletion:(void (^)(NSArray *workspaces))block
{
    // Create TCP connection so we can receive the response
    self.client.useTCP = YES;
    if ( ![self.client connect] )
    {
        NSLog(@"[server] error connecting to server: %@:%ld", self.host, (long)self.port);
    }

    [self.client sendMessages:@[] toAddress:@"/workspaces" workspace:NO block:^(NSArray *data)
    {
        [self.client disconnect];
        self.client.useTCP = NO;

        [self updateWorkspaces:data];
        
        if ( block )
            block( self.workspaces );
    }];
}

- (void) updateWorkspaces:(NSArray *)workspaces
{
    [self removeAllWorkspaces];
  
    for ( NSDictionary *dict in workspaces )
    {
        QLKWorkspace *workspace = [[QLKWorkspace alloc] initWithDictionary:dict server:self];
        [self addWorkspace:workspace];
    }
}

- (void) addWorkspace:(QLKWorkspace *)workspace
{
    [self.workspaces addObject:workspace];
}

- (void) removeWorkspace:(QLKWorkspace *)workspace
{
    [self.workspaces removeObject:workspace];
}

- (void) removeAllWorkspaces
{
    [self.workspaces removeAllObjects];
}

@end
