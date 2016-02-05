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

        var testPassed = false
        weak var weakDeinitTest: NSObject? = nil

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let handler = loader(progressCallback: { (progressInfo) -> () in

                deinitTest.description
                XCTFail()
            }, stateCallback: { (state) -> () in

                deinitTest.description
                XCTFail()
            }) { (result) -> Void in

                switch result {
                case .Success:
                    XCTFail()
                case .Failure:
                    XCTFail()
                case .Interrupted:
                    deinitTest.description
                    testPassed = true
                case .Unsubscribed:
                    XCTFail()
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            handler(task: .Cancel)
        }

        XCTAssertNil(weakDeinitTest)

        XCTAssertTrue(testPassed)
    }

    func testUnsubscribeAsync() {

        let stream = testStream()
        let loader = stream.mapNext { $0 as AnyObject }.streamToAsync()

        var testPassed = false

        weak var weakDeinitTest: NSObject? = nil

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let handler = loader(progressCallback: { (progressInfo) -> () in

                deinitTest.description
                XCTFail()
            }, stateCallback: { (state) -> () in

                deinitTest.description
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
                    deinitTest.description
                    testPassed = true
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            handler(task: .UnSubscribe)
        }

        XCTAssertNil(weakDeinitTest)

        XCTAssertTrue(testPassed)
    }

    func testNormalFinishAsync() {

        let loader = testStream().mapNext { $0 as AnyObject }.streamToAsync()

        let testFunc = { (numberOfCalls: Int) -> Void in

            var progressCalledCount = 0
            var resultValue: String?

            weak var weakDeinitTest: NSObject? = nil

            autoreleasepool {

                let deinitTest = NSObject()
                weakDeinitTest = deinitTest

                let expectation = self.expectationWithDescription("")

                let _ = loader(progressCallback: { (next) -> () in

                    deinitTest.description
                    XCTAssertEqual(progressCalledCount, next as? Int)
                    progressCalledCount += 1
                }, stateCallback: { (state) -> () in

                    deinitTest.description
                    XCTFail()
                }) { (result) -> Void in

                    switch result {
                    case .Success(let value):
                        deinitTest.description
                        resultValue = value
                        expectation.fulfill()
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
            }

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

        var nextCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let expectation1 = expectationWithDescription("")

            let _ = loader(progressCallback: { (next) -> () in

                deinitTest1.description
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }, stateCallback: { (state) -> () in

                deinitTest1.description
                XCTFail()
            }) { (result) -> Void in

                switch result {
                case .Success(let value):
                    deinitTest1.description
                    resultValue1 = value
                    expectation1.fulfill()
                case .Failure:
                    XCTFail()
                case .Interrupted:
                    XCTFail()
                case .Unsubscribed:
                    XCTFail()
                }
            }

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let expectation2 = expectationWithDescription("")

            let _ = loader(progressCallback: { (next) -> () in

                deinitTest2.description
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
            }, stateCallback: { (state) -> () in

                deinitTest2.description
                XCTFail()
            }) { (result) -> Void in

                switch result {
                case .Success(let value):
                    deinitTest2.description
                    resultValue2 = value
                    expectation2.fulfill()
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
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(5, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(2, numberOfObservers1)
    }
}
