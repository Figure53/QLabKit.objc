//
//  QLKMessage.h
//  QLabKit
//
//  Created by Zach Waugh on 7/17/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>

@class F53OSCMessage;

@interface QLKMessage : NSObject

- (id)initWithOSCMessage:(F53OSCMessage *)message;
+ (QLKMessage *)messageWithOSCMessage:(F53OSCMessage *)message;

- (BOOL)isReply;
- (BOOL)isUpdate;
- (BOOL)isWorkspaceUpdate;
- (BOOL)isCueUpdate;
- (BOOL)isPlaybackPositionUpdate;
- (BOOL)isDisconnect;
- (NSString *)address;
- (NSArray *)addressParts;
- (NSString *)replyAddress;
- (NSString *)addressWithoutWorkspace:(NSString *)workspaceID;
- (NSString *)body;
- (id)response;
- (NSArray *)arguments;
- (NSString *)cueID;

@end
