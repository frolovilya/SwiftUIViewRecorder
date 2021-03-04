import Foundation
import UIKit
import Combine

/// Abstract `UIImage` frames renderer
public protocol FramesRenderer {
    associatedtype Asset
    
    /**
     Render `UIImage` collection as some `Asset`
     
     - Parameter frames: list of `UIImage` frames to use for conversion
     - Parameter framesPerSecond: number of `UIImage` to be rendered per second
     - Returns: eventually returns generated `Asset` or `Error`
     */
    func render(frames: [UIImage], framesPerSecond: Double) -> Future<Asset?, Error>
}
