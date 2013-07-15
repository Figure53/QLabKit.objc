//
//  QLKDefines.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#if TARGET_OS_IPHONE
#define QLKImage UIImage
#define QLKColorClass UIColor
#else
#define QLKImage NSImage
#define QLKColorClass NSColor
#endif

// Blocks
typedef void (^QLRMessageHandlerBlock)(id data);
typedef void (^QLRWorkspaceHandlerBlock)(NSArray *workspaces, NSString *ip);

// Bonjour
extern NSString * const QLKBonjourTCPServiceType;
extern NSString * const QLKBonjourUDPServiceType;
extern NSString * const QLKBonjourServiceDomain;