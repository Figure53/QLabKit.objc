//
//  QLKAppDelegate.m
//  QLabKitDemo
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

#import "QLKAppDelegate.h"
#import "QLabKit.h"

#define REFRESH_INTERVAL 5 // seconds

@interface QLKAppDelegate ()

@property (strong) QLKBrowser *browser;
@property (strong) NSMutableArray *rows;

@end

@implementation QLKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cuesUpdated:) name:QLKWorkspaceDidUpdateCuesNotification object:nil];
  
  self.rows = [NSMutableArray array];
  
  self.browser = [[QLKBrowser alloc] init];
  self.browser.delegate = self;
  [self.browser start];
  [self.browser enableAutoRefreshWithInterval:REFRESH_INTERVAL];
  
  self.qlab.doubleAction = @selector(connect:);
  self.qlab.target = self;
}

- (IBAction)go:(id)sender
{
  [self.workspace go];
}

- (IBAction)stop:(id)sender
{
  [self.workspace stopAll];
}

- (IBAction)disconnect:(id)sender
{
  if (self.workspace) {
    [self.workspace disconnect];
    self.workspace = nil;
    
    self.connectionLabel.stringValue = @"";
  }
}

- (void)connect:(id)sender
{
  [self disconnect:nil];
  
  NSInteger selectedRow = self.qlab.selectedRow;
  if (selectedRow == -1) return;
  
  self.workspace = self.rows[selectedRow];
  [self.workspace connectWithPasscode:nil completion:^(id data) {
    self.connectionLabel.stringValue = [NSString stringWithFormat:@"Connected: %@", self.workspace.fullName];
  }];
}

- (void)cuesUpdated:(NSNotification *)notification
{
  [self.cues reloadData];
}

#pragma mark - QLKBrowserDelegate

- (void)browserDidUpdateServers:(QLKBrowser *)browser
{
  [self.rows removeAllObjects];
  
  for (QLKServer *server in browser.servers) {
    [self.rows addObject:server];
    [self.rows addObjectsFromArray:server.workspaces];
  }
  
  [self.qlab reloadData];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return (tableView == self.qlab) ? self.rows.count : self.workspace.firstCueList.cues.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];

  if (tableView == self.qlab) {
    id obj = self.rows[row];
    cellView.textField.stringValue = [(QLKWorkspace *)obj name];
  } else {
    QLKCue *cue = self.workspace.firstCueList.cues[row];
    cellView.textField.stringValue = ([tableColumn.identifier isEqualToString:@"number"]) ? cue.number : cue.displayName;
  }
  
  return cellView;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
  return (tableView == self.qlab) ? [self.rows[row] isKindOfClass:[QLKServer class]] : NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
  return ![self tableView:tableView isGroupRow:row];
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
  return (splitView.subviews[0] != view);
}

@end
