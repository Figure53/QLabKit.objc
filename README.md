# QLabKit

QLabKit is an Objective-C library for controlling QLab over the new OSC API introduced in QLab 3.

## Installation

All the files for the library are in the `lib` folder. Copy all the files from that folder into your project. Make sure you also include the code in the `F53OSC` folder which is a submodule. You'll also need to link against `Security.framework`.


## Usage

The primary class for talking to QLab is `QLKWorkspace`. You can either use `QLKBrowser` to automatically discover all QLab instances on the local network which returns a `QLKWorkspace` instance, or you can create one manually with an IP address and port.


## License

Licensed under the MIT license