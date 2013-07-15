//
//  QLKAppDelegate.m
//  QLabKit
//
//  Created by Zach Waugh on 7/8/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
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
  self.rows = [NSMutableArray array];
  
  self.browser = [[QLKBrowser alloc] init];
  self.browser.delegate = self;
  [self.browser start];
  [self.browser enableAutoRefreshWithInterval:REFRESH_INTERVAL];
  
  self.tableView.doubleAction = @selector(connect:);
  self.tableView.target = self;
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
  
  NSInteger selectedRow = self.tableView.selectedRow;
  if (selectedRow == -1) return;
  
  self.workspace = self.rows[selectedRow];
  [self.workspace connectToWorkspaceWithPasscode:nil completion:^(id data) {
    self.connectionLabel.stringValue = [NSString stringWithFormat:@"Connected: %@", self.workspace.fullName];
  }];
}

#pragma mark - QLKBrowserDelegate

- (void)browserDidUpdateServers:(QLKBrowser *)browser
{
  [self.rows removeAllObjects];
  
  for (QLKServer *server in browser.servers) {
    [self.rows addObject:server];
    [self.rows addObjectsFromArray:server.workspaces];
  }
  
  [self.tableView reloadData];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return self.rows.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  id obj = self.rows[row];
  
  NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
  
  cellView.textField.stringValue = [(QLKWorkspace *)obj name];

  return cellView;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
  return [self.rows[row] isKindOfClass:[QLKServer class]];
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
