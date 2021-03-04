import XCTest
import SwiftUI
import Combine
@testable import SwiftUIViewRecorder

final class ViewRecordingViewModelTest: XCTestCase {
    
    private var cancellables: [AnyCancellable] = []
    
    private var testView: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 50, height: 50)
    }
    
    private let viewModel = ViewRecordingSessionViewModel<String>()
    
    func testErrorPublishing() {
        let framesRenderer = FramesRendererMock()
        framesRenderer.error = AssetGenerationError(errorDescription: "some error reason")
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: nil,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        viewModel.handleRecording(session: session!)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 1 // nil
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 2 // nil, error
        
        cancellables.append(viewModel.$asset.sink { value in
            assetGenerated.fulfill()
        })
        
        cancellables.append(viewModel.$error.sink { error in
            if (error != nil) {
                XCTAssertEqual(error, ViewRecordingError.renderingError(reason: "some error reason"))
            }
            errorReceived.fulfill()
        })
        
        viewModel.stopRecording()
        
        wait(for: [assetGenerated, errorReceived], timeout: 1)
    }
    
    func testErrorPublishingWithFixedRecordingDuration() {
        let framesRenderer = FramesRendererMock()
        framesRenderer.error = AssetGenerationError(errorDescription: "some error reason")
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: 1,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        viewModel.handleRecording(session: session!)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 1 // nil
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 2 // nil, error
        
        cancellables.append(viewModel.$asset.sink { value in
            assetGenerated.fulfill()
        })
        
        cancellables.append(viewModel.$error.sink { error in
            if (error != nil) {
                XCTAssertEqual(error, ViewRecordingError.renderingError(reason: "some error reason"))
            }
            errorReceived.fulfill()
        })
        
        wait(for: [assetGenerated, errorReceived], timeout: 2)
    }
    
    func testValuePublishing() {
        let framesRenderer = FramesRendererMock()
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: nil,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        viewModel.handleRecording(session: session!)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 2 // nil, value
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 1 // nil
        
        cancellables.append(viewModel.$asset.sink { value in
            assetGenerated.fulfill()
        })
        
        cancellables.append(viewModel.$error.sink { error in
            errorReceived.fulfill()
        })
        
        viewModel.stopRecording()
        
        wait(for: [assetGenerated, errorReceived], timeout: 1)
    }
    
    func testValuePublishingWithFixedRecordingDuration() {
        let framesRenderer = FramesRendererMock()
        
        let session = try? ViewRecordingSession(view: testView,
                                                framesRenderer: framesRenderer,
                                                duration: 1/24,
                                                framesPerSecond: 24)
        XCTAssertNotNil(session)
        
        viewModel.handleRecording(session: session!)
        
        let assetGenerated = expectation(description: "asset generated")
        assetGenerated.expectedFulfillmentCount = 2 // nil, value
        
        let errorReceived = expectation(description: "error received")
        errorReceived.expectedFulfillmentCount = 1 // nil
        
        cancellables.append(viewModel.$asset.sink { value in
            assetGenerated.fulfill()
        })
        
        cancellables.append(viewModel.$error.sink { error in
            errorReceived.fulfill()
        })
        
        wait(for: [assetGenerated, errorReceived], timeout: 1)
    }

    static var allTests = [
        ("testErrorPublishing", testErrorPublishing),
        ("testErrorPublishingWithFixedRecordingDuration", testErrorPublishingWithFixedRecordingDuration),
        ("testValuePublishing", testValuePublishing),
        ("testValuePublishingWithFixedRecordingDuration", testValuePublishingWithFixedRecordingDuration)
    ]
}
