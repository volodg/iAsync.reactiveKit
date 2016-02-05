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

        numberOfObservers1 = 0
    }

    func testCancelAsync() {

        let stream = testStream()
        let loader = stream.mapNext { $0 as AnyObject }.streamToAsync()

        var deinitTest: NSObject? = NSObject()
        weak var weakDeinitTest = deinitTest

        var testPassed = false

        let handler = loader(progressCallback: { (progressInfo) -> () in

            if deinitTest != nil {
                XCTFail()
            } else {
                XCTFail()
            }
        }, stateCallback: { (state) -> () in

            if deinitTest != nil {
                XCTFail()
            } else {
                XCTFail()
            }
        }) { (result) -> Void in

            switch result {
            case .Success:
                XCTFail()
            case .Failure:
                XCTFail()
            case .Interrupted:
                if deinitTest != nil {
                    testPassed = true
                }
            case .Unsubscribed:
                XCTFail()
            }
        }

        XCTAssertNotNil(weakDeinitTest)

        handler(task: .Cancel)

        deinitTest = nil
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

            if deinitTest != nil {
                XCTFail()
            } else {
                XCTFail()
            }
        }, stateCallback: { (state) -> () in

            if deinitTest != nil {
                XCTFail()
            } else {
                XCTFail()
            }
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
                    testPassed = true
                }
            }
        }

        XCTAssertNotNil(weakDeinitTest)

        handler(task: .UnSubscribe)

        deinitTest = nil
        XCTAssertNil(weakDeinitTest)

        XCTAssertTrue(testPassed)
    }

    func testNormalFinishAsync() {

        let loader = testStream().mapNext { $0 as AnyObject }.streamToAsync()

        let testFunc = { (numberOfCalls: Int) -> Void in

            var progressCalledCount = 0
            var resultValue: String?

            var deinitTest: NSObject? = NSObject()
            weak var weakDeinitTest = deinitTest

            let expectation = self.expectationWithDescription("")

            let _ = loader(progressCallback: { (next) -> () in

                if deinitTest != nil {
                    XCTAssertEqual(progressCalledCount, next as? Int)
                    progressCalledCount += 1
                }
            }, stateCallback: { (state) -> () in

                if deinitTest != nil {
                    XCTFail()
                } else {
                    XCTFail()
                }
            }) { (result) -> Void in

                switch result {
                case .Success(let value):
                    if deinitTest != nil {
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

            self.waitForExpectationsWithTimeout(0.5, handler: nil)

            deinitTest = nil
            XCTAssertNil(weakDeinitTest)

            XCTAssertEqual(5, progressCalledCount)
            XCTAssertEqual("ok", resultValue)

            XCTAssertEqual(numberOfCalls, numberOfObservers1)
        }

        testFunc(1)
        testFunc(2)
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

            if deinitTest1 != nil {
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }
        }, stateCallback: { (state) -> () in

            if deinitTest1 != nil {
                XCTFail()
            } else {
                XCTFail()
            }
        }) { (result) -> Void in

            switch result {
            case .Success(let value):
                if deinitTest1 != nil {
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

            if deinitTest2 != nil {
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
            }
        }, stateCallback: { (state) -> () in

            if deinitTest2 != nil {
                XCTFail()
            } else {
                XCTFail()
            }
        }) { (result) -> Void in

            switch result {
            case .Success(let value):
                if deinitTest2 != nil {
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

        deinitTest1 = nil
        deinitTest2 = nil
        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(5, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(2, numberOfObservers1)
    }
}
