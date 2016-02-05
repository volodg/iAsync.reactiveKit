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

        let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

            firstResult = result
            return testStreamWithValue(32, next: 16)
        }

        let expectation = expectationWithDescription("")

        stream.observe { event -> () in

            switch event {
            case .Success(let value):
                secondResult = value
                expectation.fulfill()
            case .Next(let next):
                nexts.append(next)
            case .Failure:
                XCTFail()
            }
        }

        waitForExpectationsWithTimeout(0.5, handler: nil)

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
}
