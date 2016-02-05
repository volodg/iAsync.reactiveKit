//
//  MergedObserversTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

class MergedObserversTests: XCTestCase {

    override func setUp() {

        numberOfObservers = 0
    }

    func testTwoObservsers() {

        let stream = testStream().mergedObservers()

        var progressCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let expectation1 = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                    expectation1.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Progress(let progress):
                XCTAssertEqual(progressCalledCount1, progress as? Int)
                progressCalledCount1 += 1
            }
        }

        var progressCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let expectation2 = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                    expectation2.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Progress(let progress):
                XCTAssertEqual(progressCalledCount2, progress as? Int)
                progressCalledCount2 += 1
            }
        }

        XCTAssertNotNil(weakDeinitTest1)
        XCTAssertNotNil(weakDeinitTest2)

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(5, progressCalledCount1)
        XCTAssertEqual(5, progressCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(1, numberOfObservers)
    }

    func testTwoObservsersDisposeFirst() {
    }

    func testTwoObservsersDisposeSecond() {
    }

    func testTwoObservsersDisposeBoth() {
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}
