# QLabKit

QLabKit is an Objective-C library for controlling QLab over the OSC API in QLab 3 or later. QLabKit requires macOS 11+ or iOS 14+.

**NOTE:** This library is under active development and the API may change.

## Installation

All the files for the library are in the `lib` folder. Copy all the files from that folder into your project. Make sure you also include the code in the `F53OSC` folder which is a submodule. You'll also need to link against `Security.framework`. All files in QLabKit and F53OSC use ARC.

QLabKit can also be installed on iOS using CocoaPods by adding the following to your podfile:
``` ruby
pod 'F53OSC', :git => 'https://github.com/Figure53/F53OSC.git'
pod 'QLabKit', :git => 'https://github.com/Figure53/QLabKit.objc.git'
```

## Classes

There are four primary classes you will use for talking to QLab:

- `QLKBrowser` - automatically discover QLab instances on the network
- `QLKServer` - represents an individual QLab server with a name, host, and port
- `QLKWorkspace` - a single workspace on a server
- `QLKCue` - a simplified representation of a cue. A cue list cue is also represented as a cue

There are other classes in QLabKit that these classes rely on that you need not worry about. Read the headers of these primary classes for more usage information. All classes in QLabKit use ARC.

## Usage

The first thing you need to do is to get a `QLKWorkspace` instance to communicate with a single workspace from QLab. You can get this in one of two ways:

### Automatic Discovery

QLab advertises itself using Bonjour. This allows for the automatic discovery of all QLab machines on the same local network. The `QLKBrowser` class handles this for you like so:

Create a browser object and give it a delegate that implements `QLKBrowserDelegate` protocol:

``` objc
QLKBrowser *browser = [[QLKBrowser alloc] init];
browser.delegate = self;
[browser start];

// Optional: continuously refresh every 5 seconds
[browser enableAutoRefreshWithInterval:5];
```

Implement the required `QLKBrowserDelegate` methods. The browser has a `servers` property that is an array of QLKServer objects. Each QLKServer has a `workspaces` property that holds an array of QLKWorkspace objects discovered on the network.

``` objc
- (void) browserDidUpdateServers:(QLKBrowser *)browser
{
    // Browser has a servers property
    for ( QLKServer *aServer in browser.servers ) 
    {
        for ( QLKWorkspace *aWorkspace in aServer.workspaces ) 
        {
            // do something with the servers and workspaces, i.e. add to a selection UI, etc
        }
    }
}
```

NOTE: As of iOS 14, your app must be granted permission by the user to connect to devices on the local network. To enable this, your Info.plist must include the `NSLocalNetworkUsageDescription` key with a description of your app's network usage and the `NSBonjourServices` key with the QLab Bonjour service value `_qlab._tcp`. For example:

``` xml
<key>NSLocalNetworkUsageDescription</key>
<string>Some descriptive text explaining your app's reason to connect to the local network.</string>
<key>NSBonjourServices</key>
<array>
    <string>_qlab._tcp</string>
</array>

```

### Manual Discovery

If you don't want to automatically discover QLab, you can also do it manually by first creating a server:

``` objc
NSString *hostIP = @"10.0.1.1";
NSInteger port = 53000;
QLKServer *server = [[QLKServer alloc] initWithHost:hostIP port:port];
[server refreshWorkspacesWithCompletion:^(NSArray<QLKWorkspace *> * _Nonnull workspaces) {
    // server now has workspaces
    for ( QLKWorkspace *aWorkspace in workspaces )
    {
        // ... do something with aWorkspace
    }
}];

```

Once you have a workspace, you can send commands to and get data from QLab. The first thing is to connect to the workspace:

``` objc
QLKWorkspace *workspace; // assume this exists as a result of one of the earlier methods

// Connect to workspace
NSString *passcode = ...
[workspace connectWithPasscode:passcode completion:nil];

// Tell workspace to GO
[workspace go];

...

// Update name of a cue, assuming you have a cue object
cue.name = @"New name";
```

QLKWorkspace exposes higher level methods so you don't have to directly deal with formatting the correct message and address. However, there may be API calls that the workspace class doesn't currently support, and you can use the lower-level methods to manually send a message.

