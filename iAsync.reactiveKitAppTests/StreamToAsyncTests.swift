//
//  StreamToAsyncTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 04/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

import iAsync_async
import iAsync_reactiveKit

import ReactiveKit

class StreamToAsyncTests: XCTestCase {

    override func setUp() {

        numberOfObservers = 0
    }

    func testCancelAsync() {

        let stream = testStream()
        let loader = stream.mapNext { $0 as AnyObject }.streamToAsync()

        var deinitTest: NSObject? = NSObject()
        weak var weakDeinitTest = deinitTest

        var testPassed = false

        let handler = loader(progressCallback: { (progressInfo) -> () in

            XCTFail()
        }, stateCallback: { (state) -> () in

            XCTFail()
        }) { (result) -> Void in

            switch result {
            case .Success:
                XCTFail()
            case .Failure:
                XCTFail()
            case .Interrupted:
                if deinitTest != nil {
                    deinitTest = nil
                    testPassed = true
                }
            case .Unsubscribed:
                XCTFail()
            }
        }

        XCTAssertNotNil(weakDeinitTest)

        handler(task: .Cancel)

        XCTAssertNil(weakDeinitTest)

        XCTAssertTrue(testPassed)
    }

    func testUnsubscribeAsync() {

        let stream = testStream()
        let loader = stream.mapNext { $0 as AnyObject }.streamToAsync()

        var testPassed = false

        var deinitTest: NSObject? = NSObject()
        weak var weakDeinitTest = deinitTest

        let handler = loader(progressCallback: { (progressInfo) -> () in

            XCTFail()
        }, stateCallback: { (state) -> () in

            XCTFail()
        }) { (result) -> Void in

            switch result {
            case .Success:
                XCTFail()
            case .Failure:
                XCTFail()
            case .Interrupted:
                XCTFail()
            case .Unsubscribed:
                if deinitTest != nil {
                    deinitTest = nil
                    testPassed = true
                }
            }
        }

        XCTAssertNotNil(weakDeinitTest)

        handler(task: .UnSubscribe)

        XCTAssertNil(weakDeinitTest)

        XCTAssertTrue(testPassed)
    }

    func testNormalFinishAsync() {

        let stream = testStream()
        let loader = stream.mapNext { $0 as AnyObject }.streamToAsync()

        var progressCalledCount = 0
        var resultValue: String?

        var deinitTest: NSObject? = NSObject()
        weak var weakDeinitTest = deinitTest

        let expectation = expectationWithDescription("")

        let _ = loader(progressCallback: { (next) -> () in

            XCTAssertEqual(progressCalledCount, next as? Int)
            progressCalledCount += 1
        }, stateCallback: { (state) -> () in

            XCTFail()
        }) { (result) -> Void in

            switch result {
            case .Success(let value):
                if deinitTest != nil {
                    deinitTest = nil
                    resultValue = value
                    expectation.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Interrupted:
                XCTFail()
            case .Unsubscribed:
                XCTFail()
            }
        }

        XCTAssertNotNil(weakDeinitTest)

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertNil(weakDeinitTest)

        XCTAssertEqual(5, progressCalledCount)
        XCTAssertEqual("ok", resultValue)

        XCTAssertEqual(1, numberOfObservers)
    }

    func testNumberOfObservers() {

        let stream = testStream()
        let loader = stream.mapNext { $0 as AnyObject }.streamToAsync()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let expectation1 = expectationWithDescription("")

        let _ = loader(progressCallback: { (next) -> () in

            XCTAssertEqual(nextCalledCount1, next as? Int)
            nextCalledCount1 += 1
        }, stateCallback: { (state) -> () in

            XCTFail()
        }) { (result) -> Void in

            switch result {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                    expectation1.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Interrupted:
                XCTFail()
            case .Unsubscribed:
                XCTFail()
            }
        }

        var nextCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let expectation2 = expectationWithDescription("")

        let _ = loader(progressCallback: { (next) -> () in

            XCTAssertEqual(nextCalledCount2, next as? Int)
            nextCalledCount2 += 1
        }, stateCallback: { (state) -> () in

            XCTFail()
        }) { (result) -> Void in

            switch result {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                    expectation2.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Interrupted:
                XCTFail()
            case .Unsubscribed:
                XCTFail()
            }
        }

        XCTAssertNotNil(weakDeinitTest1)
        XCTAssertNotNil(weakDeinitTest2)

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(5, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(2, numberOfObservers)
    }
}
