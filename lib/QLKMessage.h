//
//  QLKMessage.h
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

@class F53OSCMessage;


NS_ASSUME_NONNULL_BEGIN

@interface QLKMessage : NSObject

+ (QLKMessage *) messageWithOSCMessage:(F53OSCMessage *)message;

- (instancetype) initWithOSCMessage:(F53OSCMessage *)message;

// Identifying the different types of messages.
@property (nonatomic, getter=isReply, readonly)                     BOOL reply;
@property (nonatomic, getter=isReplyFromCue, readonly)              BOOL replyFromCue;
@property (nonatomic, getter=isUpdate, readonly)                    BOOL update;
@property (nonatomic, getter=isWorkspaceUpdate, readonly)           BOOL workspaceUpdate;
@property (nonatomic, getter=isWorkspaceSettingsUpdate, readonly)   BOOL workspaceSettingsUpdate;
@property (nonatomic, getter=isLightDashboardUpdate, readonly)      BOOL lightDashboardUpdate;
@property (nonatomic, getter=isCueUpdate, readonly)                 BOOL cueUpdate;
@property (nonatomic, getter=isPlaybackPositionUpdate, readonly)    BOOL playbackPositionUpdate;
@property (nonatomic, getter=isPreferencesUpdate, readonly)         BOOL preferencesUpdate;
@property (nonatomic, getter=isDisconnect, readonly)                BOOL disconnect;

// Host the message came from, almost always will be the IP address.
@property (nonatomic, readonly, copy, nullable)     NSString *host;

// Full address path of this message, e.g. /update/workspace/12345/cue_id/4
@property (nonatomic, readonly, copy)               NSString *address;

// Individual address parts separated by "/", e.g. ("update", "workspace", "12345", "cue_id", "4")
@property (nonatomic, readonly, copy)               NSArray<NSString *> *addressParts;

// Address without reply, e.g. "/reply/workspace/12345/connect" -> "/workspace/12345/connect"
@property (nonatomic, readonly, copy)               NSString *replyAddress;

// Address with workspace prefix removed, will also remove /reply: "/workspace/12345/connect" -> "/connect"
- (NSString *) addressWithoutWorkspace:(nullable NSString *)workspaceID;

// Deserialized objects from the "data" key of QLab's reply.
@property (nonatomic, readonly, strong, nullable)   id response;

// Direct arguments from OSC message.
@property (nonatomic, readonly, copy)               NSArray *arguments;

// Cue ID for this message, parsed out depending on what kind of message it is.
@property (nonatomic, readonly, copy, nullable)     NSString *cueID;

@end


@interface QLKMessage (DisallowedInits)

- (instancetype) init  __attribute__((unavailable("Use -initWithOSCMessage::")));

@end

NS_ASSUME_NONNULL_END
