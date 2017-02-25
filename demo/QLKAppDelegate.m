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

#define REFRESH_INTERVAL 3 // seconds
#define AUTOMATIC_CONNECTION 1
#define QLAB_IP @"10.0.1.111"
#define QLAB_PORT 53000

@interface QLKAppDelegate ()

@property (strong) QLKBrowser *browser;
@property (strong) NSMutableArray *rows;

@property (strong) NSTimer *runningCuesTimer;

@end

@implementation QLKAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector( cuesUpdated: )
                                                 name:QLKCueCreatedNotification
                                               object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector( cuesUpdated: )
                                               name:QLKCueDeletedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector( cuesUpdated: )
                                               name:QLKCueOrderChangedNotification
                                             object:nil];
  
  
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector( playbackPositionUpdated: )
                                               name:QLKWorkspaceDidChangePlaybackPositionNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( cueListUpdated:) name:QLKWorkspaceDidUpdateCuesNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( cueListSelected: ) name:@"QLKCueListSelected" object:nil]; //can't work out how to expose the static object from the swift class...
  
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
        // Manual connect to server and get workspaces
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
  
    self.qlistDelegate = [[QLKCueListDelegate alloc] init];
    self.cueListTableView.dataSource = self.qlistDelegate;
    self.cueListTableView.delegate = self.qlistDelegate;
  
}


- (IBAction) go:(id)sender
{
//  if (self.cuesTableView.selectedRowIndexes.count > 0)
//  { //go with the selected cue
//    QLKCue *cue = [self.workspace.firstCueList.cues objectAtIndex: self.cuesTableView.selectedRowIndexes.firstIndex];
//    [cue start];
//    
//  } else
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
      if (self.runningCuesTimer != nil)
        [self.runningCuesTimer invalidate];
      
        [self.workspace disconnect];
        self.workspace = nil;
      
        self.cueList = nil;

        self.connectionLabel.stringValue = @"";
        [self.cuesOutlineView reloadData];
      
        self.qlistDelegate.workspace = nil;
        [self.cueListTableView reloadData];
    }
}

- (void) connect:(id)sender
{
    [self disconnect:nil];

    NSInteger selectedRow = self.serversTableView.selectedRow;
    if ( selectedRow == -1 )
        return;

    self.workspace = self.rows[selectedRow];
    self.qlistDelegate.workspace = self.workspace;
  
  
    [self.workspace connectWithPasscode:nil completion:^(id data)
    {
        NSLog(@"[app delegate] workspace did connect");
        self.connectionLabel.stringValue = [NSString stringWithFormat:@"Connected: %@", self.workspace.fullName];
      
        self.runningCuesTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                               target:self
                                                             selector:@selector(runningCuesTimerAction)
                                                             userInfo:nil
                                                              repeats:YES];
    }];
}

- (void) cuesUpdated:(NSNotification *)notification
{
  if (self.cueList == nil)
  {
    self.cueList = self.workspace.firstCueList;
  }
  [self.cuesOutlineView reloadData];
}

- (void) cueListUpdated:(NSNotification *)notification
{
  [self.cueListTableView reloadData];
}

- (void) cueListSelected:(NSNotification *)notification
{
  QLKCue *q = notification.object;
  self.cueList = q;
  [self.cuesOutlineView reloadData];
}

NSMutableArray *runningCues; //this is ugly, should notify to the cells and use custom cells maybe? this won't work for rows that are off the screen maybe?

