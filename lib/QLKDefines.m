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

#import "QLKDefines.h"

NSString * const QLKBonjourTCPServiceType = @"_qlab._tcp.";
NSString * const QLKBonjourUDPServiceType = @"_qlab._udp.";
NSString * const QLKBonjourServiceDomain = @"local.";

// Notifications (moved from QLKCue.m)
NSString * const QLKCueUpdatedNotification = @"QLKCueUpdatedNotification";
NSString * const QLKCueNeedsUpdateNotification = @"QLKCueNeedsUpdateNotification";
NSString * const QLKCueEditCueNotification = @"QLKCueEditCueNotification";
NSString * const QLKCueHasNewDataNotification = @"QLKCueHasNewDataNotification";

// Cue Types (moved from QLKCue.m)
NSString * const QLKCueTypeCue = @"Cue";
NSString * const QLKCueTypeGroup = @"Group";
NSString * const QLKCueTypeAudio = @"Audio";
NSString * const QLKCueTypeFade = @"Fade";
NSString * const QLKCueTypeMicrophone = @"Mic";
NSString * const QLKCueTypeVideo = @"Video";
NSString * const QLKCueTypeAnimation = @"Animation";
NSString * const QLKCueTypeCamera = @"Camera";
NSString * const QLKCueTypeMIDI = @"MIDI";
NSString * const QLKCueTypeMIDISysEx = @"MIDI SysEx";
NSString * const QLKCueTypeMTC = @"MTC";
NSString * const QLKCueTypeMSC = @"MSC";
NSString * const QLKCueTypeArtNet = @"ArtNet";
NSString * const QLKCueTypeStop = @"Stop";
NSString * const QLKCueTypeMIDIFile = @"MIDI File";
NSString * const QLKCueTypeTimecode = @"Timecode";
NSString * const QLKCueTypePause = @"Pause";
NSString * const QLKCueTypeReset = @"Reset";
NSString * const QLKCueTypeStart = @"Start";
NSString * const QLKCueTypeDevamp = @"Devamp";
NSString * const QLKCueTypeLoad = @"Load";
NSString * const QLKCueTypeScript = @"Script";
NSString * const QLKCueTypeGoto = @"Goto";
NSString * const QLKCueTypeTarget = @"Target";
NSString * const QLKCueTypeWait = @"Wait";
NSString * const QLKCueTypeMemo = @"Memo";
NSString * const QLKCueTypeArm = @"Arm";
NSString * const QLKCueTypeDisarm = @"Disarm";
NSString * const QLKCueTypeStagetracker = @"Stagetracker";

// OSC key constants (moved from QLKCue.m)
NSString * const QLKOSCUIDKey = @"uniqueID";
NSString * const QLKOSCTypeKey = @"type";
NSString * const QLKOSCNameKey = @"name";
NSString * const QLKOSCNumberKey = @"number";
NSString * const QLKOSCNotesKey = @"notes";
NSString * const QLKOSCColorNameKey = @"colorName";
NSString * const QLKOSCFlaggedKey = @"flagged";
NSString * const QLKOSCArmedKey = @"armed";
NSString * const QLKOSCContinueModeKey = @"continueMode";
NSString * const QLKOSCPreWaitKey = @"preWait";
NSString * const QLKOSCPostWaitKey = @"postWait";
NSString * const QLKOSCDurationKey = @"duration";
NSString * const QLKOSCTranslationXKey = @"translationX";
NSString * const QLKOSCTranslationYKey = @"translationY";
NSString * const QLKOSCScaleXKey = @"scaleX";
NSString * const QLKOSCScaleYKey = @"scaleY";
NSString * const QLKOSCPreserveAspectRatioKey = @"preserveAspectRatio";
NSString * const QLKOSCLayerKey = @"layer";
NSString * const QLKOSCPatchKey = @"patch";
NSString * const QLKOSCPatchListKey = @"patchList";
NSString * const QLKOSCSurfaceListKey = @"surfaceList";
NSString * const QLKOSCCuesKey = @"cues";
NSString * const QLKOSCListNameKey = @"listName";
NSString * const QLKOSCSurfaceIDKey = @"surfaceID";
NSString * const QLKOSCFullScreenKey = @"fullScreen";
NSString * const QLKOSCOpacityKey = @"opacity";
NSString * const QLKOSCRotationZKey = @"rotationZ";
NSString * const QLKOSCRotationYKey = @"rotationY";
NSString * const QLKOSCRotationXKey = @"rotationX";
NSString * const QLKOSCPlaybackPositionIdKey = @"playbackPositionId";
NSString * const QLKOSCStartNextCueWhenSliceEndsKey = @"startNextCueWhenSliceEnds";
NSString * const QLKOSCStopTargetWhenSliceEndsKey = @"stopTargetWhenSliceEnds";
NSString * const QLKOSCSliderLevelKey = @"sliderLevel";

// Identifiers for "fake" cues (moved from QLKCue.m)
NSString * const QLKActiveCueListIdentifier = @"__active__";
NSString * const QLKRootCueIdentifier = @"__root__";
