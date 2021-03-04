import SwiftUI
import Combine

/**
 Session handler to manage recording process and receive resulting `Asset`.
 
 Session handler can not be reused once stopped. Start new recording session with a new handler instance.
 */
public class ViewRecordingSession<Asset>: ViewAssetRecordingSession {
    
    private let view: AnyView
    private let framesRenderer: ([UIImage]) -> Future<Asset?, Error>
    
    private let useSnapshots: Bool
    private let duration: Double?
    private let framesPerSecond: Double
    
    private var isRecording: Bool = true
    private var frames: [ViewFrame] = []
    
    private let resultSubject: PassthroughSubject<Asset?, ViewRecordingError> = PassthroughSubject()
    private var assetGenerationCancellable: AnyCancellable? = nil
    
    /**
     Initialize new view recording session.
     
     Note that each SwiftUI view is a _struct_, thus it's copied on every assignment.
     Video capturing happens off-screen on a view's copy and intended for animation to video conversion rather than live screen recording.
     
     Recording performance is much better when setting `useSnapshots` to `true`.
     But this feature is only available on a simulator due to security limitations.
     Use snapshotting when you need to record high-FPS animation on a simulator to render it as a video.
     
     - Precondition: `duration` must be either `nil` or greater than 0.
     - Precondition: `framesPerSecond` must be greater than 0.
     - Precondition: `useSnapshots` isn't available on a real iOS device.
     
     - Parameter view: some SwiftUI `View` to record
     - Parameter framesRenderer: some `FramesRenderer` implementation to render captured frames to resulting `Asset`
     - Parameter useSnapshots: significantly improves recording performance, but doesn't work on a real iOS device due to privacy limitations
     - Parameter duration: optional fixed recording duration time in seconds. If `nil`, then need to call `stopRecording()` method to stop recording session.
     - Parameter framesPerSecond: number of frames to capture per second
     
     - Throws: `ViewRecordingError` if preconditions aren't met
     */
    public init<V: SwiftUI.View, Renderer: FramesRenderer>(view: V,
                                                           framesRenderer: Renderer,
                                                           useSnapshots: Bool = false,
                                                           duration: Double? = nil,
                                                           framesPerSecond: Double) throws where Renderer.Asset == Asset {
        guard duration == nil || duration! > 0
            else { throw ViewRecordingError.illegalDuration }
        guard framesPerSecond > 0
            else { throw ViewRecordingError.illegalFramesPerSecond }
        
        self.view = AnyView(view)
        self.duration = duration
        self.framesPerSecond = framesPerSecond
        self.useSnapshots = useSnapshots
        
        self.framesRenderer = { images in
            framesRenderer.render(frames: images, framesPerSecond: framesPerSecond)
        }
        
        recordView()
    }
    
    /// Subscribe to receive generated `Asset` or generation `ViewRecordingError`
    public var resultPublisher: AnyPublisher<Asset?, ViewRecordingError> {
        resultSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Stop current recording session and start `Asset` generation
    public func stopRecording() -> Void {
        guard isRecording else { return }
        
        print("Stop recording")
        isRecording = false
        generateAsset()
    }
    
    private var fixedFramesCount: Int? {
        duration != nil ? Int(duration! * framesPerSecond) : nil
    }
    
    private var allFramesCaptured: Bool {
        fixedFramesCount != nil && frames.count >= fixedFramesCount!
    }
    
    private var description: String {
        (duration != nil ? "\(duration!) seconds," : "")
            + (fixedFramesCount != nil ? " \(fixedFramesCount!) frames," : "")
            + " \(framesPerSecond) fps"
    }
 
    private func recordView() -> Void {
        print("Start recording \(description)")

        let uiView = view.placeUIView()
        
        Timer.scheduledTimer(withTimeInterval: 1 / framesPerSecond, repeats: true) { timer in
            if (!self.isRecording) {
                timer.invalidate()
                uiView.removeFromSuperview()
            } else {
                if self.useSnapshots, let snapshotView = uiView.snapshotView(afterScreenUpdates: false) {
                    self.frames.append(ViewFrame(snapshot: snapshotView))
                } else {
                    self.frames.append(ViewFrame(image: uiView.asImage(afterScreenUpdates: false)))
                }
                
                if (self.allFramesCaptured) {
                    self.stopRecording()
                }
            }
        }
    }
    
    private func generateAsset() -> Void {
        assetGenerationCancellable?.cancel()
        
        let frameImages = frames.map { $0.render() }
        print("Rendered \(frameImages.count) frames")

        assetGenerationCancellable = framesRenderer(frameImages)
            .mapError { error in ViewRecordingError.renderingError(reason: error.localizedDescription) }
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .subscribe(resultSubject)
    }
}
