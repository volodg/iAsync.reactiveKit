//
//  AsyncStreamFlatMap.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

import iAsync_reactiveKit

import ReactiveKit

class AsyncStreamFlatMap: XCTestCase {

    override func setUp() {
        super.setUp()

        numberOfObservers1 = 0
        numberOfObservers2 = 0
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNormalBehaviour() {

        let stream1 = testStream()

        var nexts: [Int] = []
        var firstResult: String?
        var secondResult: Int?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

            if deinitTest1 != nil {
                firstResult = result
                return testStreamWithValue(32, next: 16)
            }
            fatalError()
        }

        let expectation = expectationWithDescription("")

        stream.observe { event -> () in

            switch event {
            case .Success(let value):
                if deinitTest2 != nil {
                    secondResult = value
                    expectation.fulfill()
                }
            case .Next(let next):
                nexts.append(next)
            case .Failure:
                XCTFail()
            }
        }

        XCTAssertNotNil(weakDeinitTest1)
        XCTAssertNotNil(weakDeinitTest2)

        waitForExpectationsWithTimeout(0.5, handler: nil)

        deinitTest1 = nil
        deinitTest2 = nil
        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        let expectedNexts = [0,1,2,3,4,16,16]
        XCTAssertEqual(expectedNexts, nexts)

        XCTAssertEqual(firstResult, "ok")
        XCTAssertEqual(secondResult, 32)

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 1)
    }

    func testCancelAfterStart() {

        let stream1 = testStream()

        let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

            XCTFail()
            return testStreamWithValue(32, next: 16)
        }

        let dispose = stream.observe { event -> () in

            switch event {
            case .Success:
                XCTFail()
            case .Next:
                XCTFail()
            case .Failure:
                XCTFail()
            }
        }

        dispose.dispose()

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 0)
    }

    func testCancelAfterNextOfFirst() {
    }

    func testCancelAfterFirst() {
    }

    func testCancelAfterNextOfSecond() {
    }
}
