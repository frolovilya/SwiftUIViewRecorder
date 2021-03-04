import XCTest
import UIKit
import Combine
@testable import SwiftUIViewRecorder

final class UIImagesToVideoTest: XCTestCase {
    
    private var cancellables: [AnyCancellable] = []
    
    private func createExpectation(description: String, isInverted: Bool = false) -> XCTestExpectation {
        let someExpectation = expectation(description: description)
        someExpectation.isInverted = isInverted
        someExpectation.expectedFulfillmentCount = 1

        return someExpectation
    }

    func testNoFrames() {
        let emptyArray: [UIImage] = []
        
        let videoGenerated = createExpectation(description: "received video URL", isInverted: true)
        let errorReceived = createExpectation(description: "received video generation error")
        let finishedReceived = createExpectation(description: "publisher finished", isInverted: true)
        
        cancellables.append(emptyArray.toVideo(framesPerSecond: 24)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    if (error as? UIImagesToVideoError == UIImagesToVideoError.noFrames) {
                        errorReceived.fulfill()
                    }
                    break
                case .finished:
                    finishedReceived.fulfill()
                    break
                }
            }, receiveValue: { value in
                videoGenerated.fulfill()
            }))
        
        wait(for: [videoGenerated, errorReceived, finishedReceived], timeout: 1)
    }
    
    func testIncorrectFPS(framesPerSecond: Double) {
        let imagesArray: [UIImage] = [UIImage.fromBase64String(TestImageData.tennisBall)!]
        
        let videoGenerated = createExpectation(description: "received video URL", isInverted: true)
        let errorReceived = createExpectation(description: "received video generation error")
        let finishedReceived = createExpectation(description: "publisher finished", isInverted: true)
        
        cancellables.append(imagesArray.toVideo(framesPerSecond: framesPerSecond)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    if (error as? UIImagesToVideoError == UIImagesToVideoError.invalidFramesPerSecond) {
                        errorReceived.fulfill()
                    }
                    break
                case .finished:
                    finishedReceived.fulfill()
                    break
                }
            }, receiveValue: { value in
                videoGenerated.fulfill()
            }))
        
        wait(for: [videoGenerated, errorReceived, finishedReceived], timeout: 1)
    }
    
    func testIncorrectFPS() {
        testIncorrectFPS(framesPerSecond: 0)
        testIncorrectFPS(framesPerSecond: -1)
    }
    
    func testVideoGenerated() {
        let imagesArray: [UIImage] = [UIImage.fromBase64String(TestImageData.tennisBall)!]
        
        let videoGenerated = createExpectation(description: "received video URL")
        let errorReceived = createExpectation(description: "received video generation error", isInverted: true)
        let finishedReceived = createExpectation(description: "publisher finished")
        
        cancellables.append(imagesArray.toVideo(framesPerSecond: 24)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    errorReceived.fulfill()
                    break
                case .finished:
                    finishedReceived.fulfill()
                    break
                }
            }, receiveValue: { value in
                if value != nil {
                    self.removeGeneratedAsset(url: value!)
                    videoGenerated.fulfill()
                }
            }))
        
        wait(for: [videoGenerated, errorReceived, finishedReceived], timeout: 1)
    }
    
    private func removeGeneratedAsset(url: URL) -> Void {
        do {
            try FileManager.default.removeItem(at: url)
        } catch(let e) {
            print(e)
        }
    }
    
    static var allTests = [
        ("testNoFrames", testNoFrames),
        ("testIncorrectFPS", testIncorrectFPS),
        ("testVideoGenerated", testVideoGenerated)
    ]

}
