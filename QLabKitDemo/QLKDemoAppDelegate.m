//
//  QLKDemoAppDelegate.m
//  QLabKitDemo
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

#import "QLKDemoAppDelegate.h"
#import "QLabKit.h"

#define REFRESH_INTERVAL        3 // seconds
#define AUTOMATIC_CONNECTION    1
#define QLAB_IP                 @"10.0.1.111"
#define QLAB_PORT               53000


NS_ASSUME_NONNULL_BEGIN

@interface QLKDemoAppDelegate ()

@property (strong) QLKBrowser *browser;
@property (strong) NSMutableArray *rows;

- (void) handleCueUpdated:(NSNotification *)notification;

@end


@implementation QLKDemoAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCueUpdated:)
                                                 name:QLKCueUpdatedNotification
                                               object:nil];
  
    self.rows = [NSMutableArray array];
  
    if ( AUTOMATIC_CONNECTION )
    {
        // Find QLab using continuously updating browser
        self.browser = [[QLKBrowser alloc] init];
        self.browser.delegate = self;
        [self.browser start];
        [self.browser enableAutoRefreshWithInterval:REFRESH_INTERVAL];
    }
    else
    {
        // Manually connect to server and get workspaces
        QLKServer *server = [[QLKServer alloc] initWithHost:QLAB_IP port:QLAB_PORT];
        server.name = @"QLab";
        [server refreshWorkspacesWithCompletion:^(NSArray<QLKWorkspace *> *workspaces)
        {
            [self.rows addObject:server];
            [self.rows addObjectsFromArray:server.workspaces];
            [self.serversTableView reloadData];
        }];
    }

    self.serversTableView.doubleAction = @selector(connect:);
    self.serversTableView.target = self;
}

- (IBAction) go:(id)sender
{
    [self.workspace go];
}

- (IBAction) stop:(id)sender
{
    [self.workspace stopAll];
}

- (IBAction) disconnect:(id)sender
{
    if ( self.workspace )
    {
        [self.workspace disconnect];
        _workspace = nil;

        self.connectionLabel.stringValue = @"";
        [self.cuesTableView reloadData];
    }
}

- (IBAction) update:(id)sender
{
    [self.cuesTableView reloadData];
}

- (void) connect:(id)sender
{
    [self disconnect:sender];

    NSInteger selectedRow = self.serversTableView.selectedRow;
    if ( selectedRow == -1 )
        return;

    self.workspace = self.rows[selectedRow];
    [self.workspace connectWithPasscode:nil completion:^(id data)
    {
        NSLog(@"[app delegate] workspace did connect");
        self.connectionLabel.stringValue = [NSString stringWithFormat:@"Connected: %@", self.workspace.fullName];
    }];
}

- (void) handleCueUpdated:(NSNotification *)notification
{
    QLKCue *cue = notification.object;
    if ( !cue )
        return;
    
    // coalesce multiple cue updates into a single call to reloadData
    [NSObject cancelPreviousPerformRequestsWithTarget:self.cuesTableView selector:@selector(reloadData) object:nil];
    [self.cuesTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.05];
}

- (void) updateView
{
    [self.rows removeAllObjects];
    
    for ( QLKServer *server in self.browser.servers )
    {
        [self.rows addObject:server];
        [self.rows addObjectsFromArray:server.workspaces];
    }
    
    [self.serversTableView reloadData];
}



#pragma mark - QLKBrowserDelegate

- (void) browserDidUpdateServers:(QLKBrowser *)browser
{
    [self updateView];
}

- (void) browserServerDidUpdateWorkspaces:(QLKServer *)server
{
    [self updateView];
}



#pragma mark - NSTableViewDelegate

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if ( tableView == self.serversTableView )
        return self.rows.count;
    else
        return [[self.workspace.firstCueList propertyForKey:QLKOSCCuesKey] count];
}

- (nullable NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];

    if ( tableView == self.serversTableView )
    {
        id obj = self.rows[row];
        
        if ( [obj isKindOfClass:[QLKServer class]] )
            cellView.textField.stringValue = ((QLKServer *)obj).name.uppercaseString;
        else
            cellView.textField.stringValue = ((QLKWorkspace *)obj).name;
    }
    else
    {
        QLKCue *cueList = self.workspace.firstCueList;
        NSArray<QLKCue *> *cues = [cueList propertyForKey:QLKOSCCuesKey];
        QLKCue *cue = cues[row];
        
        if ( [tableColumn.identifier isEqualToString:QLKOSCNumberKey] )
            cellView.textField.stringValue = cue.number;
        else
            cellView.textField.stringValue = cue.listName;
    }
  
    return cellView;
}

- (BOOL) tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    if ( tableView == self.serversTableView )
        return [self.rows[row] isKindOfClass:[QLKServer class]];
    else
        return NO;
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return ![self tableView:tableView isGroupRow:row];
}



#pragma mark - NSSplitViewDelegate

- (BOOL) splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    return ( splitView.subviews[0] != view );
}

@end

NS_ASSUME_NONNULL_END