``` objc
NSString *address = [NSString stringWithFormat:@"/workspace/%@/cue_id/%@/name", workspace.uniqueID, cue.uid];
[workspace sendMessage:@"New Name" toAddress:address];
```

There is also working demo project that shows how you might hook all of this together to find servers on the network, show their workspaces, connect to a workspace, and finally fetch and display all the cues. Open `QLabKit.xcodeproj` and run the `QLabKitDemo` project to learn more.

## Migrating from 0.0.4 to 0.0.5

QLabKit 0.0.5 requires macOS 11+ or iOS 15+.

### New
* Adds support for connecting to QLab v5. See `-[QLKWorkspace connectWithPasscode:completion:]` and the QLab OSC dictionary for more.
* Adds support for unified code formatting of QLabKit source code using clang-format.

### Removed Dependencies
* GLKit.framework is no longer a required dependency (deprecated by Apple in macOS 10.15 and iOS 13). Use new type `QLKQuaternion` to replace `GLKQuaternion`.
* CocoaLumberjack is no longer added as a dependency when building with CocoaPods. It is unneeded since the socket classes that include CocoaLumberjack `DDLog.h` have logging disabled by default.

### QLKDefines
* `QLKMessageHandlerBlock` is replaced with `QLKMessageReplyBlock`, which adds a `status` parameter. Note that the `data` parameter is now properly annotated as nullable.
* The string values of certain video geometry keys are updated for compatibility with QLab v5.0 and later. For legacy values when connecting to QLab v3 or v4, use the constants that begin with `QLKOSCV4*`. QLKCue.h includes compatibility macros for synonomous keys across multiple versions of QLab.

### QLKClientDelegate
* Delegate methods are renamed to include the `QLKClient` object as a parameter.
* Adds `shouldEncryptConnectionsForClient:` to optionally enable an encrypted OSC connection when connected to QLab v5.0 and later.

### QLKCue
* Adds `liveColor` convenience getter to fetch the v5 live cue color.
* Adds `auditionPreview` convenience method. Requires QLab v5.0 or later.
* The QLKImage property `icon` is replaced with NSString `iconName`. This avoids loading an image for each QLKCue object created. Instead, a string suitable for passing to `imageNamed:` is cached, and the image is only loaded when the image file is needed. As such, the #define `QLKImage` is no longer needed and is removed.
* The `userInfo` dictionary for the `QLKCueListDidChangePlaybackPositionIDNotification` now includes the unique ID(s) of the old and/or new playback position cues. The `NSKeyValueChangeOldKey` entry, if present, contains the `uniqueID` string of the previous playback position cue. The `NSKeyValueChangeNewKey` entry, if present, contains the `uniqueID` string of the current playback position cue.
* Patches in QLab 5 are greatly expanded. They have more descriptive patch list OSC getter names (i.e. not just `/patchList`) and are now methods of the respective settings that manage a given patch type. As such, the `patchName` getter and `@"patchDescription"` helper inside `propertyForKey:` no longer cover enough cases to be useful and have been removed. Going forward when connecting to QLab 5, get the patch index or patch unique ID from the cue and cross-reference with the patch list fetched from the appropriate settings. For backward compatibility with QLab 3 and 4, get both the patch index and patch list from the cue and cross-reference with each other.

### QLKVersionNumber
* Adds a new class and NSString category used to compare version number strings.
* The `compare:` method of this class compares the "build" number of each version if needed. Use the `QLKVersionNumber` method `compare:ignoreBuild:` to optionally ignore the build number when comparing two versions.
* The `QLKQLabWorkspaceVersion` class is deprecated and will be removed in a future release in favor of using `QLKVersionNumber`.

