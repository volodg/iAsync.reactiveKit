//
//  MergedAsyncStreamTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 06/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

class MergedAsyncStreamTests: XCTestCase {

    override func setUp() {

        numberOfObservers1 = 0
    }

    func testDisposeStream() {

        let stream = testStream()

        weak var weakDeinitTest: NSObject? = nil

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let dispose = stream.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }

            dispose.dispose()

            XCTAssertNotNil(weakDeinitTest)
        }

        XCTAssertNil(weakDeinitTest)
    }
    
    func testNormalFinishStream() {

        let stream = testStream()

        let testFunc = { (numberOfCalls: Int) -> Void in

            var progressCalledCount = 0
            var resultValue: String?

            weak var weakDeinitTest: NSObject? = nil

            autoreleasepool {

                let deinitTest = NSObject()
                weakDeinitTest = deinitTest

                let expectation = self.expectationWithDescription("")

                stream.observe { ev -> Void in

                    switch ev {
                    case .Success(let value):
                        deinitTest.description
                        resultValue = value
                        expectation.fulfill()
                    case .Failure:
                        XCTFail()
                    case .Next(let next):
                        XCTAssertEqual(progressCalledCount, next)
                        progressCalledCount += 1
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
    
    func testNumberOfStream() {

        let stream = testStream()

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

            stream.observe { ev -> Void in

                switch ev {
                case .Success(let value):
                    deinitTest1.description
                    resultValue1 = value
                    expectation1.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(nextCalledCount1, next)
                    nextCalledCount1 += 1
                }
            }

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let expectation2 = expectationWithDescription("")

            stream.observe { ev -> Void in

                switch ev {
                case .Success(let value):
                    deinitTest2.description
                    resultValue2 = value
                    expectation2.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(nextCalledCount2, next)
                    nextCalledCount2 += 1
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
