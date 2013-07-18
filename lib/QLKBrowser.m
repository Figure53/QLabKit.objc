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
#import "QLKWorkspace.h"
#import "QLKServer.h"
#include <netinet/in.h>
#include <arpa/inet.h>

#define DEBUG_OSC 0
#define UDP_SERVER_PORT 53001

@interface QLKBrowser ()

@property (strong) NSMutableArray *services;
@property (strong) NSNetServiceBrowser *browser;
@property (strong) F53OSCServer *server;
@property (strong) NSTimer *refreshTimer;
@property (assign) BOOL running;

- (QLKServer *)serverForHost:(NSString *)host;

@end

@implementation QLKBrowser

- (void)dealloc
{
  [self disableAutoRefresh];
  [self.server stopListening];
  [self.browser stop];
}

- (id)init
{
  self = [super init];
  if (!self) return nil;
  
  _running = NO;
  _servers = [[NSMutableArray alloc] init];
  _services = [[NSMutableArray alloc] init];
  
  return self;
}

- (void)enableAutoRefreshWithInterval:(NSTimeInterval)interval
{
  if (!self.refreshTimer && self.running) {
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshWorkspaces) userInfo:nil repeats:YES];
  }
}

- (void)disableAutoRefresh
{
  [self.refreshTimer invalidate];
  self.refreshTimer = nil;
}

// Manually refresh all workspaces
- (void)refreshWorkspaces
{
  for (QLKServer *server in self.servers) {
    [server refreshWorkspaces];
  }
}

- (void)start
{
  if (self.running) return;
  
  self.running = YES;
  
  // OSC server to receive workspaces from QLab instances
  if (!self.server) {
    self.server = [[F53OSCServer alloc] init];
    self.server.port = UDP_SERVER_PORT;
    self.server.delegate = self;
  }
  
  [self.server startListening];
  
  // Bonjour browser to find QLab instances
  self.browser = [[NSNetServiceBrowser alloc] init];
  [self.browser setDelegate:self];
  [self.browser searchForServicesOfType:QLKBonjourUDPServiceType inDomain:QLKBonjourServiceDomain];
}

- (void)stop
{
  NSLog(@"stop listening for servers...");
  self.running = NO;

  // Remove all servers and stop OSC server
  [self.servers removeAllObjects];
  [self.server stopListening];
  self.server = nil;

  // Stop bonjour
  [self.browser stop];
  self.browser = nil;
}

- (QLKServer *)serverForHost:(NSString *)host
{
  for (QLKServer *server in self.servers) {
    if ([server.host isEqualToString:host]) {
      return server;
    }
  }
  
  return nil;
}

- (QLKServer *)serverForNetService:(NSNetService *)netService
{
  for (QLKServer *server in self.servers) {
    if ([server.netService isEqual:netService]) {
      return server;
    }
  }
  
  return nil;
}

#pragma mark - OSC server delegate

- (void)takeMessage:(F53OSCMessage *)message
{
  NSString *host = message.replySocket.host;

#if DEBUG_OSC
  NSLog(@"[OSC/UDP %@] message received - address: %@, arguments: %@", host, message.addressPattern, message.arguments);
#endif
  
  // We only care about replies for the /workspaces request
  if ([message.addressPattern hasPrefix:@"/reply"]) {
    NSString *body = message.arguments[0];
    NSError *error = nil;
    NSDictionary *reply = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    NSString *address = [message.addressPattern substringFromIndex:@"/reply".length];
    id data = reply[@"data"];
    
    if (error) {
      NSLog(@"error decoding JSON from OSC message: %@", error);
    }
    
    // Workspaces gets handled here
    if ([address isEqualToString:@"/workspaces"]) {
      NSArray *workspaces = (NSArray *)data;
      
      if (self.workspaceBlock) {
        self.workspaceBlock(workspaces, host);
      }
      
      QLKServer *server = [self serverForHost:host];
      [server updateWorkspaces:workspaces];
      
      // Make sure this is dispatched on main thread
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
          [self.delegate browserDidUpdateServers:self];
        }
      });
      
      return;
    }
  }
  
  // Some other message - we don't care about
#if DEBUG_OSC
  NSLog(@"[OSC] unhandled reply: %@ from %@", message, host);
#endif
}

- (void)takeBundle:(F53OSCBundle *)bundle
{
#if DEBUG_OSC
  NSLog(@"[OSC] bundle received: %@", bundle);
#endif
}

#pragma mark - NSNetServiceBrowser delegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
#if DEBUG
  NSLog(@"netServiceBrowser:didFindService: %@", netService);
#endif
  
  [self.services addObject:netService];
  [netService setDelegate:self];
  [netService resolveWithTimeout:5.0f];
}

// When a service is removed, assume the server is gone
// Remove the server and all workspaces
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
  NSLog(@"didRemoveService: %@", netService);
  QLKServer *server = [self serverForNetService:netService];
  [self.servers removeObject:server];
  
  // Make sure this is dispatched on main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.delegate) {
      [self.delegate browserDidUpdateServers:self];
    }
  });
}

#pragma mark - NSNetServiceDelegate

// Resolved address for net service, now get workspaces
- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
  NSLog(@"netServiceDidResolveAddress: %@", netService);
  NSString *ip = [self IPAddressFromData:netService.addresses[0]];
  NSInteger port = netService.port;
  
  // We resolved a QLab instance, create a server for it
  QLKServer *server = [[QLKServer alloc] initWithHost:ip port:port];
  server.netService = netService;
  server.name = netService.name;
  
  NSLog(@"added server: %@", server);
  
  [self.servers addObject:server];  
  [server refreshWorkspaces];
  
  // Once resolved, we can remove the net service
  [self.services removeObject:netService];
}

// Sent if resolution fails
- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)error
{
  NSLog(@"error resolving service: %@ - %@", netService, error);
}

- (NSString *)IPAddressFromData:(NSData *)data
{
  // Taken from Apple sample project - CocoaSoap
  NSString *ip = @"0.0.0.0";
  struct sockaddr_in *address_sin = (struct sockaddr_in *)data.bytes;
  const char *formatted;
  char buffer[1024];
  if (AF_INET == address_sin->sin_family) {
    formatted = inet_ntop(AF_INET, &(address_sin->sin_addr), buffer, sizeof(buffer));
    ip = [NSString stringWithFormat:@"%s", formatted];
  }

  return ip;
}

@end
