//
//  QLKAppDelegate.h
//  QLabKit
//
//  Created by Zach Waugh on 7/8/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QLKBrowser.h"

@interface QLKAppDelegate : NSObject <NSApplicationDelegate, QLKBrowserDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSPopUpButton *qlab;

- (IBAction)go:(id)sender;
- (IBAction)stop:(id)sender;

@end
