//
//  QLKAppDelegate.h
//  QLabKit
//
//  Created by Zach Waugh on 7/8/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QLKBrowser.h"

@interface QLKAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate, QLKBrowserDelegate>

@property (strong) QLKWorkspace *workspace;
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *qlab;
@property (weak) IBOutlet NSTableView *cues;
@property (weak) IBOutlet NSTextField *connectionLabel;

- (IBAction)go:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)disconnect:(id)sender;

@end
