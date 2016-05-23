# PlayerView

[![CI Status](http://img.shields.io/travis/David Alejandro/PlayerView.svg?style=flat)](https://travis-ci.org/David Alejandro/PlayerView)
[![Version](https://img.shields.io/cocoapods/v/PlayerView.svg?style=flat)](http://cocoapods.org/pods/PlayerView)
[![License](https://img.shields.io/cocoapods/l/PlayerView.svg?style=flat)](http://cocoapods.org/pods/PlayerView)
[![Platform](https://img.shields.io/cocoapods/p/PlayerView.svg?style=flat)](http://cocoapods.org/pods/PlayerView)

An elegant wraper API for AVPlayer to get events over Delegate so you dount need to use KVO

## Installation

PlayerView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PlayerView"
```

### CocoaPods

`PlayerView` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your `Podfile`:


```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :iOS, '8.0'
use_frameworks!

pod 'PlayerView'
```

### Carthage

Installation is also available using the dependency manager [Carthage](https://github.com/Carthage/Carthage).

To integrate, add the following line to your `Cartfile`:

```ogdl
github "davidlondono/PlayerView" >= 0.2.7
```

### Swift Package Manager

Installation can be done with the [Swift Package Manager](https://swift.org/package-manager/), add the following in your `Package.swift` :

```Swift
import PackageDescription

let package = Package(
    name: "PlayerView",
    dependencies: [
        .Package(url: "https://github.com/davidlondono/PlayerView.git", majorVersion: 0),
    ]
)
```

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.


### Storyboard
Just add a view and add as a class on **Identity inspector > Custom Class > Class**, make sure to add Module if is imported externaly (Pod, Package manager ....)

```Swift
import PlayerView
```

```Swift
@IBOutlet var playerVideo: PlayerView!
```

### Code

Just need to add de view as a normal View:

```Swift
import PlayerView
```

```Swift



let playerVideo = PlayerVideo()

//also could add frame:
// let playerVideo = PlayerVideo(frame: frame)
view.addSubView(playerVideo)


```

## Control


```Swift
//set aspect mode of video
//default AVLayerVideoGravityResizeAspectFill
playerVideo.fillMode = .ResizeAspect

//Set or Get the seconds of the current time of reproduction
//this will set to reproduce on 3.5 seconds
playerVideo.currentTime = 3.5

//define the time interval to get callback delegate of the current time of reproduction, default sends 60 times on 1 second
//default CMTimeMake(1, 60)
//this send the time one time per one second
playerVideo.interval = CMTimeMake(1, 1)

//set and get the speed of reproduction
//if speed is set to 0, the video will pause (same as playerVideo.pause())
//if speed is set to 1,0, the video will pause (same as playerVideo.play())
playerVideo.rate = 0.5

//play the video at rate 1.0
playerVideo.play()

// pause the video on current time
playerVideo.pause()


// stop the video on current time
playerVideo.stop()


// stop the video on current time
playerVideo.next()

//to set the url of Video
if let url = NSURL(string: "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_30mb.mp4") {
	playerVideo.url = url
    //or
    playerVideo.urls = [url]

    //add videos on queue
    playerVideo.addVideosOnQueue(urls: [url])
}

//Take a screenshot on time, and return time to ensure the tolerance of the image
//on 20.7 seconds
let(image1, time1) = playerVideo.screenshotTime(20.7)
//on actual time
let(image2, time2) = playerVideo.screenshotTime()


//on actual time
let image3 = playerVideo.screenshot()

//reset queue and observers
playerVideo.resetPlayer()
```
## Delegate
you could get event data from the PlayerView, just implement the delegate
all the functions are optionals

```Swift
import PlayerView
import AVFoundation
```

```Swift
	playerVideo.delegate = self
```

```Swift

extension MyClass:PlayerViewDelegate {


	func playerVideo(player: PlayerView, statusPlayer: PlayerViewStatus, error: NSError?) {
        //got the status of the player
		//useful to know if is ready to play
		//if status is unknown then got the error
    }

	func playerVideo(player: PlayerView, statusItemPlayer: PlayerViewItemStatus, error: NSError?) {
		//some status got here first, this is the status of AVPlayerItem
		//useful to know if is ready to play
		//if status is unknown then got the error
	}

	func playerVideo(player: PlayerView, loadedTimeRanges: [PlayerviewTimeRange]) {
		//got the buffer of the video
		//to know the progress loaded

		//this will get the seconds of the end of the buffer
		//loadedTimeRanges.first!.end.seconds

	}

	func playerVideo(player: PlayerView, duration: Double) {
		//the player knows the duration of the video to reproduce on seconds
	}

	func playerVideo(player: PlayerView, currentTime: Double) {
		//executed using the playerVideo.interval
        //only executed when the is reproducing, on pause (rate == 1) this doesn't execute
		//default executed like 60 frames per seconds, so 60 times on a second
	}

	func playerVideo(player: PlayerView, rate: Float) {
		//if the speed of reproduction changed by pausing, playing or changing speed
	}

    func playerVideo(playerFinished player: PlayerView) {
        //when the video finishes the reproduction to the end
    }
}
```

## Extra Info

- If you like another shorcut, have a better implementation of something or just say thanks,  just send me an email [davidlondono9@gmail.com](mailto:davidlondono9@gmail.com?subject=PlayerView is Awesome)

- Im using a video on http, so I needed to add this on the `info.plist` to accept all on http,
this is not safe to use on production, so better to add only trusted domains or use https

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!--Include to allow all connections (DANGER)-->
    <key>NSAllowsArbitraryLoads</key>
<true/>
</dict>
```

## Author

David Alejandro, [davidlondono9@gmail.com](mailto:davidlondono9@gmail.com?subject=PlayerView is Awesome)

## License

PlayerView is available under the MIT license. See the LICENSE file for more info.
