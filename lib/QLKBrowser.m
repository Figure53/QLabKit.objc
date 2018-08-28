//
//  QLKBrowser.m
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

#import "QLKBrowser.h"

#import "QLKWorkspace.h"
#include <netinet/in.h>
#include <arpa/inet.h>


#ifndef RELEASE
#define DEBUG_BROWSER 1
#endif


NS_ASSUME_NONNULL_BEGIN

@interface QLKBrowser ()

@property (assign, readwrite)                   BOOL running;
@property (nonatomic, strong, nullable)         NSNetServiceBrowser *netServiceDomainsBrowser;
@property (nonatomic, strong, nullable)         NSNetServiceBrowser *netServiceTCPBrowser;
@property (nonatomic, strong, nullable)         NSTimer *refreshTimer;
@property (nonatomic, strong)                   NSMutableArray<QLKServer *> *mutableServers;

@property (nonatomic, strong)                   NSMutableArray<NSNetService *> *netServices;

- (void) _refreshAllWorkspaces:(nullable NSTimer *)theTimer;

- (void) setNeedsNotifyDelegateBrowserDidUpdateServers;
- (void) notifyDelegateBrowserDidUpdateServers;
- (void) setNeedsBeginResolvingNetServices;
- (void) beginResolvingNetServices;

- (nullable QLKServer *) serverForHost:(NSString *)host;
- (nullable QLKServer *) serverForNetService:(NSNetService *)netService;

@end


@implementation QLKBrowser

- (instancetype) init
{
    self = [super init];
    if ( self )
    {
        self.running = NO;
        self.netServiceTCPBrowser = nil;
        
        self.refreshTimer = nil;
        
        self.netServices = [NSMutableArray arrayWithCapacity:0];
        self.mutableServers = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

- (void) dealloc
{
    [self stop];
}



#pragma mark - custom getters setters

- (NSArray<QLKServer *> *) servers
{
    return [NSArray arrayWithArray:self.mutableServers];
}



#pragma mark -

- (void) start
{
#if DEBUG_BROWSER
    if ( self.running )
        NSLog( @"[browser] starting browser - already running" );
    else
        NSLog( @"[browser] starting browser" );
#endif
    
    if ( self.running )
        return;
    
    // Create Bonjour browser to find available domains
    self.netServiceDomainsBrowser = [[NSNetServiceBrowser alloc] init];
    self.netServiceDomainsBrowser.delegate = self;
    
    [self.netServiceDomainsBrowser searchForBrowsableDomains];
}

- (void) stop
{
#if DEBUG_BROWSER
    NSLog( @"[browser] stopping browser" );
#endif
    
    [self disableAutoRefresh];
    
    self.delegate = nil;
    
    // Stop bonjour browsers - delegate methods will perform cleanup
    [self.netServiceDomainsBrowser stop];
    [self.netServiceTCPBrowser stop];
    
    // Stop/remove all servers
    for ( QLKServer *aServer in self.servers )
    {
        [aServer stop];
        aServer.delegate = nil;
        aServer.netService = nil;
    }
    [self.mutableServers removeAllObjects];
}

- (void) refreshAllWorkspaces
{
    [self _refreshAllWorkspaces:nil];
}

- (void) _refreshAllWorkspaces:(nullable NSTimer *)theTimer
{
    // Exit if method is being called by a timer and the timer has been cancelled
    if ( theTimer && ( !self.refreshTimer || !theTimer.isValid ) )
        return;
    
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
                                                           selector:@selector(_refreshAllWorkspaces:)
                                                           userInfo:nil
                                                            repeats:YES];
        self.refreshTimer.tolerance = ( interval * 0.1 );
    }
}

- (void) disableAutoRefresh
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}



#pragma mark - private

- (void) setNeedsNotifyDelegateBrowserDidUpdateServers
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyDelegateBrowserDidUpdateServers) object:nil];
    [self performSelector:@selector(notifyDelegateBrowserDidUpdateServers) withObject:nil afterDelay:0.5];
}

- (void) notifyDelegateBrowserDidUpdateServers
{
    [self.delegate browserDidUpdateServers:self];
}

- (void) setNeedsBeginResolvingNetServices
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginResolvingNetServices) object:nil];
    [self performSelector:@selector(beginResolvingNetServices) withObject:nil afterDelay:0.5];
}

- (void) beginResolvingNetServices
{
    // NOTE: if resolveWithTimeout: resolves immediately, netServiceDidResolveAddress: will mutate the `netServices` array
    // - so here we must enumerate a copy of that collection to avoid a crash
    NSArray<NSNetService *> *netServices = [self.netServices copy];
    for ( NSNetService *aService in netServices )
    {
        if ( aService.addresses.count )
            continue;
        
        [aService resolveWithTimeout:5.0];
    }
}



#pragma mark -

- (nullable QLKServer *) serverForHost:(NSString *)host
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

- (nullable QLKServer *) serverForNetService:(NSNetService *)netService
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



#pragma mark - QLKServerDelegate

- (void) serverDidUpdateWorkspaces:(QLKServer *)server
{
    if ( !self.delegate )
        return;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async( dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        [strongSelf.delegate browserServerDidUpdateWorkspaces:server];
        
    });
}

- (void) serverDidUpdateHostVersion:(QLKServer *)server
{
    if ( !self.delegate )
        return;
    
    if ( [self.delegate respondsToSelector:@selector(browserServerDidUpdateHostVersion:)] == NO )
        return;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async( dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        [strongSelf.delegate browserServerDidUpdateHostVersion:server];
        
    });
}



