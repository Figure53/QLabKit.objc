//
//  QLKMessage.h
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

@class F53OSCMessage;

@interface QLKMessage : NSObject

+ (QLKMessage *) messageWithOSCMessage:(F53OSCMessage *)message;

- (id) initWithOSCMessage:(F53OSCMessage *)message;

// Identifying the different types of messages.
- (BOOL) isReply;
- (BOOL) isReplyFromCue;
- (BOOL) isUpdate;
- (BOOL) isWorkspaceUpdate;
- (BOOL) isCueUpdate;
- (BOOL) isPlaybackPositionUpdate;
- (BOOL) isDisconnect;

// Host the message came from, almost always will be the IP address.
- (NSString *) host;

// Full address path of this message, e.g. /update/workspace/12345/cue_id/4
- (NSString *) address;

// Individual address parts separated by "/", e.g. ("update", "workspace", "12345", "cue_id", "4")
- (NSArray *) addressParts;

// Address without reply, e.g. "/reply/workspace/12345/connect" -> "/workspace/12345/connect"
- (NSString *) replyAddress;

// Address with workspace prefix removed, will also remove /reply: "/workspace/12345/connect" -> "/connect"
- (NSString *) addressWithoutWorkspace:(NSString *)workspaceID;

// Deserialized objects from the "data" key of QLab's reply.
- (id) response;

// Direct arguments from OSC message.
- (NSArray *) arguments;

// Cue ID for this message, parsed out depending on what kind of message it is.
- (NSString *) cueID;

@end
