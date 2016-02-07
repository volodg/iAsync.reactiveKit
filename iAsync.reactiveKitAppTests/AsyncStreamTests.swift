//
//  AsyncStreamTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 07/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

import iAsync_utils

class AsyncStreamTests: XCTestCase {

    override func setUp() {
        super.setUp()

        numberOfObservers1 = 0
    }

    func testRunMethod() {

        let testFunc = { (numberOfCalls: Int) -> Void in

            autoreleasepool {

                testStream().run()

                let expectation = self.expectationWithDescription("")

                let _ = Timer.sharedByThreadTimer().addBlock({ cancel -> Void in
                    cancel()
                    expectation.fulfill()
                }, duration: 0.1)
            }
            self.waitForExpectationsWithTimeout(0.5, handler: nil)

            XCTAssertEqual(numberOfCalls, numberOfObservers1)
        }

        testFunc(1)
        testFunc(2)
    }
}
