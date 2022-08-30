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

#import "QLKDefines.h"


NS_ASSUME_NONNULL_BEGIN

NSString *const QLKBonjourTCPServiceType = @"_qlab._tcp.";
NSString *const QLKBonjourUDPServiceType = @"_qlab._udp.";
NSString *const QLKBonjourServiceDomain = @"local.";

// Notifications
NSNotificationName const QLKCueUpdatedNotification = @"QLKCueUpdatedNotification";
NSNotificationName const QLKCueNeedsUpdateNotification = @"QLKCueNeedsUpdateNotification";
NSNotificationName const QLKCueListDidChangePlaybackPositionIDNotification = @"QLKCueListDidChangePlaybackPositionIDNotification";

// Cue Types
NSString *const QLKCueTypeCue = @"Cue";
NSString *const QLKCueTypeCueList = @"Cue List";
NSString *const QLKCueTypeCart = @"Cart";
NSString *const QLKCueTypeGroup = @"Group";
NSString *const QLKCueTypeAudio = @"Audio";
NSString *const QLKCueTypeMic = @"Mic";
NSString *const QLKCueTypeVideo = @"Video";
NSString *const QLKCueTypeCamera = @"Camera";
NSString *const QLKCueTypeText = @"Text";
NSString *const QLKCueTypeLight = @"Light";
NSString *const QLKCueTypeFade = @"Fade";
NSString *const QLKCueTypeNetwork = @"Network";
NSString *const QLKCueTypeMIDI = @"MIDI";
NSString *const QLKCueTypeMIDIFile = @"MIDI File";
NSString *const QLKCueTypeTimecode = @"Timecode";
NSString *const QLKCueTypeStart = @"Start";
NSString *const QLKCueTypeStop = @"Stop";
NSString *const QLKCueTypePause = @"Pause";
NSString *const QLKCueTypeLoad = @"Load";
NSString *const QLKCueTypeReset = @"Reset";
NSString *const QLKCueTypeDevamp = @"Devamp";
NSString *const QLKCueTypeGoto = @"GoTo";
NSString *const QLKCueTypeTarget = @"Target";
NSString *const QLKCueTypeArm = @"Arm";
NSString *const QLKCueTypeDisarm = @"Disarm";
NSString *const QLKCueTypeWait = @"Wait";
NSString *const QLKCueTypeMemo = @"Memo";
NSString *const QLKCueTypeScript = @"Script";
NSString *const QLKCueTypeStagetracker = @"Stagetracker";

// v3 compatibility
NSString *const QLKCueTypeOSC = @"OSC";
NSString *const QLKCueTypeTitles = @"Titles";

