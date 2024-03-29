//
//  QLKClient.m
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2013-2022 Figure 53 LLC, https://figure53.com
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

#if __has_include(<F53OSC/F53OSC-Swift.h>) // F53OSC_BUILT_AS_FRAMEWORK
#import <F53OSC/F53OSC-Swift.h>
#endif

#import "QLKCue.h"
#import "QLKMessage.h"


#ifndef RELEASE
#ifndef DEBUG_OSC_INPUT
#define DEBUG_OSC_INPUT 0
#endif
#ifndef DEBUG_OSC_OUTPUT
#define DEBUG_OSC_OUTPUT 0
#endif
#endif


NS_ASSUME_NONNULL_BEGIN

@interface QLKClient ()
{
    F53OSCClient *_OSCClient;
}

@property (nonatomic, readonly) NSMutableDictionary<NSString *, QLKMessageReplyBlock> *callbacks;
@property (nonatomic, readonly) NSString *workspacePrefix;

- (void)processMessage:(QLKMessage *)message;

@end


@implementation QLKClient

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port
{
    self = [super init];
    if (self)
    {
        self.OSCClient.host = host;
        if (port >= 0)
            self.OSCClient.port = port;
        self.OSCClient.useTcp = YES;
        self.OSCClient.delegate = self;

        _callbacks = [[NSMutableDictionary alloc] init]; // key: OSC address, value: code block
        _delegate = nil;
    }
    return self;
}

- (void)dealloc
{
    [_OSCClient disconnect];
    _OSCClient.delegate = nil;
}


#pragma mark -

- (nullable F53OSCClient *)OSCClient
{
    // NOTE: subclasses may wish to override this getter, so for that reason we mark it `nullable`
    // - even though the lazy init below means this *particular* implementation always returns a nonnull value

    // subclasses can do the following to provide their own custom subclass of F53OSCClient:
    // 1) declare a private ivar in the QLKClient subclass with the F53OSCClient subclass type
    // 2) override this getter method and return the F53OSCClient ivar
    // 3) after calling `initWithHost:port:` on super in the QLKClient subclass init method, create an instance of the F53OSCClient subclass and assign it to the private ivar

    if (!_OSCClient)
    {
        _OSCClient = [[F53OSCClient alloc] init];
        _OSCClient.socketDelegateQueue = dispatch_queue_create("com.figure53.QLabKit.F53OSCClient.socket", DISPATCH_QUEUE_SERIAL);
    }
    return _OSCClient;
}

- (BOOL)useTCP
{
    return self.OSCClient.useTcp;
}

- (void)setUseTCP:(BOOL)useTCP
{
    self.OSCClient.useTcp = useTCP;
}

- (BOOL)isConnected
{
    return self.OSCClient.isConnected;
}


#pragma mark -

- (BOOL)connect
{
    if ([self.delegate respondsToSelector:@selector(shouldEncryptConnectionsForClient:)] &&
        [self.delegate shouldEncryptConnectionsForClient:self])
    {
        F53OSCEncrypt *encrypter = [[F53OSCEncrypt alloc] init];
        NSData *keyPair = [encrypter generateKeyPair];
        if (!keyPair)
        {
            NSLog(@"Failed to generate key pair for QLKClient encryption");
            return NO;
        }

        return [self.OSCClient connectEncryptedWithKeyPair:keyPair];
    }
    else
    {
        return [self.OSCClient connect];
    }
}

- (void)disconnect
{
    [self.OSCClient disconnect];
}

- (void)sendOscMessage:(F53OSCMessage *)message
{
    [self sendOscMessage:message block:nil];
}

- (void)sendOscMessage:(F53OSCMessage *)message block:(nullable QLKMessageReplyBlock)block
{
    if (block)
        self.callbacks[message.addressPattern] = block;

#if DEBUG_OSC_OUTPUT
    NSLog(@"[OSC:client -> (%@:%d)]\n  sent raw OSC message: %@\n ", self.OSCClient.host, self.OSCClient.port, message);
#endif

    [self.OSCClient sendPacket:message];
}

