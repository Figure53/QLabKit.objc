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
@property (copy, atomic) NSArray<QLKServer *> *servers;

- (QLKServer *) serverForHost:(NSString *)host;
- (QLKServer *) serverForNetService:(NSNetService *)netService;
- (void) serverDidUpdateWorkspaces:(QLKServer *)server;

@end


@implementation QLKBrowser

- (instancetype) init
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
    self.browser.delegate = self;
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
    self.servers = @[];
    
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
    netService.delegate = self;
    [netService resolveWithTimeout:5.0f];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
#if DEBUG_BROWSER
    NSLog( @"netServiceBrowser:didRemoveService: %@", netService );
#endif
    
    QLKServer *server = [self serverForNetService:netService];
	
	NSMutableArray *mutableServers = [self.servers mutableCopy];
    [mutableServers removeObject:server];
	self.servers = mutableServers;
    
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
    
    NSString *ip = nil;
    
    for ( NSData *address in netService.addresses )
    {
        ip = [self IPAddressFromData:address];
        if ( ip )
            break;
    }
    
    if ( !ip )
    {
        // This should never happen - we just resolved an address
        // Only possible if somehow there were no addresses
        return;
    }
    
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
    
    self.servers = [self.servers arrayByAddingObject:server];
    
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

- (nullable NSString *) IPAddressFromData:(NSData *)data
{
    typedef union {
        struct sockaddr sa;
        struct sockaddr_in ipv4;
        struct sockaddr_in6 ipv6;
    } ip_socket_address;
    
    ip_socket_address *socketAddress = (ip_socket_address *)data.bytes;
    
    if ( socketAddress && ( AF_INET == socketAddress->sa.sa_family || AF_INET6 == socketAddress->sa.sa_family ) )
    {
        char buffer[INET6_ADDRSTRLEN];
        memset( buffer, 0, INET6_ADDRSTRLEN );
        
        const char *formatted = inet_ntop( socketAddress->sa.sa_family,
                                          (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                          buffer, sizeof( buffer ) );
        return [NSString stringWithFormat:@"%s", formatted];
    }
    else
    {
        return nil;
    }
}

@end
