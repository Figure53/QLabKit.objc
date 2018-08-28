//
//  QLKMessage.m
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

#import "QLKMessage.h"

#import "F53OSCMessage.h"


NS_ASSUME_NONNULL_BEGIN

@interface QLKMessage ()

@property (strong) F53OSCMessage *OSCMessage;

@end


@implementation QLKMessage

+ (QLKMessage *) messageWithOSCMessage:(F53OSCMessage *)message
{
    return [[QLKMessage alloc] initWithOSCMessage:message];
}

- (instancetype) initWithOSCMessage:(F53OSCMessage *)message
{
    self = [super init];
    if ( self )
    {
        _OSCMessage = message;
    }
    return self;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"address: %@, arguments: %@", self.address, [self.arguments componentsJoinedByString:@" - "]];
}



#pragma mark -

- (BOOL) isReply
{
    return [self.OSCMessage.addressPattern hasPrefix:@"/reply"];
}

- (BOOL) isReplyFromCue
{
    // /reply/cue_id/1/action
    return [self.address hasPrefix:@"/reply/cue_id"];
}

- (BOOL) isUpdate
{
    return [self.OSCMessage.addressPattern hasPrefix:@"/update"];
}

- (BOOL) isWorkspaceUpdate
{
    // /update/workspace/{workspace_id}
    NSArray<NSString *> *parts = self.addressParts;
    
    return ( parts.count == 3 && [parts[1] isEqualToString:@"workspace"] );
}

- (BOOL) isWorkspaceSettingsUpdate
{
    // /update/workspace/{workspace_id}/settings/{settings_controller}
    NSArray<NSString *> *parts = self.addressParts;
    
    return ( parts.count == 5 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"settings"] );
}

- (BOOL) isLightDashboardUpdate
{
    // /update/workspace/{workspace_id}/dashboard
    NSArray<NSString *> *parts = self.addressParts;
    
    return ( parts.count == 4 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"dashboard"] );
}

- (BOOL) isCueUpdate
{
    // /update/workspace/{workspace_id}/cue_id/{cue_id}
    NSArray<NSString *> *parts = self.addressParts;
    
    return ( parts.count == 5 && [parts[1] isEqualToString:@"workspace"] && [parts[3] isEqualToString:@"cue_id"] );
}

- (BOOL) isPlaybackPositionUpdate
{
    // /update/workspace/{workspace_id}/cueList/{cue_list_id}/playbackPosition {cue_id}
    NSArray<NSString *> *parts = self.addressParts;
    
    return ( parts.count == 6 && [self.address hasSuffix:@"/playbackPosition"] );
}

- (BOOL) isPreferencesUpdate
{
    // /update/preferences/{preferences_key}
    NSArray<NSString *> *parts = self.addressParts;
    
    return ( parts.count == 3 && [parts[1] isEqualToString:@"preferences"] );
}

- (BOOL) isDisconnect
{
    // /update/workspace/{workspace_id}/disconnect
    NSArray<NSString *> *parts = self.addressParts;
    
    return ( parts.count == 4 && [parts[3] isEqualToString:@"disconnect"] );
}

- (nullable NSString *) host
{
    return self.OSCMessage.replySocket.host;
}

- (NSString *) address
{
    return self.OSCMessage.addressPattern;
}

- (NSArray<NSString *> *) addressParts
{
    NSArray<NSString *> *parts = self.address.pathComponents;
    return [parts subarrayWithRange:NSMakeRange( 1, parts.count - 1 )];
}

- (NSString *) replyAddress
{
    return ( self.isReply ? [self.address substringFromIndex:@"/reply".length] : self.address );
}

- (NSString *) addressWithoutWorkspace:(nullable NSString *)workspaceID
{
    NSString *address = self.replyAddress;
    
    if ( !workspaceID )
        return address;
    
    NSString *workspacePrefix = [NSString stringWithFormat:@"/workspace/%@", workspaceID];
    if ( workspaceID && [address hasPrefix:workspacePrefix] )
        return [address substringFromIndex:workspacePrefix.length];
    else
        return address;
}

- (nullable id) response
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

- (NSArray *) arguments
{
    return self.OSCMessage.arguments;
}

- (nullable NSString *) cueID
{
    if ( self.isCueUpdate )
    {
        return self.addressParts[4];
    }
    else if ( self.isPlaybackPositionUpdate )
    {
        return ( self.arguments.count > 0 ? self.arguments[0] : nil );
    }
    else if ( self.isReplyFromCue )
    {
        return self.addressParts[2];
    }
    else
    {
        return nil;
    }
}

@end

NS_ASSUME_NONNULL_END
