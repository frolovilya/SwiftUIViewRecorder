import XCTest

import SwiftUIViewRecorderTests

var tests = [XCTestCaseEntry]()
tests += ViewRecordingSessionTest.allTests()
tests += ViewRecordingSessionViewModelTest.allTests()
tests += UIImagesToVideoTest.allTests()
XCTMain(tests)
