//
//  QLKAppDelegate.m
//  QLabKit
//
//  Created by Zach Waugh on 7/8/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "QLKAppDelegate.h"
#import "QLabKit.h"

@interface QLKAppDelegate ()

@property (strong) QLKBrowser *browser;

@end

@implementation QLKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.browser = [[QLKBrowser alloc] init];
  self.browser.delegate = self;
  [self.browser startServers];
}

- (IBAction)go:(id)sender
{
  NSMenuItem *item = [self.qlab selectedItem];
  if (item.representedObject) {
    QLKWorkspace *workspace = item.representedObject;
    [workspace go];
  }
}

- (IBAction)stop:(id)sender
{
  NSMenuItem *item = [self.qlab selectedItem];
  if (item.representedObject) {
    QLKWorkspace *workspace = item.representedObject;
    [workspace stopAll];
  }
}

#pragma mark - QLKBrowserDelegate

- (void)browserDidUpdateServers:(QLKBrowser *)browser
{
  [self.qlab removeAllItems];
  
  for (QLKServer *server in browser.servers) {
    [self.qlab addItemWithTitle:server.name];
    for (QLKWorkspace *workspace in server.workspaces) {
      NSMenuItem *item = [[NSMenuItem alloc] init];
      item.title = workspace.name;
      item.representedObject = workspace;
      [self.qlab.menu addItem:item];
    }
    
    [self.qlab.menu addItem:[NSMenuItem separatorItem]];
  }
}

@end