- (void) runningCuesTimerAction
{
  
  if (runningCues == nil)
    runningCues = [[NSMutableArray alloc] init];
  [self.workspace runningOrPausedCuesWithBlock:^(id data)
  {
    if (![data isKindOfClass:[NSArray class]])
      return;
    
    for (QLKCue *q in runningCues)
    {
      
      if (!([self.cuesOutlineView rowForItem:q] >= 0))
        continue;
      
      [self.cuesOutlineView rowViewAtRow:[self.cuesOutlineView rowForItem:q] makeIfNecessary:YES].backgroundColor = [NSColor clearColor];
    }
    
    [runningCues removeAllObjects];
    
    NSArray *da = (NSArray*)data;
    
    for (NSDictionary *q in da)
    {
      QLKCue *cue = [self.workspace cueWithId:[q valueForKey:QLKOSCUIDKey]];
      
      if (!([self.cuesOutlineView rowForItem:cue]>=0))
        continue;
      
      [self.cuesOutlineView rowViewAtRow:[self.cuesOutlineView rowForItem:cue] makeIfNecessary:YES].backgroundColor = [NSColor redColor];
      
      [runningCues addObject:cue];
    }
    
    
  }];
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

- (void) serverDidUpdateWorkspaces:(QLKServer *)server
{
    [self updateView];
}


- (void) playbackPositionUpdated:(NSNotification*) notification
{
  
  if (![notification.object isKindOfClass:[QLKCue class]])
    return;
  
  QLKCue *cue = (QLKCue*)notification.object;

  
  if (![self.cuesOutlineView doesContain:cue])
  { //this row must be collapsed, so need to hunt for the cue
    //todo: should we be able to check that this cue is in our cue list?
    NSArray *location = [self recursiveFindCue:cue in:self.cueList];
    
    if (location == nil || location.count == 0)
      return; //give up
    
    //now expand all the items to find it
    QLKCue *q = self.cueList;
    
    for (NSNumber *num in location)
    {
    
      int index = num.intValue;
      [self.cuesOutlineView expandItem:[q.cues objectAtIndex: index]];
      q = [q.cues objectAtIndex:index];
    }
  
  }
  
  [self.cuesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex: [self.cuesOutlineView rowForItem:cue]] byExtendingSelection:NO];

  //NSLog(@" row for item %lu", [self.cuesOutlineView rowForItem:cue]);
  
}
//returns an array of the needles to find the item
//this is quite nifty, should be be in the class above?
- (NSArray*)recursiveFindCue:(QLKCue*)cue in: (QLKCue*) list
{
  //one of out cues is it
  if ([list.cues containsObject:cue])
  {
    return [NSArray arrayWithObject:[NSNumber numberWithInt:(int)[list.cues indexOfObject:cue]]];
  }
  //otherwise search through our cues for it
  for (QLKCue *q in list.cues)
  {
    if (q.hasChildren)
    {
      NSArray *halfResult = [self recursiveFindCue:cue in:q];
      if (halfResult != nil)
      {
        NSArray *result = [NSArray arrayWithObject:[NSNumber numberWithInt:(int)[list.cues indexOfObject:q]]];
        result = [NSArray arrayWithArray:[result arrayByAddingObjectsFromArray:halfResult]];
        return result;
      }
    }
  }
  
  return nil;

}
#pragma mark - NSOutlineViewDelegate

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil)
    return self.cueList.cues.count;
  
  QLKCue *q = (QLKCue*)item;

  return q.cues.count;
}

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  if (item == nil)
    return [self.cueList.cues objectAtIndex:index];
  QLKCue *q = (QLKCue*)item;
  return [q.cues objectAtIndex:index];

}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  QLKCue *q = (QLKCue*)item;
  return q.isGroup;
}


-(NSView *) outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  
  NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
  
  QLKCue *cue = (QLKCue*)item;
    
  cellView.textField.stringValue = ([tableColumn.identifier isEqualToString:QLKOSCNumberKey]) ? cue.number : [cue displayName];
  
  
  return cellView;
}
-(void) outlineViewSelectionDidChange:(NSNotification *)notification
{
  
  QLKCue *q =   [self.cuesOutlineView itemAtRow:
                 [self.cuesOutlineView selectedRow]];
  
  [self.workspace cue:self.cueList updatePropertySend:q.uid forKey:QLKOSCPlaybackPositionIdKey];
  
}


#pragma mark - NSTableViewDelegate

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
  return self.rows.count;
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];


    id obj = self.rows[row];
    cellView.textField.stringValue = ([obj isKindOfClass:[QLKServer class]]) ? [(QLKServer *)obj name].uppercaseString : [(QLKWorkspace *)obj name];
  
  
    return cellView;
}

- (BOOL) tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
  return [self.rows[row] isKindOfClass:[QLKServer class]];
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return ![self tableView:tableView isGroupRow:row];
}


#pragma mark - NSSplitViewDelegate

- (BOOL) splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    return (splitView.subviews[0] != view);
}


- (void)keyDown: (NSEvent *) event {
  NSLog(@"here");
}
@end
