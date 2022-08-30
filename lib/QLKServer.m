//
//  QLKServer.m
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

#import "QLKServer.h"

#import "QLKBrowser.h"
#import "QLKClient.h"
#import "QLKMessage.h"
#import "QLKWorkspace.h"


NS_ASSUME_NONNULL_BEGIN

@interface QLKServer ()

@property (nonatomic, strong, readwrite) QLKClient *client;
@property (nonatomic, strong, readwrite, nullable) NSString *hostVersion;
@property (nonatomic, strong, readwrite) NSArray<QLKWorkspace *> *workspaces;
@property (nonatomic, strong, nullable) NSTimer *refreshTimer;

- (void)updateWorkspaces:(NSArray<NSDictionary *> *)workspaceDicts;

@end


@implementation QLKServer

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port
{
    // Create a private client that we'll use for querying the list of workspaces on the QLab server.
    // (Usually a QLKClient is associated with a specific workspace, but not in this case.)
    QLKClient *client = [[QLKClient alloc] initWithHost:host port:port];
    client.useTCP = YES;
    return [self initWithHost:host port:port client:client];
}

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port client:(QLKClient *)client
{
    self = [super init];
    if (self)
    {
        if (port == 0)
            port = 53000;

        _host = host;
        _port = port;
        _name = host;
        _netService = nil;
        _workspaces = @[];

        self.client = client;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    self.delegate = nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@ - %@:%ld", super.description, self.name, self.host, (long)self.port];
}

- (BOOL)isConnected
{
    return self.client.isConnected;
}

- (nullable NSString *)hostVersion
{
    if (!_hostVersion)
    {
        __weak typeof(self) weakSelf = self;
        [self.client sendMessagesWithArguments:nil
                                     toAddress:@"/version"
                                     workspace:NO
                                         block:^(NSString *status, id _Nullable data) {
                                             __strong typeof(weakSelf) strongSelf = weakSelf;
                                             if (!strongSelf)
                                                 return;

                                             if ([data isKindOfClass:[NSString class]])
                                             {
                                                 strongSelf->_hostVersion = data;

                                                 if ([strongSelf.delegate respondsToSelector:@selector(serverDidUpdateHostVersion:)])
                                                     [strongSelf.delegate serverDidUpdateHostVersion:strongSelf];
                                             }
                                         }];
    }

    return _hostVersion;
}


#pragma mark - Workspaces

- (void)updateWorkspaces:(NSArray<NSDictionary *> *)workspaceDicts
{
    NSMutableArray<QLKWorkspace *> *newWorkspaces = [NSMutableArray array];
    for (NSDictionary<NSString *, NSObject<NSCopying> *> *aWorkspaceDict in workspaceDicts)
    {
        NSString *uniqueID = (NSString *)aWorkspaceDict[QLKOSCUIDKey];
        if (!uniqueID)
            continue;

        QLKWorkspace *workspace = nil;

        // Check first if a workspace with this ID was already added during this update,
        // e.g. if QLab has two workspaces with the same Unique ID currently open.
        NSUInteger index = [newWorkspaces indexOfObjectPassingTest:^BOOL(QLKWorkspace *obj, NSUInteger idx, BOOL *stop) {
            return [obj.uniqueID isEqual:uniqueID];
        }];
        if (index != NSNotFound)
            workspace = [newWorkspaces objectAtIndex:index];

        // If not, then check if this server already has a QLKWorkspace for this ID from a previous update.
        if (!workspace)
        {
            workspace = [self workspaceWithID:(NSString *_Nonnull)uniqueID];
            if (workspace)
                [newWorkspaces addObject:workspace];
        }

        // Update an existing workspace, else create a new workspace.
        if (workspace)
        {
            [workspace updateWithDictionary:aWorkspaceDict];
        }
        else
        {
            workspace = [self newWorkspaceWithDictionary:aWorkspaceDict];
            [newWorkspaces addObject:workspace];
        }
    }

    self.workspaces = [NSArray arrayWithArray:newWorkspaces];

    [self.delegate serverDidUpdateWorkspaces:self];
}

- (void)refreshWorkspaces
{
    if (!self.client.isConnected && ![self.client connect])
    {
        NSLog(@"Error: QLKServer unable to connect to QLab server: %@:%ld", self.host, (long)self.port);
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.client sendMessagesWithArguments:nil
                                 toAddress:@"/workspaces"
                                 workspace:NO
                                     block:^(NSString *status, id _Nullable data) {
                                         __strong typeof(weakSelf) strongSelf = weakSelf;
                                         if (!strongSelf)
                                             return;

                                         if ([data isKindOfClass:[NSArray class]] == NO)
                                             return;

                                         [strongSelf updateWorkspaces:(NSArray *)data];
                                     }];
}

- (void)refreshWorkspacesWithCompletion:(nullable void (^)(NSArray<QLKWorkspace *> *workspaces))completion
{
    if (!self.client.isConnected && ![self.client connect])
    {
        NSLog(@"Error: QLKServer unable to connect to QLab server: %@:%ld", self.host, (long)self.port);
        if (completion)
            completion(@[]);
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.client sendMessagesWithArguments:nil
                                 toAddress:@"/workspaces"
                                 workspace:NO
                                     block:^(NSString *status, id _Nullable data) {
                                         __strong typeof(weakSelf) strongSelf = weakSelf;
                                         if (!strongSelf)
                                             return;

                                         if ([data isKindOfClass:[NSArray class]])
                                         {
                                             [strongSelf updateWorkspaces:(NSArray *)data];
                                             if (completion)
                                                 completion(strongSelf.workspaces);
                                         }
                                         else // unexpected reply format
                                         {
                                             if (completion)
                                                 completion(@[]);
                                         }
                                     }];
}

- (void)enableAutoRefreshWithInterval:(NSTimeInterval)interval
{
    if (!self.refreshTimer)
    {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(refreshWorkspaces)
                                                           userInfo:nil
                                                            repeats:YES];
    }
}

- (QLKWorkspace *)newWorkspaceWithDictionary:(NSDictionary<NSString *, NSObject<NSCopying> *> *)dict
{
    // subclasses can override to customize QLKWorkspace returned, if desired
    QLKWorkspace *workspace = [[QLKWorkspace alloc] initWithDictionary:dict server:self];
    return workspace;
}

- (nullable QLKWorkspace *)workspaceWithID:(NSString *)uniqueID
{
    for (QLKWorkspace *aWorkspace in self.workspaces)
    {
        if ([aWorkspace.uniqueID isEqualToString:uniqueID])
            return aWorkspace;
    }

    // else
    return nil;
}

- (void)disableAutoRefresh
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)removeAllWorkspaces
{
    self.workspaces = @[];
}

- (void)stop
{
    [self disableAutoRefresh];
    [self.client disconnect];
    [self removeAllWorkspaces]; // IMPORTANT: Servers hold strong references to the workspaces they create, and workspaces hold a strong reference to their QLKServer. So when stopping, we must break the retain cycle by emptying the `workspaces` array here, thus allowing unused servers to dealloc.
}

- (void)sendOscMessage:(F53OSCMessage *)message
{
    [self sendOscMessage:message block:nil];
}

- (void)sendOscMessage:(F53OSCMessage *)message block:(nullable QLKMessageReplyBlock)block
{
    [self.client sendOscMessage:message block:block];
}

@end

NS_ASSUME_NONNULL_END