#pragma mark - NSNetServiceBrowserDelegate

- (void) netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
#if DEBUG_BROWSER
    if ( browser == self.netServiceDomainsBrowser )
        NSLog( @"[browser] starting bonjour - browsable domains search" );
    else if ( browser == self.netServiceTCPBrowser )
        NSLog( @"[browser] starting bonjour (TCP) - \"%@\"", QLKBonjourServiceDomain );
    else
        NSLog( @"[browser] netServiceBrowserWillSearch: %@", browser );
#endif
    
    if ( browser == self.netServiceDomainsBrowser )
        self.running = YES;
    
    [self.delegate browserDidUpdateServers:self];
}

- (void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
#if DEBUG_BROWSER
    if ( browser == self.netServiceDomainsBrowser )
        NSLog( @"[browser] stopping bonjour - browsable domains search" );
    else if ( browser == self.netServiceTCPBrowser )
        NSLog( @"[browser] stopping bonjour (TCP) - \"%@\"", QLKBonjourServiceDomain );
    else
        NSLog( @"[browser] netServiceBrowserDidStopSearch: %@", browser );
#endif
    
    if ( browser == self.netServiceDomainsBrowser )
    {
        self.running = NO;
        
        self.netServiceDomainsBrowser.delegate = nil;
        self.netServiceDomainsBrowser = nil;
    }
    else if ( browser == self.netServiceTCPBrowser )
    {
        self.netServiceTCPBrowser.delegate = nil;
        self.netServiceTCPBrowser = nil;
    }
    
    [self.delegate browserDidUpdateServers:self];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
#if DEBUG_BROWSER
    NSLog( @"[browser] netServiceBrowser:didNotSearch:" );
    for ( NSString *aError in errorDict )
    {
        NSLog( @"[browser] search error %@: %@, ", (NSNumber *)errorDict[aError], aError );
    }
#endif
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
#if DEBUG_BROWSER
    NSLog( @"[browser] netServiceBrowser:didFindDomain: \"%@\" moreComing: %@", domainString, ( moreComing ? @"YES" : @"NO" ) );
#endif
    
    if ( !self.netServiceTCPBrowser && [domainString isEqualToString:QLKBonjourServiceDomain] )
    {
        self.netServiceTCPBrowser = [[NSNetServiceBrowser alloc] init];
        self.netServiceTCPBrowser.delegate = self;
        
        [self.netServiceTCPBrowser searchForServicesOfType:QLKBonjourTCPServiceType inDomain:QLKBonjourServiceDomain];
    }
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
#if DEBUG_BROWSER
    NSLog( @"[browser] netServiceBrowser:didFindService: \"%@\" moreComing: %@", netService, ( moreComing ? @"YES" : @"NO" ) );
#endif
    
    netService.delegate = self;
    [self.netServices addObject:netService];
    
    // multiple calls cancel previous requests to ensure service resolving only begins once (i.e. if moreComing == YES)
    [self setNeedsBeginResolvingNetServices];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
#if DEBUG_BROWSER
    NSLog( @"[browser] netServiceBrowser:didRemoveService: %@ moreComing: %@", netService, ( moreComing ? @"YES" : @"NO" ) );
#endif
    
    QLKServer *server = [self serverForNetService:netService];
    if ( !server )
        return;
    
    [server stop];
    server.delegate = nil;
    server.netService = nil;
    [self.mutableServers removeObject:server];
    
    // multiple calls cancel previous requests to ensure delegate is only notified once (i.e. if moreComing == YES)
    [self setNeedsNotifyDelegateBrowserDidUpdateServers];
}



#pragma mark - NSNetServiceDelegate

- (void) netServiceDidResolveAddress:(NSNetService *)netService
{
#if DEBUG_BROWSER
    NSLog( @"[browser] netServiceDidResolveAddress: %@", netService );
#endif
    NSInteger port = netService.port;
    if ( port < 0 ) // -1 = not resolved
        return;
    
    NSString *host = netService.hostName;
    
    // Fallback on IP only if we do not have a hostName to use
    // This may never happen though, since the docs seem to say that hostName and addresses both become non-nil at the same time
    if ( !host || host.length == 0 )
    {
        for ( NSData *address in netService.addresses )
        {
            host = [self IPAddressFromData:address];
            if ( host )
                break;
        }
        
        if ( !host )
        {
            // This should never happen - we just resolved an address
            // Only possible if somehow there were no addresses
            return;
        }
    }
    
    QLKServer *server = [[QLKServer alloc] initWithHost:host port:port];
    server.name = netService.name;
    server.delegate = self;
    server.netService = netService;
    
    // Once resolved, we can remove the net service from our local records.
    // (The QLKServer will still hold on to it, though.)
    netService.delegate = nil;
    [self.netServices removeObject:netService];
    
#if DEBUG_BROWSER
    NSLog( @"[browser] adding server: %@", server );
#endif
    
    [self.mutableServers addObject:server];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async( dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        [strongSelf.delegate browserDidUpdateServers:strongSelf];
        
    });
    
    [server refreshWorkspaces];
}

- (void) netService:(NSNetService *)netService didNotResolve:(NSDictionary<NSString *, NSNumber *> *)error
{
    [netService stop];
    netService.delegate = nil;
    [self.netServices removeObject:netService];
    
    NSLog( @"[browser] Error: Failed to resolve service: %@ - %@", netService, error );
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

NS_ASSUME_NONNULL_END
