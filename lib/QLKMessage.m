//
//  QLKMessage.m
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


#import "QLKMessage.h"
#import "F53OSCMessage.h"

@interface QLKMessage ()

@property (strong) F53OSCMessage *OSCMessage;

- (NSArray *) addressParts;

@end

@implementation QLKMessage

+ (QLKMessage *) messageWithOSCMessage:(F53OSCMessage *)message
{
    return [[QLKMessage alloc] initWithOSCMessage:message];
}

- (id) initWithOSCMessage:(F53OSCMessage *)message
{
    self = [super init];
    if ( !self )
        return nil;

    _OSCMessage = message;

    return self;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"address: %@, arguments: %@", self.address, [self.arguments componentsJoinedByString:@" - "]];
}

- (BOOL) isReply
{
    return [self.OSCMessage.addressPattern hasPrefix:@"/reply"];
}

- (BOOL) isUpdate
{
    return [self.OSCMessage.addressPattern hasPrefix:@"/update"];
}

- (BOOL) isWorkspaceUpdate
{
    // /update/workspace/{workspace_id}
    NSArray *parts = self.addressParts;

    return (parts.count == 3 && [parts[1] isEqualToString:@"workspace"]);
}

- (BOOL) isCueUpdate
{
    // /update/workspace/{workspace_id}/cue_id/{cue_id}
    NSArray *parts = self.addressParts;

    return (parts.count == 5 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"cue_id"]);
}

- (BOOL) isPlaybackPositionUpdate
{
    // /update/workspace/{workspace_id}/cueList/{cue_list_id}/playbackPosition {cue_id}
    NSArray *parts = self.addressParts;

    return (parts.count == 6 && [self.address hasSuffix:@"/playbackPosition"]);
}

- (BOOL) isDisconnect
{
    return [self.address hasSuffix:@"/disconnect"];
}

- (BOOL) isReplyFromCue
{
    // /reply/cue_id/1/action
    return [self.address hasPrefix:@"/reply/cue_id"];
}

- (NSString *) cueID
{
    if ( [self isCueUpdate] )
    {
        return self.addressParts[4];
    }
    else if ( [self isPlaybackPositionUpdate] )
    {
        return (self.arguments.count > 0) ? self.arguments[0] : nil;
    }
    else if ( [self isReplyFromCue] )
    {
        return self.addressParts[2];
    }
    else
    {
        return nil;
    }
}

- (NSString *) host
{
    return self.OSCMessage.replySocket.host;
}

- (NSArray *) arguments
{
    return self.OSCMessage.arguments;
}

- (NSString *) address
{
    return self.OSCMessage.addressPattern;
}

- (NSString *) replyAddress
{
    return (self.isReply) ? [self.address substringFromIndex:@"/reply".length] : self.address;
}

- (NSString *) addressWithoutWorkspace:(NSString *)workspaceID
{
    NSString *workspacePrefix = [NSString stringWithFormat:@"/workspace/%@", workspaceID];
    NSString *address = self.replyAddress;

    if ( [address hasPrefix:workspacePrefix] )
    {
        return [address substringFromIndex:workspacePrefix.length];
    }
    else
    {
        return address;
    }
}

- (NSArray *) addressParts
{
    NSArray *parts = [self.address pathComponents];
    return [parts subarrayWithRange:NSMakeRange( 1, parts.count - 1 )];
}

- (id) response
{
    NSError *error = nil;
    NSString *body = self.OSCMessage.arguments[0]; // QLab replies have one argument, which is a JSON string.
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

    if ( error )
    {
        NSLog( @"error decoding JSON: %@, %@", error, self.OSCMessage.arguments );
    }

    return dict[@"data"]; // The answer to a reply is stored as "data" in the JSON-encoded dictionary sent by QLab.
}

@end