- (void)sendMessageWithArgument:(nullable NSObject *)argument toAddress:(NSString *)address
{
    [self sendMessageWithArgument:argument toAddress:address block:nil];
}

- (void)sendMessageWithArgument:(nullable NSObject *)argument toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block
{
    NSArray *arguments = nil;
    if ([argument isKindOfClass:[NSArray class]])
        arguments = (NSArray *)argument;
    else if (argument != nil)
        arguments = @[argument];

    [self sendMessagesWithArguments:arguments toAddress:address block:block];
}

- (void)sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address
{
    [self sendMessagesWithArguments:arguments toAddress:address block:nil];
}

- (void)sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block
{
    [self sendMessagesWithArguments:arguments toAddress:address workspace:YES block:block];
}

- (void)sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address workspace:(BOOL)toWorkspace block:(nullable QLKMessageReplyBlock)block
{
    if (block)
        self.callbacks[address] = block;

    NSString *fullAddress = (toWorkspace && self.delegate ? [NSString stringWithFormat:@"%@%@", self.workspacePrefix, address] : address);

#if DEBUG_OSC_OUTPUT
    NSLog(@"[OSC:client -> (%@:%d)]\n  address: %@\n     data: {%@}\n ", self.OSCClient.host, self.OSCClient.port, fullAddress, [arguments componentsJoinedByString:@","]);
#endif

    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:fullAddress arguments:arguments];
    [self.OSCClient sendPacket:message];
}

- (NSString *)workspacePrefix
{
    return [NSString stringWithFormat:@"/workspace/%@", [self.delegate workspaceIDForClient:self]];
}


#pragma mark -

