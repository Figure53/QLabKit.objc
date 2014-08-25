# QLabKit

QLabKit is an Objective-C library for controlling QLab over the new OSC API introduced in QLab 3. It runs on OS X (10.7+) and iOS (6.0+).

**NOTE:** This library is under active development and the API may change.

## Installation

All the files for the library are in the `lib` folder. Copy all the files from that folder into your project. Make sure you also include the code in the `F53OSC` folder which is a submodule. You'll also need to link against `Security.framework`. All files in QLabKit use ARC. All files in F53OSC are non-ARC except for the GCDAsync* files. Non-ARC files will need to have `fno-objc-arc` flag set in the build phase.

## Classes

There are four primary classes you will use for talking to QLab:

- `QLKBrowser` - automatically discover QLab instances on the network
- `QLKServer` - represents and individual QLab server with a name, host, and port
- `QLKWorkspace` - a single workspace on a server
- `QLKCue` - a simplified representation of a cue. A cue list is also represented as a cue

There are other  classes in QLabKit that these classes rely on that you need not worry about. Read the headers of these primary classes for more usage information. All classes in QLabKit use ARC.

## Usage

The first thing you need to do is to get a `QLKWorkspace` instance to communicate with a single workspace from QLab. You can get this in one of two ways:

### Automatic

QLab advertises itself using Bonjour. This allows for the automatic discovery of all QLab machines on the same local network. The `QLKBrowser` class handles this for you like so:

Create a browser object and give it a delegate that implements `QLKBrowserDelegate` protocol:

```
QLKBrowser *browser = [[QLKBrowser alloc] init];
browser.delegate = self;
[browser start];

// Optional: continuously refresh every 5 seconds
[browser enableAutoRefreshWithInterval:5];
```

Implement the single delegate method. The browser has a `servers` property that is an array of `QLKServer` objects. Each `QLKServer` has a `workspaces` property that holds an array of `QLKWorkspace` objects

```
- (void)browserDidUpdateServers:(QLKBrowser *)browser
{
  // Browser has a servers property
  for (QLKServer *server in browser.servers) {
   	for (QLKWorkspace *workspace in server.workspaces) {
   		// do something with the servers, add to a server selection UI, etc
   	}
  }
}
```

### Manual

If you don't want to automatically discover QLab, you can also do it manually by first creating a server:

```
QLKServer *server = [[QLKServer alloc] initWithHost:@"10.0.1.1" port:53000];
[server refreshWorkspacesWithCompletion:^(NSArray *workspaces){
	// server now has workspaces
	for (QLKWorkspace *workspace in server.workspaces) {
		// … do something with workspace
	}
}];

```

Once you have a workspace, you can send commands and get data from QLab. First thing is to connect to the workspace:

```
QLKWorkspace *workspace; // assume this exists as a result of one of the earlier methods

// Connect to workspace
[workspace connect];

// Tell workspace to GO
[workspace go];

// Update name of a cue, assuming you have a cue object
[workspace cue:cue updateName:@"New name"];
```

The workspace exposes higher level methods so you don't have to directly deal with formatting the correct message and address. However, there may be API calls that the workspace class doesn't currently support, and you can use the lower-level methods to manually send a message.

```
[workspace sendMessage:@"New Name" toAddress:"/workspace/<workspace_id>/cue_id/<cue_id>/name"];
```

There is also working demo project that shows how you might hook all of this together to find servers on the network, show their workspaces, connect to a workspace, and finally fetch and display all the cues. Open `QLabKit.xcworkspace` and run the `QLabKitDemo` project.

## License

QLab is © copyright 2014 Figure 53

QLabKit is Licensed under the MIT license
