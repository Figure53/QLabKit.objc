//
//  QLKBrowser.m
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

#import "QLKBrowser.h"
#import "QLKServer.h"
#import "QLKWorkspace.h"
#include <netinet/in.h>
#include <arpa/inet.h>

#define DEBUG_BROWSER 0


@interface QLKBrowser ()

@property (assign) BOOL running;
@property (strong) NSNetServiceBrowser *browser;
@property (strong) NSMutableArray *services;
@property (strong) NSTimer *refreshTimer;

- (QLKServer *) serverForHost:(NSString *)host;
- (QLKServer *) serverForNetService:(NSNetService *)netService;
- (void) serverDidUpdateWorkspaces:(QLKServer *)server;

@end


@implementation QLKBrowser

- (id) init
{
    self = [super init];
    if ( !self )
        return nil;
    
    _running = NO;
    _browser = nil;
    _services = [[NSMutableArray alloc] init];
    _refreshTimer = nil;
    _servers = [[NSMutableArray alloc] init];
    
    return self;
}

- (void) dealloc
{
    [self disableAutoRefresh];
    [self.browser stop];
}

- (void) start
{
    if ( self.running )
        return;
    
    self.running = YES;
    
#if DEBUG_BROWSER
    NSLog( @"[browser] starting bonjour" );
#endif
    
    // Create Bonjour browser to find QLab instances.
    self.browser = [[NSNetServiceBrowser alloc] init];
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:QLKBonjourTCPServiceType inDomain:QLKBonjourServiceDomain];
}

- (void) stop
{
#if DEBUG_BROWSER
    NSLog( @"[browser] stopping bonjour" );
#endif
    
    // Stop bonjour
    [self.browser stop];
    self.browser = nil;
    
    // Remove all servers.
    [self.servers removeAllObjects];
    
    self.running = NO;
}

- (void) refreshAllWorkspaces
{
    for ( QLKServer *server in self.servers )
    {
        [server refreshWorkspaces];
    }
}

- (void) enableAutoRefreshWithInterval:(NSTimeInterval)interval
{
    if ( !self.refreshTimer )
    {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector( refreshAllWorkspaces )
                                                           userInfo:nil
                                                            repeats:YES];
    }
}

- (void) disableAutoRefresh
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark -

- (QLKServer *) serverForHost:(NSString *)host
{
    for ( QLKServer *server in self.servers )
    {
        if ( [server.host isEqualToString:host] )
        {
            return server;
        }
    }

    return nil;
}

- (QLKServer *) serverForNetService:(NSNetService *)netService
{
    for ( QLKServer *server in self.servers )
    {
        if ( [server.netService isEqual:netService] )
        {
            return server;
        }
    }

    return nil;
}

- (void) serverDidUpdateWorkspaces:(QLKServer *)server
{
    dispatch_async( dispatch_get_main_queue(), ^
    {
        [self.delegate serverDidUpdateWorkspaces:server];
    });
}

#pragma mark - NSNetServiceBrowserDelegate

- (void) netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
#if DEBUG_BROWSER
    NSLog( @"netServiceBrowser:didFindService: %@", netService );
#endif
    
    [self.services addObject:netService];
    [netService setDelegate:self];
    [netService resolveWithTimeout:5.0f];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
#if DEBUG_BROWSER
    NSLog( @"netServiceBrowser:didRemoveService: %@", netService );
#endif
    
    QLKServer *server = [self serverForNetService:netService];
    [self.servers removeObject:server];
    
    dispatch_async( dispatch_get_main_queue(), ^
    {
        [self.delegate browserDidUpdateServers:self];
    });
}

#pragma mark - NSNetServiceDelegate

- (void) netServiceDidResolveAddress:(NSNetService *)netService
{
#if DEBUG_BROWSER
    NSLog( @"netServiceDidResolveAddress: %@", netService );
#endif
    
    NSString *ip = [self IPAddressFromData:netService.addresses[0]];
    NSInteger port = netService.port;
    QLKServer *server = [[QLKServer alloc] initWithHost:ip port:port];
    server.name = netService.name;
    server.browser = self;
    server.netService = netService;
    
    // Once resolved, we can remove the net service from our local records.
    // (The QLKServer will still hold on to it, though.)
    [self.services removeObject:netService];
    
#if DEBUG_BROWSER
    NSLog( @"[browser] adding server: %@", server );
#endif
    
    [self.servers addObject:server];
    
    dispatch_async( dispatch_get_main_queue(), ^
    {
        [self.delegate browserDidUpdateServers:self];
    });
    
    [server refreshWorkspaces];
}

- (void) netService:(NSNetService *)netService didNotResolve:(NSDictionary *)error
{
    NSLog( @"Error: Failed to resolve service: %@ - %@", netService, error );
}

#pragma mark -

- (NSString *) IPAddressFromData:(NSData *)data
{
    // Taken from Apple sample project - CocoaSoap.
    
    NSString *ip = @"0.0.0.0";
    struct sockaddr_in *address_sin = (struct sockaddr_in *)data.bytes;
    const char *formatted;
    char buffer[1024];
    if ( AF_INET == address_sin->sin_family )
    {
        formatted = inet_ntop( AF_INET, &(address_sin->sin_addr), buffer, sizeof( buffer ) );
        ip = [NSString stringWithFormat:@"%s", formatted];
    }
    
    return ip;
}

@end
