//
//  QLKDefines.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#if TARGET_OS_IPHONE
#define QLKImage UIImage
#define QLKColor UIColor
#else
#define QLKImage NSImage
#define QLKColor NSColor
#endif

typedef void (^QLRMessageHandlerBlock)(id data);
typedef void (^QLRWorkspaceHandlerBlock)(NSArray *workspaces, NSString *ip);
