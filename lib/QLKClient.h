//
//  QLKClient.h
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

#import <Foundation/Foundation.h>

#import "QLKDefines.h"
#import <F53OSC/F53OSCClient.h>


@class QLKCue;
@class F53OSCMessage;
@protocol QLKClientDelegate;


NS_ASSUME_NONNULL_BEGIN

@interface QLKClient : NSObject <F53OSCPacketDestination, F53OSCClientDelegate>

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port;

@property (nonatomic, weak, nullable) id<QLKClientDelegate> delegate;
@property (nonatomic, nullable, readonly) F53OSCClient *OSCClient;
@property (nonatomic) BOOL useTCP;
@property (nonatomic, readonly) BOOL isConnected;

- (BOOL)connect;
- (void)disconnect;

- (void)sendOscMessage:(F53OSCMessage *)message;
- (void)sendOscMessage:(F53OSCMessage *)message block:(nullable QLKMessageReplyBlock)block;

// NOTE: `arguments` must be a type supported by F53OSCMessage `arguments`: NSString, NSData, or NSNumber
- (void)sendMessageWithArgument:(nullable NSObject *)argument toAddress:(NSString *)address;
- (void)sendMessageWithArgument:(nullable NSObject *)argument toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block;
- (void)sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address;
- (void)sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address block:(nullable QLKMessageReplyBlock)block;
- (void)sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address workspace:(BOOL)toWorkspace block:(nullable QLKMessageReplyBlock)block;

@end


@protocol QLKClientDelegate <NSObject>

- (NSString *)workspaceIDForClient:(QLKClient *)client;

- (void)clientConnected:(QLKClient *)client;
- (void)clientConnectionErrorOccurred:(QLKClient *)client;

- (void)clientWorkspaceUpdated:(QLKClient *)client;
- (void)client:(QLKClient *)client workspaceSettingsUpdated:(NSString *)settingsType;
- (void)client:(QLKClient *)client cueNeedsUpdate:(NSString *)cueID;
- (void)client:(QLKClient *)client cueUpdated:(NSString *)cueID withProperties:(NSDictionary<NSString *, NSObject<NSCopying> *> *)properties;
- (void)client:(QLKClient *)client cueListUpdated:(NSString *)cueListID withPlaybackPositionID:(nullable NSString *)cueID;
- (void)clientWorkspaceDisconnected:(QLKClient *)client;

@optional
- (BOOL)shouldEncryptConnectionsForClient:(QLKClient *)client; // requires connection to QLab v5+.

// Upon encountering a connection error, if delegate returns YES (or method is not implemented), client will immediately send `clientConnectionErrorOccurred:`.
// If delegate returns NO, delegate is responsible for disconnecting/destroying this client when appropriate.
- (BOOL)clientShouldDisconnectOnError:(QLKClient *)client;

// NOTE: these update messages are sent only when connected to QLab 4.2+
- (void)clientLightDashboardUpdated:(QLKClient *)client;
- (void)client:(QLKClient *)client preferencesUpdated:(NSString *)key;

@end


@interface QLKClient (DisallowedInits)

- (instancetype)init __attribute__((unavailable("Use -initWithHost:port:")));

@end

NS_ASSUME_NONNULL_END
