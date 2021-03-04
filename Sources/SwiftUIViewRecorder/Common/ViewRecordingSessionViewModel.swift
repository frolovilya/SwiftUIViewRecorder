import SwiftUI
import Combine

/// `View` recording session `ViewModel`
public class ViewRecordingSessionViewModel<Asset>: ObservableObject {
    
    /// Resulting `Asset`
    @Published public var asset: Asset?
    
    /// Error during recording session
    @Published public var error: ViewRecordingError?
    
    private var session: ViewRecordingSession<Asset>?
    
    private var sessionResultCancellable: AnyCancellable?
    private var imageCancellable: AnyCancellable?

    public init() {}
    
    /**
     Track recording session.
     
     Subscribes to a session's `resultPublisher` and updates `@Published` `asset` and `error` `ViewModel`'s parameters.
     
     - Parameter session: `View` recording session handler to track
     */
    public func handleRecording(session: ViewRecordingSession<Asset>) -> Void {
        self.session = session
        
        sessionResultCancellable = session.resultPublisher
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.error = error
                    break
                default:
                    break
                }
            }, receiveValue: { [weak self] value in
                self?.asset = value
            })
    }
    
    /// Stop currently tracked recording session
    public func stopRecording() {
        self.session?.stopRecording()
    }
        
    public func captureImage<V: SwiftUI.View>(view: V) where Asset == UIImage {
        imageCancellable = view.asImage().sink { image in
            self.asset = image
        }
    }
}
