import UIKit
import UIImageExtensions
import Combine

class VideoRenderer: FramesRenderer {
    func render(frames: [UIImage], framesPerSecond: Double) -> Future<URL?, Error> {
        frames.toVideo(framesPerSecond: framesPerSecond)
    }
}
