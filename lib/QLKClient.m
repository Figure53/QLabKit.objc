//
//  QLKClient.m
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

#import "QLKClient.h"
#import "QLKDefines.h"
#import "QLKCue.h"
#import "QLKMessage.h"
#import "F53OSC.h"

#define DEBUG_OSC 0

@interface QLKClient ()

@property (strong) F53OSCClient *OSCClient;
@property (strong) NSMutableDictionary *callbacks;

@end

@implementation QLKClient

- (void) dealloc
{
    _OSCClient.delegate = nil;
}

- (id) initWithHost:(NSString *)host port:(NSInteger)port
{
    self = [super init];
    if ( !self )
        return nil;

    _callbacks = [[NSMutableDictionary alloc] init];
    _OSCClient = [[F53OSCClient alloc] init];
    _OSCClient.host = host;
    _OSCClient.port = port;
    _OSCClient.delegate = self;
    _connected = NO;

    return self;
}

- (void) setUseTCP:(BOOL)useTCP
{
    _useTCP = useTCP;
    self.OSCClient.useTcp = useTCP;
}

- (BOOL) connect
{
    return [self.OSCClient connect];
}

- (void) disconnect
{
    [self.OSCClient disconnect];
}

- (void) sendMessage:(F53OSCMessage *)message
{
#if DEBUG_OSC
    NSLog( @"[OSC:client ->] %@ (%@:%d)", message.addressPattern, self.OSCClient.host, self.OSCClient.port );
#endif
  
    [self.OSCClient sendPacket:message];
}

- (void) sendMessage:(NSObject *)message toAddress:(NSString *)address
{
    [self sendMessage:message toAddress:address block:nil];
}

- (void) sendMessage:(NSObject *)message toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block
{
    NSArray *messages = (message != nil) ? @[message] : nil;
    [self sendMessages:messages toAddress:address block:block];
}

- (void) sendMessages:(NSArray *)messages toAddress:(NSString *)address
{
    [self sendMessages:messages toAddress:address block:nil];
}

- (void) sendMessages:(NSArray *)messages toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block
{
    [self sendMessages:messages toAddress:address workspace:YES block:block];
}

- (void) sendMessages:(NSArray *)messages toAddress:(NSString *)address workspace:(BOOL)toWorkspace block:(QLKMessageHandlerBlock)block
{
    if ( block )
    {
        self.callbacks[address] = block;
    }
  
    NSString *fullAddress = (toWorkspace && self.delegate) ? [NSString stringWithFormat:@"%@%@", [self workspacePrefix], address] : address;
  
#if DEBUG_OSC
    NSLog( @"[OSC:client ->] %@, data: %@ (%@:%d)", fullAddress, messages, self.OSCClient.host, self.OSCClient.port );
#endif

    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:fullAddress arguments:messages];
    [self.OSCClient sendPacket:message];
}

#pragma mark - 

- (NSString *) workspacePrefix
{
    return [NSString stringWithFormat:@"/workspace/%@", [self.delegate workspaceID]];
}

#pragma mark - F53OSCPacketDestination

- (void) takeMessage:(F53OSCMessage *)message
{
    [self processMessage:[QLKMessage messageWithOSCMessage:message]];
}

#pragma mark - F53OSCClientDelegate

- (void) clientDidConnect:(F53OSCClient *)client
{
}

- (void) clientDidDisconnect:(F53OSCClient *)client
{
    [self.delegate clientConnectionErrorOccurred];
}

- (void) processMessage:(QLKMessage *)message
{
#if DEBUG_OSC
    NSLog( @"[OSC:client <-] %@", message );
#endif
  
    if ( [message isReply] )
    {
        id data = message.response;
    
        // Special case, want to update cue properties
        if ( [message isReplyCueUpdate] )
        {
            if ( [data isKindOfClass:[NSDictionary class]] )
            {
                [self.delegate cueUpdated:message.cueID withProperties:data];
            }
        }
    
        // Reply to a message we sent
        NSString *relativeAddress = [message addressWithoutWorkspace:[self.delegate workspaceID]];
        QLKMessageHandlerBlock block = self.callbacks[relativeAddress];
        
        if ( block )
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                block( data );
            
                // Remove handler for address
                [self.callbacks removeObjectForKey:relativeAddress];
            });
        }
    }
    else if ( [message isUpdate] )
    {
        // QLab has informed us of an update
        if ( [message isWorkspaceUpdate] )
        {
            [self.delegate workspaceUpdated];
        }
        else if ( [message isCueUpdate] )
        {
            [self.delegate cueUpdated:message.cueID];
        }
        else if ( [message isPlaybackPositionUpdate] )
        {
            [self.delegate playbackPositionUpdated:message.cueID];
        }
        else if ( [message isDisconnect] )
        {
            [self.delegate clientConnectionErrorOccurred];
        }
        else
        {
            NSLog( @"[client] unhandled update message: %@", message.address );
        }
    }
}

@end
