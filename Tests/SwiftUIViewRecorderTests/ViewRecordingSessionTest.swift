import XCTest
import SwiftUI
import Combine
@testable import SwiftUIViewRecorder

final class ViewRecordingSessionTest: XCTestCase {
    
    private var cancellables: [AnyCancellable] = []
    
    private var testView: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 50, height: 50)
    }
    
    func testIncorrectInitialization(duration: Double?, fps: Double, expectedError: ViewRecordingError) {
        var exception: Error?
        
        XCTAssertThrowsError(try ViewRecordingSession(view: testView,
                                                      framesRenderer: VideoRenderer(),
                                                      duration: duration,
                                                      framesPerSecond: fps)) { error in
            exception = error
        }
        
        XCTAssertEqual(exception as? ViewRecordingError, expectedError)
    }
    
    func testIncorrectDuration() {
        testIncorrectInitialization(duration: 0, fps: 24, expectedError: .illegalDuration)
        testIncorrectInitialization(duration: -1, fps: 24, expectedError: .illegalDuration)
    }
    
    func testIncorrectFramesPerSecond() throws {
        testIncorrectInitialization(duration: nil, fps: 0, expectedError: .illegalFramesPerSecond)
        testIncorrectInitialization(duration: 100, fps: -24, expectedError: .illegalFramesPerSecond)
    }
    
    func testAssetGenerationError() {
        let framesRenderer = FramesRendererMock()
        framesRenderer.error = AssetGenerationError(errorDescription: "some error reason")
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: nil,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 1
        assetGenerated.isInverted = true
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 1

        cancellables.append(session!.resultPublisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("Finished")
                break
            case .failure(let e):
                print("Error \(e)")
                XCTAssertEqual(e, ViewRecordingError.renderingError(reason: "some error reason"))
                errorReceived.fulfill()
                break
            }
        }, receiveValue: { value in
            print("Value \(String(describing: value))")
            if (value != nil) {
                assetGenerated.fulfill()
            }
        }))
        
        session?.stopRecording()
        
        wait(for: [assetGenerated, errorReceived], timeout: 1)
    }
    
    func testSuccessAssetGeneration() {
        let framesRenderer = FramesRendererMock()
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: nil,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 1
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 1
        errorReceived.isInverted = true
        
        cancellables.append(session!.resultPublisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("Finished")
                break
            case .failure(let e):
                print("Error \(e)")
                errorReceived.fulfill()
                break
            }
        }, receiveValue: { value in
            print("Value \(String(describing: value))")
            if (value != nil) {
                assetGenerated.fulfill()
            }
        }))
        
        session?.stopRecording()
        
        wait(for: [assetGenerated, errorReceived], timeout: 1)
    }
    
    func testNoAssetGeneratedWithoutCallingStop() {
        let framesRenderer = FramesRendererMock()
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: nil,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 1
        assetGenerated.isInverted = true
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 1
        errorReceived.isInverted = true

        cancellables.append(session!.resultPublisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("Finished")
                break
            case .failure(let e):
                print("Error \(e)")
                errorReceived.fulfill()
                break
            }
        }, receiveValue: { value in
            print("Value \(String(describing: value))")
            if (value != nil) {
                assetGenerated.fulfill()
            }
        }))
        
        wait(for: [assetGenerated, errorReceived], timeout: 1)
    }
    
    func testAssetGenerationWithFixedDuration() {
        let framesRenderer = FramesRendererMock()
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: 1,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 1
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 1
        errorReceived.isInverted = true

        cancellables.append(session!.resultPublisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("Finished")
                XCTAssertEqual(24, framesRenderer.capturedFrames.count)
                break
            case .failure(let e):
                print("Error \(e)")
                errorReceived.fulfill()
                break
            }
        }, receiveValue: { value in
            print("Value \(String(describing: value))")
            if (value != nil) {
                assetGenerated.fulfill()
            }
        }))
        
        wait(for: [assetGenerated, errorReceived], timeout: 2)
    }

    static var allTests = [
        ("testIncorrectDuration", testIncorrectDuration),
        ("testIncorrectFramesPerSecond", testIncorrectFramesPerSecond),
        ("testAssetGenerationError", testAssetGenerationError),
        ("testSuccessAssetGeneration", testSuccessAssetGeneration),
        ("testNoAssetGeneratedWithoutCallingStop", testNoAssetGeneratedWithoutCallingStop),
        ("testAssetGenerationWithFixedDuration", testAssetGenerationWithFixedDuration),
    ]
}
