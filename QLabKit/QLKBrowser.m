//
//  QLRConnectionManager.m
//  QLab for iPad
//
//  Created by Zach Waugh on 3/23/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import "QLKBrowser.h"
#import "QLKWorkspace.h"
#import "QLKServer.h"
#include <netinet/in.h>
#include <arpa/inet.h>

#define DEBUG_OSC 1
#define SERVER_PORT 53001

NSString * const QLRServersUpdatedNotification = @"QLRServersUpdatedNotification";

@interface QLKBrowser ()

@property (strong, nonatomic) F53OSCServer *server;
@property (assign) BOOL running;

- (QLKServer *)serverForIPAddress:(NSString *)ip port:(NSInteger)port;

@end

@implementation QLKBrowser

- (void)dealloc 
{
  [self.server stopListening];
  [self.browser stop];
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
  _automaticallyRefresh = NO;
  
  return self;
}

- (void)enableAutoRefreshWithInterval:(NSTimeInterval)interval
{
  self.automaticallyRefresh = YES;
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
  [self.browser searchForServicesOfType:QLKBonjourServiceType inDomain:QLKBonjourServiceDomain];
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

- (QLKServer *)serverForIPAddress:(NSString *)ip port:(NSInteger)port
{
  for (QLKServer *server in self.servers) {
    if ([server.ip isEqualToString:ip] && server.port == port) {
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
  NSString *ip = message.replySocket.host;
  int port = message.replySocket.port;

#if DEBUG_OSC
  NSLog(@"[OSC/UDP %@:%d] message received - address: %@, arguments: %@", ip, port, message.addressPattern, message.arguments);
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
      
      QLKServer *server = [self serverForIPAddress:ip port:port];
      [server removeAllWorkspaces];
      
      for (NSDictionary *dict in workspaces) {
        QLKWorkspace *workspace = [[QLKWorkspace alloc] initWithDictionary:dict server:server];
        [server addWorkspace:workspace];
      }

      // Make sure this is dispatched on main thread
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
          [self.delegate browserDidUpdateServers:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:QLRServersUpdatedNotification object:self];
      });
    } else {
      NSLog(@"[OSC] unhandled reply: %@ from %@", message, ip); 
    }
  } else {
    NSLog(@"[OSC] unhandled reply: %@ from %@", message, ip);
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
    if (self.delegate) {
      [self.delegate browserDidUpdateServers:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QLRServersUpdatedNotification object:self];
  });
}

#pragma mark - NSNetServiceDelegate

// Resolved address for net service, now get workspaces
- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
  NSString *ip = [self IPAddressFromData:netService.addresses[0]];

  F53OSCClient *client = [[F53OSCClient alloc] init];
  client.host = ip;
  client.port = netService.port;
  
  QLKServer *server = [self serverForNetService:netService];
  server.ip = ip;
  server.port = netService.port;
  server.client = client;
  
  NSLog(@"resolved address for server: %@:%ld", server, netService.port);
  
  [client sendPacket:[F53OSCMessage messageWithAddressPattern:@"/workspaces" arguments:nil]];
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
