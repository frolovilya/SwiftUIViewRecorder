import Foundation

/// Errors which may occur during view recording session
public enum ViewRecordingError: Error, Equatable {
    case illegalDuration
    case illegalFramesPerSecond
    case renderingError(reason: String? = nil)
}
