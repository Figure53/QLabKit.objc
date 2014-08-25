//
//  QLKDefines.h
//  QLabKit
//
//  Created by Zach Waugh on 7/9/13.
//
//  Copyright (c) 2011-2014 Figure 53 LLC, http://figure53.com
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

#if TARGET_OS_IPHONE
#define QLKImage UIImage
#define QLKColorClass UIColor
#else
#define QLKImage NSImage
#define QLKColorClass NSColor
#endif

// Blocks
typedef void (^QLKMessageHandlerBlock)(id data);

// Bonjour
extern NSString * const QLKBonjourTCPServiceType;
extern NSString * const QLKBonjourUDPServiceType;
extern NSString * const QLKBonjourServiceDomain;

// Notifications (moved from QLKCue.h)
extern NSString * const QLKCueUpdatedNotification;
extern NSString * const QLKCueNeedsUpdateNotification;
extern NSString * const QLKCueEditCueNotification;
extern NSString * const QLKCueHasNewDataNotification;

// Cue types (moved from QLKCue.h)
extern NSString * const QLKCueTypeCue;
extern NSString * const QLKCueTypeGroup;
extern NSString * const QLKCueTypeAudio;
extern NSString * const QLKCueTypeFade;
extern NSString * const QLKCueTypeMicrophone;
extern NSString * const QLKCueTypeVideo;
extern NSString * const QLKCueTypeAnimation;
extern NSString * const QLKCueTypeCamera;
extern NSString * const QLKCueTypeMIDI;
extern NSString * const QLKCueTypeMIDISysEx;
extern NSString * const QLKCueTypeTimecode;
extern NSString * const QLKCueTypeMTC;
extern NSString * const QLKCueTypeMSC;
extern NSString * const QLKCueTypeStop;
extern NSString * const QLKCueTypeMIDIFile;
extern NSString * const QLKCueTypePause;
extern NSString * const QLKCueTypeReset;
extern NSString * const QLKCueTypeStart;
extern NSString * const QLKCueTypeDevamp;
extern NSString * const QLKCueTypeLoad;
extern NSString * const QLKCueTypeScript;
extern NSString * const QLKCueTypeGoto;
extern NSString * const QLKCueTypeTarget;
extern NSString * const QLKCueTypeWait;
extern NSString * const QLKCueTypeMemo;
extern NSString * const QLKCueTypeArm;
extern NSString * const QLKCueTypeDisarm;
extern NSString * const QLKCueTypeStagetracker;

// Special cue identifiers (moved from QLKCue.h)
extern NSString * const QLKActiveCueListIdentifier;
extern NSString * const QLKRootCueIdentifier;

// Continue mode type (moved from QLKCue.h)
typedef enum {
    QLKCueContinueModeNoContinue,
    QLKCueContinueModeAutoContinue,
    QLKCueContinueModeAutoFollow
} QLKCueContinueMode;


extern NSString * const QLKOSCUIDKey;
extern NSString * const QLKOSCTypeKey;
extern NSString * const QLKOSCNameKey;
extern NSString * const QLKOSCNumberKey;
extern NSString * const QLKOSCNotesKey;
extern NSString * const QLKOSCColorNameKey;
extern NSString * const QLKOSCFlaggedKey;
extern NSString * const QLKOSCArmedKey;
extern NSString * const QLKOSCContinueModeKey;
extern NSString * const QLKOSCPreWaitKey;
extern NSString * const QLKOSCPostWaitKey;
extern NSString * const QLKOSCDurationKey;
extern NSString * const QLKOSCTranslationXKey;
extern NSString * const QLKOSCTranslationYKey;
extern NSString * const QLKOSCScaleXKey;
extern NSString * const QLKOSCScaleYKey;
extern NSString * const QLKOSCPreserveAspectRatioKey;
extern NSString * const QLKOSCLayerKey;
extern NSString * const QLKOSCPatchKey;
extern NSString * const QLKOSCPatchListKey;
extern NSString * const QLKOSCSurfaceListKey;
extern NSString * const QLKOSCCuesKey;
extern NSString * const QLKOSCListNameKey;
extern NSString * const QLKOSCSurfaceIDKey;
extern NSString * const QLKOSCFullScreenKey;
extern NSString * const QLKOSCOpacityKey;
extern NSString * const QLKOSCRotationZKey;
extern NSString * const QLKOSCRotationYKey;
extern NSString * const QLKOSCRotationXKey;
extern NSString * const QLKOSCPlaybackPositionIdKey;
extern NSString * const QLKOSCStartNextCueWhenSliceEndsKey;
extern NSString * const QLKOSCStopTargetWhenSliceEndsKey;
extern NSString * const QLKOSCSliderLevelKey;

// Identifiers for "fake" cues (moved from QLKCue.h)
extern NSString * const QLKActiveCueListIdentifier;
extern NSString * const QLKRootCueIdentifier;