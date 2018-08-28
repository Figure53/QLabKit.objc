//
//  QLKDemoAppDelegate.h
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

@import Cocoa;

#import "QLKBrowser.h"
#import "QLKWorkspace.h"


NS_ASSUME_NONNULL_BEGIN

@interface QLKDemoAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate, QLKBrowserDelegate>

@property (strong) QLKWorkspace *workspace;
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *serversTableView;
@property (weak) IBOutlet NSTableView *cuesTableView;
@property (weak) IBOutlet NSTextField *connectionLabel;

- (IBAction) go:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) disconnect:(id)sender;
- (IBAction) update:(id)sender;

@end

NS_ASSUME_NONNULL_END
