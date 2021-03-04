import Foundation
import Combine
import UIKit
@testable import SwiftUIViewRecorder

class FramesRendererMock: FramesRenderer {
    
    var result: String? = "someGeneratedAsset"
    var error: Error? = nil
    
    var capturedFrames: [UIImage] = []
    
    func render(frames: [UIImage], framesPerSecond: Double) -> Future<String?, Error> {
        print("Start rendering \(frames.count) frames")
              
        capturedFrames = frames
        
        return Future<String?, Error>() { promise in
            if (self.error == nil) {
                print("Successfully finished rendering frames")
                promise(.success(self.result))
            } else {
                print("Finished rendering frames with error \(self.error!)")
                promise(.failure(self.error!))
            }
        }
    }

}