### QLKWorkspace
* Adds `auditionGo` and `auditionPreviewCue:` convenience methods. Both require QLab v5.0 or later.
* When connected to QLab v4 and later, calling `fetchDisplayAndGeometryForCue:` no longer fetches properties related to the list of workspace video outputs or properties of a given output. Instead, the workspace populates its `videoOutputsList` property with the reply payload from `/settings/video/stages` (v5.0+) or `/settings/video/surfaces` (v4.x). This avoids duplicate and/or stale data from being stored in all video cues. Use new QLKWorkpace methods `stageDictForStageID:` (v5.0+) or `surfaceDictForSurfaceID:` (v4.x) to get a dictionary of values for that video output ID. The `videoOutputsList` array is kept up-to-date by the workspace in response to Video settings update notifications.
* The helper method `addressForWildcardNumber:action:` is deprecated because it is unused in QLabKit and only generates `/cue/*`-prefixed addresses, whereas wildcards can be also be used in addresses with the `/cue_id/*` prefix.

## Migrating from 0.0.3 to 0.0.4

QLabKit 0.0.4 requires macOS 10.9+ or iOS 8.4+.

### QLKCue
* Fixes the class method `cueTypeIsAudio:` so that it now correctly returns `NO` for the following cue types: Fade, Camera, Text/Titles.
* Fixes `panicCue:` so that the `QLKOSCIsPanickingKey` property is only updated when connected to QLab 4.0 or later (which is the minimum QLab version that supports the `/isPanicking` OSC method).
* Adds convenience getters `isOverridden`, `isBroken`, `isTailingOut`, and `isPanicking` which also take into account the property values of child cues in Group, Cue List, and Cue Cart cues.
* When using `propertyForKey:` to get the quaternion of a Video or Fade cue, the value is no longer transformed to NSValue and is now returned as an array of NSNumbers (representing the X, Y, Z, and W components of the quaternion). The convenience property `quaternion` remains unchanged and gets/sets a `GLKQuaternion` struct, and the new convenience setter `setQuaternion:tellQLab:` also accepts a `GLKQuaternion` struct.

### QLKColor
* Colors and colorspaces are now more consistent between iOS and macOS.
* The `name` property and the class method `+[QLKColor colorWithName:]` now return an empty QLKColor object for undefined color names. Subclasses or categories can override the `name` property to define additional colors.

### QLKClient
* Fixes an issue where replies from individual OSC getter methods (i.e. calls from `cue:valueForKey:block:`) were not being processed.
* The internal F53OSCClient used by QLKClient now performs its TCP/UDP communication with QLab on a background thread. F53OSCClient ensures that its F53OSCClientDelegate methods continue to be called on the main thread. However, be aware that custom implementations of GCDAsyncSocketDelegate or GCDAsyncUdpSocketDelegate methods in any subclasses of QLKClient or F53OSCClient will now be called on a background thread and must dispatch back to the main thread when necessary.
* Adds QLKClientDelegate methods:
  * `workspaceDisconnected` (required) which is now called when a QLKClient receives an OSC `/update/workspace/{id}/disconnect` message from QLab. This replaces the previous behavior in which `clientConnectionErrorOccurred` was called. This new delegate method now makes it possible for a client app to distinguish between the QLab workspace proactively notifying the client it should disconnect (e.g. because the QLab workspace was closed) and some other issue with the network connection. Connection errors continue to trigger a call to `clientConnectionErrorOccurred`.
  * `clientShouldDisconnectOnError` (optional) - If the delegate implements this method and returns `NO`, the QLKClient will no longer immediately disconnect after a connection error is reported by its internal F53OSCClient. Instead, the delegate is responsible for disconnecting and tearing down the client at some point in the future. If this method returns `YES` or is not implemented, the QLKClient will behave as before and immediately call `disconnect` in response to a connection error.
  * `lightDashboardUpdated:` (optional) - When connected to QLab 4.2 or later, this notifies the delegate when the state of the Light Dashboard has updated.
  * `preferencesUpdated:` (optional) - When connected to QLab 4.2 or later, this notifies the delegate when certain application preferences in QLab are updated, namely `liveFadePreview`. To respond to changes made to workspace-level settings, continue to use `workspaceSettingsUpdated:`.

