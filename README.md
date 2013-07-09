# QLabKit

QLabKit is an Objective-C library for controlling QLab over the new OSC API introduced in QLab 3.


## Usage

The primary class for talking to QLab is `QLKWorkspace`. You can either use `QLKBrowser` to automatically discover all QLab instances on the local network which returns a `QLKWorkspace` instance, or you can create one manually with an IP address and port.


## License

Licensed under the MIT license