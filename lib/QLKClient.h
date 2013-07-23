//
//  QLKClient.h
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


#import <Foundation/Foundation.h>
#import "QLKDefines.h"
#import "F53OSCClient.h"

@class QLKCue, F53OSCMessage;

@protocol QLKClientDelegate <NSObject>

- (void)cueUpdated:(NSString *)cueID;
- (void)cueUpdated:(NSString *)cueID withProperties:(NSDictionary *)properties;
- (void)workspaceUpdated;
- (void)playbackPositionUpdated:(NSString *)cueID;
- (NSString *)workspaceID;

@end

@interface QLKClient : NSObject <F53OSCClientDelegate, F53OSCPacketDestination>

@property (unsafe_unretained) id<QLKClientDelegate> delegate;
@property (assign, nonatomic) BOOL useTCP;
@property (assign) BOOL connected;

- (id)initWithHost:(NSString *)host port:(NSInteger)port;
- (void)disconnect;
- (BOOL)connect;

- (void)sendMessage:(F53OSCMessage *)message;
- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address;
- (void)sendMessage:(NSObject *)message toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block;
- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address;
- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address block:(QLKMessageHandlerBlock)block;
- (void)sendMessages:(NSArray *)messages toAddress:(NSString *)address workspace:(BOOL)toWorkspace block:(QLKMessageHandlerBlock)block;

@end