### QLKWorkspace
* QLKWorkspace now posts a `QLKWorkspaceDidDisconnectNotification` only after receiving an affirmative `/disconnect` update message from QLab. QLKWorkspace also no longer posts a redundant `QLKWorkspaceDidDisconnectNotification` when disconnecting itself from QLab. All other connection errors, e.g. failed attempts to connect due to an incorrect OSC passcode or other network problems, post a `QLKWorkspaceConnectionErrorNotification` so that observers can evaluate whether to attempt to reconnect or not.
* The `connect` method is deprecated because it does not support connecting to workspaces with an OSC passcode. Instead, use `connectWithPasscode:completion:` and pass `nil` for the passcode parameter to connect to a workspace whose `hasPasscode` property is `NO`.
* The method `connectWithPasscode:completion:` now caches the passcode in the workspace only upon a successful connection.
* Adds a property `attemptToReconnect` which QLKWorkspace uses in its implementation of the new QLKClientDelegate method `clientShouldDisconnectOnError`. After receiving a connection error notification, QLKWorkspace uses the value of the `attemptToReconnect` property to determine whether to attempt to reestablish a connection to the current workspace or to disconnect immediately.
* The methods `startHeartbeat` and `stopHeartbeat` are now public and can be used to actively monitor the network connection. When the heartbeat is running, a network timeout will cause the workspace to post a `QLKWorkspaceConnectionErrorNotification`.
* Adds two new methods `deferFetchingPropertiesForCue:` and `resumeFetchingPropertiesForCue:` which can be used to reduce network traffic and significantly improve performance when connected to large workspaces. Selective use of these methods allows a workspace to consolidate update requests on a cue-by-cue basis, enabling a client app to send requests for data only when it is actually needed (e.g. when a cue is about to become visible in the UI). When a workspace is set to defer fetching the properties of a given cue, all QLKWorkspace methods prefixed with `fetch` will cache the property key(s) from any request for that cue instead of sending an OSC message to QLab. When the workspace later is set to resume fetching the properties for that cue, a single `/valuesForKeys` message will be sent to QLab requesting values for all previously-cached property keys, and all `fetch` methods will once again transmit OSC requests for that cue immediately when called.
* Adds a property `defaultDeferFetchingPropertiesForNewCues`. Set this property to `YES` to cause the workspace to defer fetching properties for all new cues immediately upon creation. For example, this can be used to avoid flooding the network with OSC update requests when first connecting to QLab. The default for this property is `NO`, meaning new cues created by the workspace will not defer fetching properties (the "resume" behavior).
* Adds a `QLKWorkspaceDidUpdateLightDashboardNotification` which is posted by the QLKWorkspace implementation of QLKClientDelegate method `lightDashboardUpdated:` when connected to QLab 4.2 or later.
* Adds a `QLKQLabDidUpdatePreferencesNotification` which is posted by the QLKWorkspace implementation of QLKClientDelegate method `preferencesUpdated:` when connected to QLab 4.2 or later.
* The methods `fetchChildrenForCue:block:` and `fetchAudioLevelsForCue:block:` are deprecated because their `block` parameters are not compatible with the new deferred property fetching mechanism. Instead, request these values using `cue:valueForKey:block:` with the keys `children` and `sliderLevels`, respectively.
* The values of the following NSString constants are updated to follow the convention of the value matching the name. Any code that directly accesses the value of one of these constants, e.g. comparing to another string using `isEqual:` or `isEqualToString:`, should update to use the new string values:
  - `QLKWorkspaceDidConnectNotification`
  - `QLKWorkspaceDidDisconnectNotification`
  - `QLKWorkspaceConnectionErrorNotification`


## Migrating from 0.0.2 to 0.0.3

QLabKit 0.0.3 requires macOS 10.9+ or iOS 8.4+.

### QLKBrowser
* The QLKBrowserDelegate method `serverDidUpdateWorkspaces:` is renamed to `browserServerDidUpdateWorkspaces:` to avoid collision with the QLKServerDelegate method of the same name.
* The selector called by the NSTimer scheduled in `enableAutoRefreshWithInterval:` is changed from the public method `refreshAllWorkspaces` to a new private method `_refreshAllWorkspaces:`.

