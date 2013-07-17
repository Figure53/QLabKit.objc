//
//  QLKClient.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
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

@end
