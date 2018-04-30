# QLabKit

QLabKit is an Objective-C library for controlling QLab over the OSC API in QLab 3 or later. QLabKit requires macOS 10.9+ or iOS 8.4+.

**NOTE:** This library is under active development and the API may change.

## Installation

All the files for the library are in the `lib` folder. Copy all the files from that folder into your project. Make sure you also include the code in the `F53OSC` folder which is a submodule. You'll also need to link against `Security.framework` and `GLKit.framework`. All files in QLabKit and F53OSC use ARC.

QLabKit can also be installed on iOS using CocoaPods by adding the following to your podfile:
``` ruby
pod 'F53OSC', :git => 'https://github.com/Figure53/F53OSC.git', :commit => 'd895b2e7a1b5bcf07c0f7d69483ece8f847219b2'  # v1.0.2
pod 'QLabKit', :git => 'https://github.com/Figure53/QLabKit.objc.git'
```

## Classes

There are four primary classes you will use for talking to QLab:

- `QLKBrowser` - automatically discover QLab instances on the network
- `QLKServer` - represents and individual QLab server with a name, host, and port
- `QLKWorkspace` - a single workspace on a server
- `QLKCue` - a simplified representation of a cue. A cue list cue is also represented as a cue

There are other classes in QLabKit that these classes rely on that you need not worry about. Read the headers of these primary classes for more usage information. All classes in QLabKit use ARC.

## Usage

The first thing you need to do is to get a `QLKWorkspace` instance to communicate with a single workspace from QLab. You can get this in one of two ways:

### Automatic

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

### Manual

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
[workspace connect];

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

QLabKit © copyright 2014-2017 Figure 53, LLC.

QLabKit is licensed under the MIT license.
