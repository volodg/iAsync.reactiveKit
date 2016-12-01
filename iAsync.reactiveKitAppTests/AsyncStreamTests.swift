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

        let testFunc = { (numberOfCalls: Int) in

            autoreleasepool {

                testStream().run()

                let expectation = self.expectation(description: "")

                let _ = Timer.sharedByThreadTimer().add(actionBlock: { cancel in
                    cancel()
                    expectation.fulfill()
                }, delay: .milliseconds(100))
            }
            self.waitForExpectations(timeout: 0.5, handler: nil)

            XCTAssertEqual(numberOfCalls, numberOfObservers1)
        }

        testFunc(1)
        testFunc(2)
    }
}
