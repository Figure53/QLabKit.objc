//
//  QLKDefines.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2011-2022 Figure 53 LLC, https://figure53.com
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

#import <Foundation/Foundation.h>


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define QLKColorClass UIColor
#else
#import <AppKit/AppKit.h>
#define QLKColorClass NSColor
#endif


NS_ASSUME_NONNULL_BEGIN

// Blocks
typedef void (^QLKMessageReplyBlock)(NSString *status, id _Nullable data);

// Bonjour
extern NSString *const QLKBonjourTCPServiceType;
extern NSString *const QLKBonjourUDPServiceType;
extern NSString *const QLKBonjourServiceDomain;

// Notifications
extern NSNotificationName const QLKCueUpdatedNotification;
extern NSNotificationName const QLKCueNeedsUpdateNotification;
extern NSNotificationName const QLKCueListDidChangePlaybackPositionIDNotification;

// Cue types
extern NSString *const QLKCueTypeCue;
extern NSString *const QLKCueTypeCueList;
extern NSString *const QLKCueTypeCart;
extern NSString *const QLKCueTypeGroup;
extern NSString *const QLKCueTypeAudio;
extern NSString *const QLKCueTypeMic;
extern NSString *const QLKCueTypeVideo;
extern NSString *const QLKCueTypeCamera;
extern NSString *const QLKCueTypeText;
extern NSString *const QLKCueTypeLight;
extern NSString *const QLKCueTypeFade;
extern NSString *const QLKCueTypeNetwork;
extern NSString *const QLKCueTypeMIDI;
extern NSString *const QLKCueTypeMIDIFile;
extern NSString *const QLKCueTypeTimecode;
extern NSString *const QLKCueTypeStart;
extern NSString *const QLKCueTypeStop;
extern NSString *const QLKCueTypePause;
extern NSString *const QLKCueTypeLoad;
extern NSString *const QLKCueTypeReset;
extern NSString *const QLKCueTypeDevamp;
extern NSString *const QLKCueTypeGoto;
extern NSString *const QLKCueTypeTarget;
extern NSString *const QLKCueTypeArm;
extern NSString *const QLKCueTypeDisarm;
extern NSString *const QLKCueTypeWait;
extern NSString *const QLKCueTypeMemo;
extern NSString *const QLKCueTypeScript;
extern NSString *const QLKCueTypeStagetracker;

// v3 compatibility
extern NSString *const QLKCueTypeOSC;
extern NSString *const QLKCueTypeTitles;

// Continue mode type
typedef NS_ENUM(NSUInteger, QLKCueContinueMode)
{
    QLKCueContinueModeNoContinue = 0,
    QLKCueContinueModeAutoContinue,
    QLKCueContinueModeAutoFollow
};

