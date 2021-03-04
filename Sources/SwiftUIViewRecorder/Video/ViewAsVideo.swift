import SwiftUI
import Combine

extension SwiftUI.View {
    /**
     Record `View` animation as video
     
     - Parameter duration: fixed recording duration in seconds.
     If `nil`, then call `stopRecording()` on a `ViewRecordingSession` returned by this method to stop recording.
     - Parameter framesPerSecond: number of frames to take per second. By default is 24.
     - Parameter useSnapshots: separate capturing and rendering phases. Works on a simulator only. See `ViewRecordingSession` docs for details.
     
     - Returns: `ViewRecordingSession` recording handler to control recording process.
     */
    public func recordVideo(duration: Double? = nil,
                            framesPerSecond: Double = 24,
                            useSnapshots: Bool = false) throws -> ViewRecordingSession<URL> {
        try ViewRecordingSession(view: self,
                                 framesRenderer: VideoRenderer(),
                                 useSnapshots: useSnapshots,
                                 duration: duration,
                                 framesPerSecond: framesPerSecond)
    }
}
