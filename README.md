# Francis

Francis is macOS app for discovering Bonjour services on the local network. It is built around the [DNSSDObjects](https://developer.apple.com/library/archive/samplecode/DNSSDObjects/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011371-Intro-DontLinkElementID_2) sample code from Apple. Nearby services are displayed in an `NSTableView` through RxSwift and Cocoa Bindings.

## Requirements

* Xcode 10
* Swift 4.2
* Carthage

## Installation

```
git clone git@github.com:andyshep/Francis.git
carthage update --no-use-binaries --platform macOS
open Francis.xcodeproj
```

## Screenshot

![](https://i.imgur.com/QdiT26z.gif)

## Artwork

App icon courtesy of the [Noun Project](https://thenounproject.com/rebelsaeful/collection/doodle-ui/?i=1513021)
