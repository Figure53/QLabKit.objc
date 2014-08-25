//
//  QLKClient.m
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

- (id) initWithHost:(NSString *)host port:(NSInteger)port
{
    self = [super init];
    if ( !self )
        return nil;
    
    _OSCClient = [[F53OSCClient alloc] init];
    _OSCClient.host = host;
    _OSCClient.port = port;
    _OSCClient.useTcp = YES;
    _OSCClient.delegate = self;
    _callbacks = [[NSMutableDictionary alloc] init]; // key: OSC address, value: code block
    _delegate = nil;
    
    return self;
}

- (void) dealloc
{
    [self.OSCClient disconnect];
    self.OSCClient.delegate = nil;
}

- (BOOL) useTCP
{
    return self.OSCClient.useTcp;
}

- (void) setUseTCP:(BOOL)useTCP
{
    self.OSCClient.useTcp = useTCP;
}

- (BOOL) isConnected
{
    return self.OSCClient.isConnected;
}

- (BOOL) connect
{
    return [self.OSCClient connect];
}

- (void) disconnect
{
    [self.OSCClient disconnect];
}

- (void) sendOscMessage:(F53OSCMessage *)message
{
    [self sendOscMessage:message block:nil];
}

- (void) sendOscMessage:(F53OSCMessage *)message block:(QLKMessageHandlerBlock)block
{
    if ( block )
        self.callbacks[message.addressPattern] = block;
    
#if DEBUG_OSC
    NSLog( @"QLKClient sending raw OSC message to (%@:%d): %@", self.OSCClient.host, self.OSCClient.port, messages );
#endif
    
    [self.OSCClient sendPacket:message];
}

- (void) sendMessageWithArgument:(NSObject *)argument toAddress:(NSString *)address
{
    [self sendMessageWithArgument:argument toAddress:address block:nil];
}

- (void) sendMessageWithArgument:(NSObject *)argument toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block
{
    NSArray *arguments = (argument != nil) ? @[argument] : nil;
    [self sendMessagesWithArguments:arguments toAddress:address block:block];
}

- (void) sendMessagesWithArguments:(NSArray *)arguments toAddress:(NSString *)address
{
    [self sendMessagesWithArguments:arguments toAddress:address block:nil];
}

- (void) sendMessagesWithArguments:(NSArray *)arguments toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block
{
    [self sendMessagesWithArguments:arguments toAddress:address workspace:YES block:block];
}

- (void) sendMessagesWithArguments:(NSArray *)arguments toAddress:(NSString *)address workspace:(BOOL)toWorkspace block:(QLKMessageHandlerBlock)block
{
    if ( block )
        self.callbacks[address] = block;
  
    NSString *fullAddress = (toWorkspace && self.delegate) ? [NSString stringWithFormat:@"%@%@", [self workspacePrefix], address] : address;
  
#if DEBUG_OSC
    NSLog( @"QLKClient sending OSC message to (%@:%d): %@ data: %@", self.OSCClient.host, self.OSCClient.port, fullAddress, arguments );
#endif

    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:fullAddress arguments:arguments];
    [self.OSCClient sendPacket:message];
}

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

#pragma mark - 

- (void) processMessage:(QLKMessage *)message
{
#if DEBUG_OSC
    NSLog( @"[OSC:client <-] %@", message );
#endif
  
    if ( [message isReply] )
    {
        id data = message.response; // Get the deserialized value sent back in this reply.
    
        // Special case, want to update cue properties.
        if ( [message isReplyFromCue] )
        {
            //this check is sufficient for determining whether new info is arriving
            if ( [data isKindOfClass:[NSDictionary class]] )
            {
                [self.delegate cueUpdated:message.cueID withProperties:data];
            }
        }
    
        NSString *relativeAddress = [message addressWithoutWorkspace:[self.delegate workspaceID]];
        QLKMessageHandlerBlock block = self.callbacks[relativeAddress];
        if ( block )
        {
            dispatch_async( dispatch_get_main_queue(), ^
            {
                block( data );
            
                // Remove handler for address.
                [self.callbacks removeObjectForKey:relativeAddress];
            });
        }
    }
    else if ( [message isUpdate] )
    {
        if ( [message isWorkspaceUpdate] )
        {
            [self.delegate workspaceUpdated];
        }
        else if ( [message isCueUpdate] )
        {
            [self.delegate cueNeedsUpdate:message.cueID];
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
