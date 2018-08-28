//
//  QLKClient.h
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

@import Foundation;

#import "QLKDefines.h"
#import "F53OSCClient.h"


@class QLKCue, F53OSCMessage;
@protocol QLKClientDelegate;


NS_ASSUME_NONNULL_BEGIN

@interface QLKClient : NSObject <F53OSCPacketDestination, F53OSCClientDelegate>

- (instancetype) initWithHost:(NSString *)host port:(NSInteger)port;

@property (nonatomic, weak, nullable)               id<QLKClientDelegate> delegate;
@property (nonatomic, strong, nullable, readonly)   F53OSCClient *OSCClient;
@property (nonatomic)                               BOOL useTCP;
@property (nonatomic, readonly)                     BOOL isConnected;

- (BOOL) connect;
- (void) disconnect;

- (void) sendOscMessage:(F53OSCMessage *)message;
- (void) sendOscMessage:(F53OSCMessage *)message block:(nullable QLKMessageHandlerBlock)block;

// NOTE: `arguments` must be a type supported by F53OSCMessage `arguments`: NSString, NSData, or NSNumber
- (void) sendMessageWithArgument:(nullable NSObject *)argument toAddress:(NSString *)address;
- (void) sendMessageWithArgument:(nullable NSObject *)argument toAddress:(NSString *)address block:(nullable QLKMessageHandlerBlock)block;
- (void) sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address;
- (void) sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address block:(nullable QLKMessageHandlerBlock)block;
- (void) sendMessagesWithArguments:(nullable NSArray *)arguments toAddress:(NSString *)address workspace:(BOOL)toWorkspace block:(nullable QLKMessageHandlerBlock)block;

@end


@protocol QLKClientDelegate <NSObject>

@property (nonatomic, readonly, copy)               NSString *workspaceID;

- (void) workspaceUpdated;
- (void) workspaceSettingsUpdated:(NSString *)settingsType;
- (void) workspaceDisconnected;
- (void) cueNeedsUpdate:(NSString *)cueID;
- (void) cueUpdated:(NSString *)cueID withProperties:(NSDictionary<NSString *, NSObject<NSCopying> *> *)properties;
- (void) cueListUpdated:(NSString *)cueListID withPlaybackPositionID:(nullable NSString *)cueID;
- (void) clientConnectionErrorOccurred;

@optional
// upon encountering a connection error, if delegate returns YES (or method is not implemented), client will immediately send `clientConnectionErrorOccurred`
// if delegate returns NO, delegate is responsible for disconnecting/destroying this client when appropriate
- (BOOL) clientShouldDisconnectOnError;

// NOTE: these update messages are sent only when connected to QLab 4.2+
- (void) lightDashboardUpdated;
- (void) preferencesUpdated:(NSString *)key;

@end


@interface QLKClient (DisallowedInits)

- (instancetype) init  __attribute__((unavailable("Use -initWithHost:port:")));

@end

NS_ASSUME_NONNULL_END