### QLKColor
* Color values are updated to match the color scheme of QLab 4.
* Helper class methods `colorWithRed:green:blue:alpha:` and `colorWithWhite:alpha:` are deprecated in favor of specific values for NSColor/UIColor for better color matching between Mac and iOS.
* The "type" property for the object returned by class method `defaultColor` now has the string value "default" instead of "none".
* `startColor` and `endColor` are deprecated since QLab 4 no longer displays cue colors with gradients. Use `lightColor` and `darkColor` instead.
* `lightBlueColor`, `panelColor` and `navBarColor` are no longer used in QLab 4 and are deprecated.

### QLKClientDelegate
* `playbackPositionUpdated:` is changed to `cueListUpdated:withPlaybackPositionID:` to allow updating the playback position individually for each cue list cue.

### QLKCue
* Class method `iconForType:` now returns the string value "mic" for Mic cues to match QLab conventions.
* `pushUpProperty:forKey:` is deprecated. Use `setProperty:forKey:tellQLab:` instead, with the `tellQLab` parameter set to `YES`.
* `triggerPushDownPropertyForKey:` is deprecated. Use `pullDownPropertyForKey:block:` instead.
* `pushDownProperty:forKey:` is deprecated. Use `setProperty:forKey:tellQLab:` instead.
* String constant `QLKCueHasNewDataNotification` is removed because the method which posted this notification is now deprecated.
* The unique ID of each cue list cue's playback position can now be accessed using the `playbackPositionID` property and set using `setPlaybackPositionID:tellQLab:`. View controllers should now observe `QLKCueListDidChangePlaybackPositionIDNotification` notifications to respond to playback position changes on a per-cue list basis.
* QLKCue property getters and setters are now thread-safe and updates are processed on a background queue.

### QLKDefines
* `QLKActiveCueListIdentifier` is renamed to `QLKActiveCuesIdentifier` for clarity.
* `QLKCueTypeMicrophone` is renamed to `QLKCueTypeMic` to match QLab conventions.

### QLKServer
* The property `browser` is removed. QLKBrowser now conforms to `QLKServerProtocol` so an existing browser instance can now be set as the delegate of QLKServer instead of needing to have a dedicated browser property on the server itself.

### QLKWorkspace
* `uniqueId` property is renamed to `uniqueID` to unify capitalization of "ID".
* `fetchMainPropertiesForCue:` is renamed to `fetchDefaultCueListPropertiesForCue:`.
* A `QLKCueUpdatedNotification` notification is now posted only when cue data has actually changed.
* String constant `QLKWorkspaceDidChangePlaybackPositionNotification` is replaced by `QLKCueListDidChangePlaybackPositionIDNotification`. (See QLKCue above.)
* String constant `QLKWorkspaceDidUpdateCuesNotification` has been removed and is replaced with `QLKCueUpdatedNotification`. Observers of `QLKCueUpdatedNotification` notifications can now inspect the notification object, which is the cue that was updated, and react accordingly. For example, the notification object will be the QLKWorkspace `root` after adding a cue list to the workspace. Test the notification object cue for `isCueList` to determine if the child cues of a particular cue list have changed.
* All method parameters of type `QLKMessageHandlerBlock` are renamed to "block" to distinguish from the various styles of other "completion" blocks:
  * `cue:valueForKey:completion:` is renamed to `cue:valueForKey:block:`.
  * `fetchCueListsWithCompletion:` is renamed to `fetchCueListsWithBlock:`.
  * `fetchPlaybackPositionForCue:completion:` is renamed to `fetchPlaybackPositionForCue:block:`.
  * `fetchChildrenForCue:completion:` is renamed to `fetchChildrenForCue:block:`.
  * `fetchAudioLevelsForCue:completion:` is renamed to `fetchAudioLevelsForCue:block:`.
* The "type" property for the `__root__` and `__active__` cue list cues are changed from `QLKCueTypeGroup` to `QLKCueTypeCueList`.


## License

QLabKit © copyright 2014-2022 Figure 53, LLC.

QLabKit is licensed under the MIT license.
