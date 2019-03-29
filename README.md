# Francis

Francis is an app for discovering Bonjour services on the local network. It is built with an RxSwift layer on top of `NetServiceBrowser` and `NetService`. The app runs on both macOS and iOS.

## Requirements

* Xcode 10.2
* Swift 5
* macOS 10.14 or iOS 12
* Carthage

## Installation

```
git clone git@github.com:andyshep/Francis.git && cd Francis
carthage update --no-use-binaries --platform macOS,iOS
open Francis.xcodeproj
```

## Screenshot

![](https://i.imgur.com/QdiT26z.gif)

## Artwork

App icon courtesy of the [Noun Project](https://thenounproject.com/rebelsaeful/collection/doodle-ui/?i=1513021)
