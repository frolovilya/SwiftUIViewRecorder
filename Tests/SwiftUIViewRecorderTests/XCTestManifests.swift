import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ViewRecordingSessionTest.allTests),
        testCase(ViewRecordingSessionViewModelTest.allTests),
        testCase(UIImagesToVideoTest.allTests)
    ]
}
#endif