// OSC key constants
NSString *const QLKOSCUIDKey = @"uniqueID";
NSString *const QLKOSCTypeKey = @"type";
NSString *const QLKOSCParentKey = @"parent";
NSString *const QLKOSCNameKey = @"name";
NSString *const QLKOSCNumberKey = @"number";
NSString *const QLKOSCNotesKey = @"notes";
NSString *const QLKOSCFileTargetKey = @"fileTarget";
NSString *const QLKOSCCueTargetNumberKey = @"cueTargetNumber";
NSString *const QLKOSCCurrentCueTargetKey = @"currentCueTarget";
NSString *const QLKOSCColorNameKey = @"colorName";
NSString *const QLKOSCLiveColorNameKey = @"colorName/live";
NSString *const QLKOSCColorConditionKey = @"colorCondition";
NSString *const QLKOSCFlaggedKey = @"flagged";
NSString *const QLKOSCArmedKey = @"armed";
NSString *const QLKOSCContinueModeKey = @"continueMode";
NSString *const QLKOSCPreWaitKey = @"preWait";
NSString *const QLKOSCPostWaitKey = @"postWait";
NSString *const QLKOSCDurationKey = @"duration";
NSString *const QLKOSCCurrentDurationKey = @"currentDuration";
NSString *const QLKOSCPercentPreWaitElapsedKey = @"percentPreWaitElapsed";
NSString *const QLKOSCPercentPostWaitElapsedKey = @"percentPostWaitElapsed";
NSString *const QLKOSCPercentActionElapsedKey = @"percentActionElapsed";
NSString *const QLKOSCPreWaitElapsedKey = @"preWaitElapsed";
NSString *const QLKOSCPostWaitElapsedKey = @"postWaitElapsed";
NSString *const QLKOSCActionElapsedKey = @"actionElapsed";
NSString *const QLKOSCGroupModeKey = @"mode";
NSString *const QLKOSCCartPositionKey = @"cartPosition";
NSString *const QLKOSCCartRowsKey = @"cartRows";
NSString *const QLKOSCCartColumnsKey = @"cartColumns";
NSString *const QLKOSCHasFileTargetsKey = @"hasFileTargets";
NSString *const QLKOSCHasCueTargetsKey = @"hasCueTargets";
NSString *const QLKOSCAllowsEditingDurationKey = @"allowsEditingDuration";
NSString *const QLKOSCIsPanickingKey = @"isPanicking";
NSString *const QLKOSCIsCrossfadingOutKey = @"isCrossfadingOut";
NSString *const QLKOSCIsAuditioningKey = @"isAuditioning";
NSString *const QLKOSCIsChildAuditioningKey = @"isChildAuditioning";
NSString *const QLKOSCIsRunningKey = @"isRunning";
NSString *const QLKOSCIsTailingOutKey = @"isTailingOut";
NSString *const QLKOSCIsPausedKey = @"isPaused";
NSString *const QLKOSCIsBrokenKey = @"isBroken";
NSString *const QLKOSCIsOverriddenKey = @"isOverridden";
NSString *const QLKOSCIsWarningKey = @"isWarning";
NSString *const QLKOSCIsLoadedKey = @"isLoaded";
NSString *const QLKOSCIsChildFlaggedKey = @"isChildFlagged";
NSString *const QLKOSCTranslationXKey = @"translation/x";
NSString *const QLKOSCTranslationYKey = @"translation/y";
NSString *const QLKOSCScaleXKey = @"scale/x";
NSString *const QLKOSCScaleYKey = @"scale/y";
NSString *const QLKOSCOriginXKey = @"origin/x";
NSString *const QLKOSCOriginYKey = @"origin/y";
NSString *const QLKOSCQuaternionKey = @"quaternion";
NSString *const QLKOSCCueSizeKey = @"cueSize";
NSString *const QLKOSCPreserveAspectRatioKey = @"preserveAspectRatio";
NSString *const QLKOSCLayerKey = @"layer";
NSString *const QLKOSCAudioOutputPatchIDKey = @"audioOutputPatchID";
NSString *const QLKOSCCuesKey = @"cues";
NSString *const QLKOSCListNameKey = @"listName";
NSString *const QLKOSCStageIDKey = @"stageID";
NSString *const QLKOSCFillStageKey = @"fillStage";
NSString *const QLKOSCOpacityKey = @"opacity";
NSString *const QLKOSCRotateXKey = @"rotate/x";
NSString *const QLKOSCRotateYKey = @"rotate/y";
NSString *const QLKOSCRotateZKey = @"rotate/z";
NSString *const QLKOSCPlaybackPositionIDKey = @"playbackPositionID";
NSString *const QLKOSCStartNextCueWhenSliceEndsKey = @"startNextCueWhenSliceEnds";
NSString *const QLKOSCStopTargetWhenSliceEndsKey = @"stopTargetWhenSliceEnds";
NSString *const QLKOSCSliderLevelKey = @"sliderLevel";
NSString *const QLKOSCFadeLevelsModeKey = @"levelsMode";

// Identifiers for "fake" cues
NSString *const QLKRootCueIdentifier = @"__root__";
NSString *const QLKActiveCuesIdentifier = @"__active__";

// Legacy compatibility
// v3.x
NSString *const QLKOSCFullScreenKey = @"fullScreen";
// v4.x and earlier
NSString *const QLKOSCSurfaceListKey = @"surfaceList";
NSString *const QLKOSCSurfaceIDKey = @"surfaceID";
NSString *const QLKOSCSurfaceSizeKey = @"surfaceSize";
NSString *const QLKOSCFullSurfaceKey = @"fullSurface";
NSString *const QLKOSCV4PlaybackPositionIdKey = @"playbackPositionId";
NSString *const QLKOSCV4PatchKey = @"patch";
NSString *const QLKOSCV4PatchListKey = @"patchList";
NSString *const QLKOSCV4TranslationXKey = @"translationX";
NSString *const QLKOSCV4TranslationYKey = @"translationY";
NSString *const QLKOSCV4ScaleXKey = @"scaleX";
NSString *const QLKOSCV4ScaleYKey = @"scaleY";
NSString *const QLKOSCV4OriginXKey = @"originX";
NSString *const QLKOSCV4OriginYKey = @"originY";
NSString *const QLKOSCV4RotateXKey = @"rotateX";
NSString *const QLKOSCV4RotateYKey = @"rotateY";
NSString *const QLKOSCV4RotateZKey = @"rotateZ";
NSString *const QLKOSCV4FadeLevelsModeKey = @"mode";

NS_ASSUME_NONNULL_END
