//
//  QLKClient.h
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


#import <Foundation/Foundation.h>
#import "QLKDefines.h"
#import "F53OSCClient.h"

@class QLKCue, F53OSCMessage;

@protocol QLKClientDelegate <NSObject>

- (NSString *) workspaceID;
- (void) workspaceUpdated;
- (void) playbackPositionUpdated:(NSString *)cueID;
- (void) cueNeedsUpdate:(NSString *)cueID;
- (void) cueUpdated:(NSString *)cueID withProperties:(NSDictionary *)properties;
- (void) clientConnectionErrorOccurred;

@end

@interface QLKClient : NSObject <F53OSCPacketDestination, F53OSCClientDelegate>

- (id) initWithHost:(NSString *)host port:(NSInteger)port;

@property (unsafe_unretained) id<QLKClientDelegate> delegate;
@property (assign, nonatomic) BOOL useTCP;
@property (readonly) BOOL isConnected;

- (BOOL) connect;
- (void) disconnect;

- (void) sendOscMessage:(F53OSCMessage *)message;
- (void) sendOscMessage:(F53OSCMessage *)message block:(QLKMessageHandlerBlock)block;

- (void) sendMessageWithArgument:(NSObject *)argument toAddress:(NSString *)address;
- (void) sendMessageWithArgument:(NSObject *)argument toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block;
- (void) sendMessagesWithArguments:(NSArray *)arguments toAddress:(NSString *)address;
- (void) sendMessagesWithArguments:(NSArray *)arguments toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block;
- (void) sendMessagesWithArguments:(NSArray *)arguments toAddress:(NSString *)address workspace:(BOOL)toWorkspace block:(QLKMessageHandlerBlock)block;

@end
