//
//  QLRConnectionManager.m
//  QLab for iPad
//
//  Created by Zach Waugh on 3/23/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import "QLKBrowser.h"
#import "QLRWorkspace.h"
#import "QLKServer.h"
#include <netinet/in.h>
#include <arpa/inet.h>

#define DEBUG_OSC 1
#define SERVER_PORT 53001

NSString * const QLRServersUpdatedNotification = @"QLRServersUpdatedNotification";
NSString * const QLabServiceType = @"_qlab._tcp.";
NSString * const QLabServiceDomain = @"local.";

@interface QLKBrowser ()

@property (assign) BOOL running;

@end

@implementation QLKBrowser

- (void)dealloc 
{
  [self.server stopListening];
  [self.browser stop];
  [self.activeWorkspace disconnect];
}

+ (QLKBrowser *)sharedManager
{
  static QLKBrowser *_sharedManager = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedManager = [[QLKBrowser alloc] init];
  });
  
  return _sharedManager;
}

- (id)init
{
  self = [super init];
  if (!self) return nil;
  
  _running = NO;
  _servers = [[NSMutableArray alloc] init];
  
  return self;
}

// Manually refresh all workspaces
- (void)refreshWorkspaces
{
  for (QLKServer *server in self.servers) {
    [server.client sendPacket:[F53OSCMessage messageWithAddressPattern:@"/workspaces" arguments:nil]];
  }
}

// Start OSC server and bonjour browser
- (void)startServers
{
  NSLog(@"start listening for servers...");
  if (self.running) return;
  
  self.running = YES;
  
  // OSC server to receive workspaces from QLab instances
  if (!self.server) {
    self.server = [[F53OSCServer alloc] init];
    self.server.port = SERVER_PORT;
    self.server.delegate = self;
  }
  
  [self.server startListening];
  
  // Bonjour browser to find QLab instances
  self.browser = [[NSNetServiceBrowser alloc] init];
  [self.browser setDelegate:self];
  [self.browser searchForServicesOfType:QLabServiceType inDomain:QLabServiceDomain];
}

// Stop bonjour - can't currently stop OSC server
- (void)stopServers
{
  NSLog(@"stop listening for servers...");
  self.running = NO;
  
  [self.servers removeAllObjects];
  [self.server stopListening];
  self.server = nil;

  [self.browser stop];
  self.browser = nil;  
}

#pragma mark - OSC server delegate

- (void)takeMessage:(F53OSCMessage *)message
{
  NSString *ip = message.replySocket.host;

#if DEBUG_OSC
  NSLog(@"[OSC/UDP] message received - address: %@, arguments: %@ (from %@)", message.addressPattern, message.arguments, ip);
#endif

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
        self.workspaceBlock(workspaces, ip);
      }
      
      QLKServer *server = [self serverForIp:ip];
      [server removeAllWorkspaces];
      
      for (NSDictionary *dict in workspaces) {
        QLRWorkspace *workspace = [[QLRWorkspace alloc] initWithDictionary:dict server:server];
        [server addWorkspace:workspace];
      }

      // Make sure this is dispatched on main thread
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:QLRServersUpdatedNotification object:self];
      });
    } else if (self.activeWorkspace) {
      // Forward to appropriate connection
      [self.activeWorkspace processMessage:message];
    } else {
      NSLog(@"[OSC] unhandled reply: %@ from %@", message, ip);
    }
  } else if ([message.addressPattern hasPrefix:@"/update"]) {
    [self.activeWorkspace processMessage:message];
  }
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
  
  QLKServer *server = [[QLKServer alloc] init];
  server.netService = netService;
  server.name = netService.name;
  
  NSLog(@"added server: %@", server);
  
  [self.servers addObject:server];
  
  NSLog(@"servers: %@", self.servers);

  [netService setDelegate:self];
  [netService resolveWithTimeout:5.0f];
}

// When a service is removed, assume the server is gone
// Remove the server and all workspaces
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
  QLKServer *server = [self serverForNetService:netService];
  [self.servers removeObject:server];
  
  // Make sure this is dispatched on main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:QLRServersUpdatedNotification object:self];
  });
}

#pragma mark - NSNetServiceDelegate

// Resolved address for net service, now get workspaces
- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
  // Taken from Apple sample project - CocoaSoap
  NSData *address = netService.addresses[0];
  NSString *ip = @"0.0.0.0";
  struct sockaddr_in *address_sin = (struct sockaddr_in *)[address bytes];
  const char *formatted;
  char buffer[1024];
  if (AF_INET == address_sin->sin_family) {
    formatted = inet_ntop(AF_INET, &(address_sin->sin_addr), buffer, sizeof(buffer));
    ip = [NSString stringWithFormat:@"%s", formatted];
  }
  
  F53OSCClient *client = [[F53OSCClient alloc] init];
  client.host = ip;
  client.port = [netService port];
  
  QLKServer *server = [self serverForNetService:netService];
  server.ip = ip;
  server.client = client;
  
  NSLog(@"resolved address for server: %@", server);
  
  [client sendPacket:[F53OSCMessage messageWithAddressPattern:@"/workspaces" arguments:nil]];
}

// Sent if resolution fails
- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)error
{
  NSLog(@"error resolving service: %@ - %@", netService, error);
}

#pragma mark - Server helpers

- (QLKServer *)serverForIp:(NSString *)ip
{
  for (QLKServer *server in self.servers) {
    if ([server.ip isEqualToString:ip]) {
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

@end
