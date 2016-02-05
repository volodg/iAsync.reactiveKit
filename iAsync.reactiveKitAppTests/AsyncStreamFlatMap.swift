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
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
        XCTAssertEqual(expectedNexts.count, nexts.count)
        for (index, _) in expectedNexts.enumerate() {
            XCTAssertEqual(expectedNexts[index], nexts[index])
        }

        XCTAssertEqual(firstResult, "ok")
        XCTAssertEqual(secondResult, 32)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}
