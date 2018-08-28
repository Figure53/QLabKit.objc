//
//  QLKDefines.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2011-2018 Figure 53 LLC, http://figure53.com
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

@import Foundation;


#if TARGET_OS_IPHONE
@import UIKit;
#define QLKImage UIImage
#define QLKColorClass UIColor
#else
@import AppKit;
#define QLKImage NSImage
#define QLKColorClass NSColor
#endif


NS_ASSUME_NONNULL_BEGIN

// Blocks
typedef void (^QLKMessageHandlerBlock)( id data );

// Bonjour
extern NSString * const QLKBonjourTCPServiceType;
extern NSString * const QLKBonjourUDPServiceType;
extern NSString * const QLKBonjourServiceDomain;

// Notifications
extern NSString * const QLKCueUpdatedNotification;
extern NSString * const QLKCueNeedsUpdateNotification;
extern NSString * const QLKCueListDidChangePlaybackPositionIDNotification;

// Cue types
extern NSString * const QLKCueTypeCue;
extern NSString * const QLKCueTypeCueList;
extern NSString * const QLKCueTypeCart;
extern NSString * const QLKCueTypeGroup;
extern NSString * const QLKCueTypeAudio;
extern NSString * const QLKCueTypeMic;
extern NSString * const QLKCueTypeVideo;
extern NSString * const QLKCueTypeCamera;
extern NSString * const QLKCueTypeText;
extern NSString * const QLKCueTypeLight;
extern NSString * const QLKCueTypeFade;
extern NSString * const QLKCueTypeNetwork;
extern NSString * const QLKCueTypeMIDI;
extern NSString * const QLKCueTypeMIDIFile;
extern NSString * const QLKCueTypeTimecode;
extern NSString * const QLKCueTypeStart;
extern NSString * const QLKCueTypeStop;
extern NSString * const QLKCueTypePause;
extern NSString * const QLKCueTypeLoad;
extern NSString * const QLKCueTypeReset;
extern NSString * const QLKCueTypeDevamp;
extern NSString * const QLKCueTypeGoto;
extern NSString * const QLKCueTypeTarget;
extern NSString * const QLKCueTypeArm;
extern NSString * const QLKCueTypeDisarm;
extern NSString * const QLKCueTypeWait;
extern NSString * const QLKCueTypeMemo;
extern NSString * const QLKCueTypeScript;
extern NSString * const QLKCueTypeStagetracker;

// v3 compatibility
extern NSString * const QLKCueTypeOSC;
extern NSString * const QLKCueTypeTitles;


// Continue mode type
typedef NS_ENUM( NSUInteger, QLKCueContinueMode ) {
    QLKCueContinueModeNoContinue = 0,
    QLKCueContinueModeAutoContinue,
    QLKCueContinueModeAutoFollow
};


extern NSString * const QLKOSCUIDKey;
extern NSString * const QLKOSCTypeKey;
extern NSString * const QLKOSCParentKey;
extern NSString * const QLKOSCNameKey;
extern NSString * const QLKOSCNumberKey;
extern NSString * const QLKOSCNotesKey;
extern NSString * const QLKOSCFileTargetKey;
extern NSString * const QLKOSCCueTargetNumberKey;
extern NSString * const QLKOSCCurrentCueTargetKey; // returns cue_id
extern NSString * const QLKOSCColorNameKey;
extern NSString * const QLKOSCFlaggedKey;
extern NSString * const QLKOSCArmedKey;
extern NSString * const QLKOSCContinueModeKey;
extern NSString * const QLKOSCPreWaitKey;
extern NSString * const QLKOSCPostWaitKey;
extern NSString * const QLKOSCCurrentDurationKey;
extern NSString * const QLKOSCPercentPreWaitElapsedKey;
extern NSString * const QLKOSCPercentPostWaitElapsedKey;
extern NSString * const QLKOSCPercentActionElapsedKey;
extern NSString * const QLKOSCPreWaitElapsedKey;
extern NSString * const QLKOSCPostWaitElapsedKey;
extern NSString * const QLKOSCActionElapsedKey;
extern NSString * const QLKOSCGroupModeKey;
extern NSString * const QLKOSCHasFileTargetsKey;
extern NSString * const QLKOSCHasCueTargetsKey;
extern NSString * const QLKOSCCartPositionKey;
extern NSString * const QLKOSCCartRowsKey;
extern NSString * const QLKOSCCartColumnsKey;
extern NSString * const QLKOSCAllowsEditingDurationKey;
extern NSString * const QLKOSCIsPanickingKey;
extern NSString * const QLKOSCIsTailingOutKey;
extern NSString * const QLKOSCIsRunningKey;
extern NSString * const QLKOSCIsLoadedKey;
extern NSString * const QLKOSCIsPausedKey;
extern NSString * const QLKOSCIsBrokenKey;
extern NSString * const QLKOSCIsOverriddenKey;
extern NSString * const QLKOSCTranslationXKey;
extern NSString * const QLKOSCTranslationYKey;
extern NSString * const QLKOSCScaleXKey;
extern NSString * const QLKOSCScaleYKey;
extern NSString * const QLKOSCOriginXKey;
extern NSString * const QLKOSCOriginYKey;
extern NSString * const QLKOSCQuaternionKey;
extern NSString * const QLKOSCSurfaceSizeKey;
extern NSString * const QLKOSCCueSizeKey;
extern NSString * const QLKOSCPreserveAspectRatioKey;
extern NSString * const QLKOSCLayerKey;
extern NSString * const QLKOSCPatchKey;
extern NSString * const QLKOSCPatchListKey;
extern NSString * const QLKOSCSurfaceListKey;
extern NSString * const QLKOSCCuesKey;
extern NSString * const QLKOSCListNameKey;
extern NSString * const QLKOSCSurfaceIDKey;
extern NSString * const QLKOSCFullSurfaceKey;
extern NSString * const QLKOSCOpacityKey;
extern NSString * const QLKOSCRotationZKey;
extern NSString * const QLKOSCRotationYKey;
extern NSString * const QLKOSCRotationXKey;
extern NSString * const QLKOSCPlaybackPositionIdKey; // NOTE: QLab OSC dictionary uses "Id" capitalization
extern NSString * const QLKOSCStartNextCueWhenSliceEndsKey;
extern NSString * const QLKOSCStopTargetWhenSliceEndsKey;
extern NSString * const QLKOSCSliderLevelKey;

// v3 compatibility
extern NSString * const QLKOSCDurationKey;
extern NSString * const QLKOSCFullScreenKey;


// Identifiers for "fake" cues
extern NSString * const QLKRootCueIdentifier;
extern NSString * const QLKActiveCuesIdentifier;

NS_ASSUME_NONNULL_END
