# SwiftUIViewRecorder

Package to efficiently record any SwiftUI `View` as image or video.

* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
  * [Record view as video](#viewAsVideo)
  * [Record view as image](#viewAsImage)
  * [Custom view recording](#viewAsCustomAsset)

<a name="requirements"/>

## Requirements
* iOS 13.0
* Swift 5.2

<a name="installation"/>

## Installation
Use Xcode's built-in Swift Package Manager:

* Open Xcode
* Click File -> Swift Packages -> Add Package Dependency
* Paste package repository https://github.com/frolovilya/SwiftUIViewRecorder.git and press return
* Import module to any file using `import SwiftUIViewRecorder`

<a name="usage"/>

## Usage

<a name="viewAsVideo"/>

### Record `View` animation as a *.mov* QuickTime video

```swift
func recordVideo(duration: Double? = nil,
                 framesPerSecond: Double = 24,
                 useSnapshots: Bool = false) throws -> ViewRecordingSession<URL>
```

Note that each SwiftUI `View` is a **struct**, thus it's copied on every assignment.
Video capturing happens off-screen on a view's copy and intended for animation to video conversion rather than live screen recording.

Recording performance is much better when setting `useSnapshots` to `true`. In this case view frame capturing and image rendering phases are separated, but the feature is only available on a simulator due to security limitations.
Use snapshotting when you need to record high-FPS animation on a simulator to render it as a video.

You could use provided `ViewRecordingSessionViewModel` or write your own recording session view model to handle recording progress. 

```swift
import SwiftUI
import SwiftUIViewRecorder

struct MyViewWithAnimation: View {
    
    // observe changes using built-in recording view model
    @ObservedObject var recordingViewModel: ViewRecordingSessionViewModel<URL>
    
    private var viewToRecord: some View {
        // some view with animation which we'd like to record as a video
    }
    
    var body: some View {
        ZStack {
            if (recordingViewModel.asset != nil) {
                Text("Video URL \(recordingViewModel.asset!)")
            } else {
                Text("Recording video...")
            }
        }
        .onAppear {
            recordingViewModel.handleRecording(session: try! viewToRecord.recordVideo())
        }
    }
    
}
```

<a name="viewAsImage"/>

### Snapshot `View` as `UIImage`

```swift
func asImage() -> Future<UIImage, Never>
```

Simply call `asImage()` on any `View` to capture it's current state as an image. 
Since image is returned as a `Future` value, view model must be used to handle the result.
You could use provided `ViewImageCapturingViewModel` or write your own. 

```swift
import SwiftUI
import SwiftUIViewRecorder

struct ContentView: View {

    // observe image generation using built-in recording view model
    @ObservedObject var imageCapturingViewModel: ViewImageCapturingViewModel

    var viewToImage: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 50, height: 50)
            .asImage()
    }
    
    var body: some View {
        ZStack {
            if (imageCapturingViewModel.image != nil) {
                Image(uiImage: imageCapturingViewModel.image!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        .onAppear {
            imageViewModel.captureImage(view: viewToImage)
        }
    }

}
```

<a name="viewAsCustomAsset"/>

### Record view with a custom frames renderer

It's possible to impement and use your own `FramesRenderer` to convert array of `UIImage` frames to some asset.

First, implement `FramesRenderer` protocol:

```swift
class CustomRenderer: FramesRenderer {
    func render(frames: [UIImage], framesPerSecond: Double) -> Future<CustomAsset?, Error> {
        // process frames to a CustomAsset
    }
}
```
Second, init `ViewRecordingSession` with your custom renderer:

```swift
extension SwiftUI.View {
    public func toCustomAsset(duration: Double? = nil,
                              framesPerSecond: Double = 24) throws -> ViewRecordingSession<CustomAsset> {
        try ViewRecordingSession(view: self,
                                 framesRenderer: CustomRenderer(),
                                 duration: duration,
                                 framesPerSecond: framesPerSecond)
    }
}
```