- (void)processMessage:(QLKMessage *)message
{
#if DEBUG_OSC_INPUT
    NSLog(@"[OSC:client <-]\n  address:   %@\n  arguments: %@\n ", message.address, [message.arguments componentsJoinedByString:@" - "]);
#endif

    if (message.isReply)
    {
        NSString *status = (message.status ? message.status : @"error");
        id data = message.response; // Get the deserialized value sent back in this reply.

        // Special case, want to update cue properties.
        if (message.isReplyFromCue && [status isEqualToString:@"ok"])
        {
            // this check is sufficient for determining whether new info is arriving
            if ([data isKindOfClass:[NSDictionary class]])
            {
                // replies from /valuesWithKeys contain already-formed data dictionaries

                __weak typeof(self.delegate) delegate = self.delegate;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate client:self cueUpdated:message.cueID withProperties:(NSDictionary *)data];
                });
            }
            else if (message.cueID != nil && // should be non-nil for `isReplyFromCue`, but check to be safe
                     ([data isKindOfClass:[NSNumber class]] || [data isKindOfClass:[NSString class]]))
            {
                NSString *propertyKey = nil;

                // Construct the property key from the addressPart(s) following "cue_id".
                NSArray<NSString *> *addressParts = message.addressParts;
                NSUInteger cueIDIndex = [addressParts indexOfObject:message.cueID];
                if (cueIDIndex != NSNotFound)
                {
                    NSUInteger keyStartIndex = cueIDIndex + 1;
                    if (keyStartIndex + 1 == addressParts.count)
                    {
                        propertyKey = addressParts.lastObject;
                    }
                    else if (keyStartIndex < addressParts.count)
                    {
                        NSRange range = NSMakeRange(keyStartIndex, addressParts.count - keyStartIndex);
                        NSIndexSet *keyComponentIndexes = [NSIndexSet indexSetWithIndexesInRange:range];
                        NSArray<NSString *> *keyComponents = [addressParts objectsAtIndexes:keyComponentIndexes];
                        propertyKey = [keyComponents componentsJoinedByString:@"/"];
                    }
                }

                if (propertyKey.length > 0)
                {
                    // replies from property getters contain just the value, so we need to form the dictionary
                    NSDictionary<NSString *, NSObject<NSCopying> *> *properties = @{propertyKey: data};

                    __weak typeof(self.delegate) delegate = self.delegate;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [delegate client:self cueUpdated:message.cueID withProperties:properties];
                    });
                }
            }
        }

        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf)
                return;

            NSString *workspaceID = [strongSelf.delegate workspaceIDForClient:strongSelf];
            NSString *relativeAddress = [message addressWithoutWorkspace:workspaceID];
            QLKMessageReplyBlock block = strongSelf.callbacks[relativeAddress];
            if (!block)
                return;

            // Remove handler for address
            [strongSelf.callbacks removeObjectForKey:relativeAddress];

            block(status, data);
        });
    }
    else if (message.isUpdate)
    {
        if (message.isCueUpdate)
        {
            __weak typeof(self.delegate) delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate client:self cueNeedsUpdate:message.cueID];
            });
        }
        else if (message.isPlaybackPositionUpdate)
        {
            NSArray<NSString *> *parts = message.addressParts; // ( parts.count == 6 ) validated by `isPlaybackPositionUpdate`
            NSString *cueListID = parts[4];

            __weak typeof(self.delegate) delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate client:self cueListUpdated:cueListID withPlaybackPositionID:message.cueID];
            });
        }
        else if (message.isWorkspaceUpdate)
        {
            __weak typeof(self.delegate) delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate clientWorkspaceUpdated:self];
            });
        }
        else if (message.isWorkspaceSettingsUpdate)
        {
            NSString *settingsType = message.addressParts.lastObject;
            if (!settingsType)
                return;

            __weak typeof(self.delegate) delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate client:self workspaceSettingsUpdated:settingsType];
            });
        }
        else if (message.isLightDashboardUpdate)
        {
            // NOTE: Dashboard update messages are sent by QLab 4.2 and newer
            if ([self.delegate respondsToSelector:@selector(clientLightDashboardUpdated:)] == NO)
                return;

            __weak typeof(self.delegate) delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate clientLightDashboardUpdated:self];
            });
        }
        else if (message.isPreferencesUpdate)
        {
            // NOTE: QLab app preference update messages are sent by QLab 4.2 and newer
            if ([self.delegate respondsToSelector:@selector(client:preferencesUpdated:)] == NO)
                return;

            NSString *key = message.addressParts.lastObject;
            if (!key)
                return;

            __weak typeof(self.delegate) delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate client:self preferencesUpdated:key];
            });
        }
        else if (message.isDisconnect)
        {
            NSLog(@"[client] disconnect message received: %@", message.address);

            __weak typeof(self.delegate) delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate clientWorkspaceDisconnected:self];
            });
        }
        else
        {
            NSLog(@"[client] unhandled update message: %@", message.address);
        }
    }
}


#pragma mark - F53OSCPacketDestination

- (void)takeMessage:(nullable F53OSCMessage *)message
{
    if (!message)
        return;

    // called on the self.OSCClient.socketDelegateQueue thread
    [self processMessage:[QLKMessage messageWithOSCMessage:(F53OSCMessage *_Nonnull)message]];
}


#pragma mark - F53OSCClientDelegate

- (void)clientDidConnect:(F53OSCClient *)client
{
    [self.delegate clientConnected:self];
}

- (void)clientDidDisconnect:(F53OSCClient *)client
{
    NSLog(@"[client] clientDidDisconnect: %@", client);

    [self.delegate clientConnectionErrorOccurred:self];

    // if delegate replies with NO, do nothing further
    // - delegate will be responsible for disconnecting and destroying this client
    if ([self.delegate respondsToSelector:@selector(clientShouldDisconnectOnError:)] &&
        [self.delegate clientShouldDisconnectOnError:self] == NO)
    {
        return;
    }

    [self disconnect];
}

@end

NS_ASSUME_NONNULL_END
