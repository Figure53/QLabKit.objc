//
//  QLKMessage.m
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

#import "QLKMessage.h"

#import <F53OSC/F53OSCMessage.h>


NS_ASSUME_NONNULL_BEGIN

@interface QLKMessage ()
{
    id _response;
    NSString *_status;
}

@property (nonatomic, strong) F53OSCMessage *OSCMessage;
@property (nonatomic, strong, nullable) NSArray<NSString *> *addressPartsCache;

@end


@implementation QLKMessage

+ (QLKMessage *)messageWithOSCMessage:(F53OSCMessage *)message
{
    return [[QLKMessage alloc] initWithOSCMessage:message];
}

- (instancetype)initWithOSCMessage:(F53OSCMessage *)message
{
    self = [super init];
    if (self)
    {
        self.OSCMessage = message;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"address: %@, arguments: %@", self.address, [self.arguments componentsJoinedByString:@" - "]];
}

#pragma mark - custom getters/setters

- (void)setOSCMessage:(F53OSCMessage *)OSCMessage
{
    if (_OSCMessage != OSCMessage)
    {
        _OSCMessage = OSCMessage;
        self.addressPartsCache = nil;
    }
}

#pragma mark -

- (BOOL)isReply
{
    if ([self.addressParts.firstObject isEqualToString:@"reply"])
        return YES;
    else
        return NO;
}

- (BOOL)isReplyFromCue
{
    if (!self.isReply)
        return NO;

    NSArray<NSString *> *parts = self.addressParts;

    // NOTE: We do not need to inspect the addresParts of this reply for the "cue" component.
    // - By convention, QLabKit sends all cue messages to QLab with the "/cue_id/" form.
    // - Thus, the addressParts of a reply to a QLabKit message will only contain "cue_id".

    // "long-form" reply
    // /reply/workspace/{id}/cue_id/{cue_id}/*
    if (parts.count > 5 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"cue_id"])
        return YES;

    // "short-form" reply
    // /reply/cue_id/{cue_id}/*
    if (parts.count > 2 && [parts[1] isEqualToString:@"cue_id"])
        return YES;

    return NO;
}

- (BOOL)isUpdate
{
    if ([self.addressParts.firstObject isEqualToString:@"update"])
        return YES;
    else
        return NO;
}

- (BOOL)isWorkspaceUpdate
{
    if (!self.isUpdate)
        return NO;

    // /update/workspace/{workspace_id}
    NSArray<NSString *> *parts = self.addressParts;

    return (parts.count == 3 && [parts[1] isEqualToString:@"workspace"]);
}

- (BOOL)isWorkspaceSettingsUpdate
{
    if (!self.isUpdate)
        return NO;

    // /update/workspace/{workspace_id}/settings/{settings_controller}
    NSArray<NSString *> *parts = self.addressParts;

    return (parts.count == 5 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"settings"]);
}

- (BOOL)isLightDashboardUpdate
{
    if (!self.isUpdate)
        return NO;

    // /update/workspace/{workspace_id}/dashboard
    NSArray<NSString *> *parts = self.addressParts;

    return (parts.count == 4 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"dashboard"]);
}

- (BOOL)isCueUpdate
{
    if (!self.isUpdate)
        return NO;

    // /update/workspace/{workspace_id}/cue_id/{cue_id}
    NSArray<NSString *> *parts = self.addressParts;

    // NOTE: We do not need to inspect the addresParts of this update for the "cue" component.
    // - All cue /update messages from QLab use the "/cue_id/" form.

    return (parts.count == 5 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"cue_id"]);
}

- (BOOL)isPlaybackPositionUpdate
{
    if (!self.isUpdate)
        return NO;

    // /update/workspace/{workspace_id}/cueList/{cue_list_id}/playbackPosition {cue_id}
    NSArray<NSString *> *parts = self.addressParts;

    return (parts.count == 6 && [parts[5] isEqualToString:@"playbackPosition"]);
}

- (BOOL)isPreferencesUpdate
{
    if (!self.isUpdate)
        return NO;

    // /update/preferences/{preferences_key}
    NSArray<NSString *> *parts = self.addressParts;

    return (parts.count == 3 && [parts[1] isEqualToString:@"preferences"]);
}

- (BOOL)isDisconnect
{
    if (!self.isUpdate)
        return NO;

    // /update/workspace/{workspace_id}/disconnect
    NSArray<NSString *> *parts = self.addressParts;

    return (parts.count == 4 && [parts[3] isEqualToString:@"disconnect"]);
}

- (nullable NSString *)host
{
    return self.OSCMessage.replySocket.host;
}

- (NSString *)address
{
    return self.OSCMessage.addressPattern;
}

- (NSArray<NSString *> *)addressParts
{
    if (self.addressPartsCache == nil)
    {
        NSArray<NSString *> *parts = [self.address componentsSeparatedByString:@"/"];
        if (parts.count > 0 && parts[0].length == 0)
            parts = [parts subarrayWithRange:NSMakeRange(1, parts.count - 1)];
        self.addressPartsCache = parts;
    }
    return self.addressPartsCache;
}

- (NSString *)replyAddress
{
    return (self.isReply ? [self.address substringFromIndex:[@"/reply" length]] : self.address);
}

- (NSString *)addressWithoutWorkspace:(nullable NSString *)workspaceID
{
    NSString *address = self.replyAddress;

    if (!workspaceID)
        return address;

    NSString *workspacePrefix = [NSString stringWithFormat:@"/workspace/%@", workspaceID];
    if (workspaceID && [address hasPrefix:workspacePrefix])
        return [address substringFromIndex:workspacePrefix.length];
    else
        return address;
}

- (nullable id)response
{
    if (!_response)
        [self deserializeReplyArguments];

    return _response;
}

- (nullable NSString *)status
{
    if (!_status)
        [self deserializeReplyArguments];

    return _status;
}

- (void)deserializeReplyArguments
{
    if (!self.isReply)
        return;

    if (!self.arguments.count)
        return;

    NSString *body = self.arguments.firstObject; // QLab replies have one argument, which is a JSON string.
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    if (!data)
    {
        NSLog(@"error decoding data: %@", self.arguments);
        return;
    }

    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!dict || error)
    {
        NSLog(@"error deserializing JSON: %@, %@", error, self.arguments);
        return;
    }

    if ([dict[@"status"] isKindOfClass:[NSString class]])
        _status = dict[@"status"];

    _response = dict[@"data"];
}

- (NSArray *)arguments
{
    return self.OSCMessage.arguments;
}

- (nullable NSString *)cueID
{
    if (self.isCueUpdate)
    {
        return self.addressParts[4];
    }
    else if (self.isPlaybackPositionUpdate)
    {
        return (self.arguments.count > 0 ? self.arguments[0] : nil);
    }
    else if (self.isReplyFromCue)
    {
        NSArray<NSString *> *parts = self.addressParts;

        // "long-form" reply
        // /reply/workspace/{id}/cue_id/{cue_id}/*
        if (parts.count > 5)
            return parts[4];

        // "short-form" reply
        // /reply/cue_id/{cue_id}/*
        else
            return parts[2];
    }
    else
    {
        return nil;
    }
}

@end

NS_ASSUME_NONNULL_END
