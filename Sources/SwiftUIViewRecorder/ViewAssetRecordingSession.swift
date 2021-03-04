import SwiftUI
import Combine

/// Abstract recording session handler
public protocol ViewAssetRecordingSession {
    associatedtype Asset
    
    /// Subscribe to receive `Asset` or `ViewRecordingError` once recording is finished
    var resultPublisher: AnyPublisher<Asset?, ViewRecordingError> { get }
    
    /// Stop current recording session and start `Asset` generation
    func stopRecording() -> Void
}