extern NSString *const QLKOSCUIDKey;
extern NSString *const QLKOSCTypeKey;
extern NSString *const QLKOSCParentKey;
extern NSString *const QLKOSCNameKey;
extern NSString *const QLKOSCNumberKey;
extern NSString *const QLKOSCNotesKey;
extern NSString *const QLKOSCFileTargetKey;
extern NSString *const QLKOSCCueTargetNumberKey;
extern NSString *const QLKOSCCurrentCueTargetKey; // returns cue_id
extern NSString *const QLKOSCColorNameKey;
extern NSString *const QLKOSCLiveColorNameKey;  // v5.0+
extern NSString *const QLKOSCColorConditionKey; // v5.0-5.1
extern NSString *const QLKOSCUseSecondColorKey; // v5.2+
extern NSString *const QLKOSCSecondColorNameKey; // v5.2+
extern NSString *const QLKOSCFlaggedKey;
extern NSString *const QLKOSCArmedKey;
extern NSString *const QLKOSCContinueModeKey;
extern NSString *const QLKOSCPreWaitKey;
extern NSString *const QLKOSCPostWaitKey;
extern NSString *const QLKOSCDurationKey; // NOTE: generally use QLKOSCCurrentDurationKey when connected to v4 and later
extern NSString *const QLKOSCCurrentDurationKey;
extern NSString *const QLKOSCPercentPreWaitElapsedKey;
extern NSString *const QLKOSCPercentPostWaitElapsedKey;
extern NSString *const QLKOSCPercentActionElapsedKey;
extern NSString *const QLKOSCPreWaitElapsedKey;
extern NSString *const QLKOSCPostWaitElapsedKey;
extern NSString *const QLKOSCActionElapsedKey;
extern NSString *const QLKOSCGroupModeKey;
extern NSString *const QLKOSCHasFileTargetsKey;
extern NSString *const QLKOSCHasCueTargetsKey;
extern NSString *const QLKOSCCartPositionKey;
extern NSString *const QLKOSCCartRowsKey;
extern NSString *const QLKOSCCartColumnsKey;
extern NSString *const QLKOSCAllowsEditingDurationKey;
extern NSString *const QLKOSCIsPanickingKey;
extern NSString *const QLKOSCIsCrossfadingOutKey;   // v5.0+
extern NSString *const QLKOSCIsAuditioningKey;      // v5.0+
extern NSString *const QLKOSCIsChildAuditioningKey; // v5.0+, Group cues only
extern NSString *const QLKOSCIsRunningKey;
extern NSString *const QLKOSCIsTailingOutKey;
extern NSString *const QLKOSCIsPausedKey;
extern NSString *const QLKOSCIsBrokenKey;
extern NSString *const QLKOSCIsOverriddenKey;
extern NSString *const QLKOSCIsWarningKey; // v5.0+
extern NSString *const QLKOSCIsLoadedKey;
extern NSString *const QLKOSCIsChildFlaggedKey; // v5.0+, Group cues only
extern NSString *const QLKOSCTranslationXKey;   // v5.0+
extern NSString *const QLKOSCTranslationYKey;   // v5.0+
extern NSString *const QLKOSCScaleXKey;         // v5.0+
extern NSString *const QLKOSCScaleYKey;         // v5.0+
extern NSString *const QLKOSCAnchorXKey;        // v5.0.2+
extern NSString *const QLKOSCAnchorYKey;        // v5.0.2+
extern NSString *const QLKOSCQuaternionKey;
extern NSString *const QLKOSCCueSizeKey;
extern NSString *const QLKOSCPreserveAspectRatioKey;
extern NSString *const QLKOSCFillStyleKey; // v5.2+
extern NSString *const QLKOSCLayerKey;
extern NSString *const QLKOSCAudioOutputPatchIDKey;
extern NSString *const QLKOSCCuesKey;
extern NSString *const QLKOSCListNameKey;
extern NSString *const QLKOSCStageIDKey;
extern NSString *const QLKOSCFillStageKey;
extern NSString *const QLKOSCOpacityKey;
extern NSString *const QLKOSCSmoothKey;  // v5.0+
extern NSString *const QLKOSCRotateXKey; // v5.0+
extern NSString *const QLKOSCRotateYKey; // v5.0+
extern NSString *const QLKOSCRotateZKey; // v5.0+
extern NSString *const QLKOSCPlaybackPositionIDKey;
extern NSString *const QLKOSCStartNextCueWhenSliceEndsKey;
extern NSString *const QLKOSCStopTargetWhenSliceEndsKey;
extern NSString *const QLKOSCSliderLevelKey;
extern NSString *const QLKOSCFadeLevelsModeKey;

// Identifiers for "fake" cues
extern NSString *const QLKRootCueIdentifier;
extern NSString *const QLKActiveCuesIdentifier;

// Legacy compatibility
// v3.x
extern NSString *const QLKOSCFullScreenKey;
// v4.x and earlier
extern NSString *const QLKOSCSurfaceListKey;
extern NSString *const QLKOSCSurfaceIDKey;
extern NSString *const QLKOSCSurfaceSizeKey;
extern NSString *const QLKOSCFullSurfaceKey;
extern NSString *const QLKOSCV4PlaybackPositionIdKey; // NOTE: "Id" capitalization prior to v5
extern NSString *const QLKOSCV4PatchKey;
extern NSString *const QLKOSCV4PatchListKey;
extern NSString *const QLKOSCV4TranslationXKey;
extern NSString *const QLKOSCV4TranslationYKey;
extern NSString *const QLKOSCV4ScaleXKey;
extern NSString *const QLKOSCV4ScaleYKey;
extern NSString *const QLKOSCV4OriginXKey;
extern NSString *const QLKOSCV4OriginYKey;
extern NSString *const QLKOSCV4RotateXKey;
extern NSString *const QLKOSCV4RotateYKey;
extern NSString *const QLKOSCV4RotateZKey;
extern NSString *const QLKOSCV4FadeLevelsModeKey;
// v5.0.x
extern NSString *const QLKOSCOriginXKey;
extern NSString *const QLKOSCOriginYKey;

NS_ASSUME_NONNULL_END
