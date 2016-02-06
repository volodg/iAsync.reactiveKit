//
//  MergedAsyncStreamTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 06/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

import iAsync_reactiveKit

import ReactiveKit

typealias MergerType = MergedAsyncStream<String, String, Int, NSError>

class MergedAsyncStreamTests: XCTestCase {

    override func setUp() {

        numberOfObservers1 = 0
    }

    func testDisposeStream() {

        weak var weakDeinitTest: NSObject?
        weak var weakMerger: MergerType?

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream1 = merger.mergedStream({ testStream() }, key: "1")
            let stream2 = merger.mergedStream({ testStream() }, key: "2")

            let dispose1 = stream1.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }
            let dispose2 = stream1.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }
            let dispose3 = stream2.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }

            dispose1.dispose()
            dispose2.dispose()
            dispose3.dispose()

            XCTAssertNotNil(weakDeinitTest)
        }

        XCTAssertNil(weakMerger)
        XCTAssertNil(weakDeinitTest)
    }

    func testNormalFinishStream() {

        var progressCalledCount1 = 0
        var resultValue1: String?

        var progressCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ testStream() }, key: "1")

            let expectation1 = self.expectationWithDescription("")
            let expectation2 = self.expectationWithDescription("")

            stream.observe { ev -> Void in

                switch ev {
                case .Success(let value):
                    deinitTest.description
                    resultValue1 = value
                    expectation1.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1
                }
            }
            stream.observe { ev -> Void in
                
                switch ev {
                case .Success(let value):
                    deinitTest.description
                    resultValue2 = value
                    expectation2.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(progressCalledCount2, next)
                    progressCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(5, progressCalledCount1)
        XCTAssertEqual("ok", resultValue1)

        XCTAssertEqual(5, progressCalledCount2)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(numberOfObservers1, 1)
    }

    func testDisposeFirstStreamImmediately() {

        var progressCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ testStream() }, key: "1")

            let expectation2 = self.expectationWithDescription("")

            let dispose1 = stream.observe { ev -> Void in

                deinitTest.description
                XCTFail()
            }

            dispose1.dispose()

            stream.observe { ev -> Void in

                switch ev {
                case .Success(let value):
                    deinitTest.description
                    resultValue2 = value
                    expectation2.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(progressCalledCount2, next)
                    progressCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(5, progressCalledCount2)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(numberOfObservers1, 2)
    }

    func testDisposeFirstStreamOnNext() {
    }

    func testDisposeSecondStreamImmediately() {

        var progressCalledCount1 = 0
        var resultValue1: String?

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ testStream() }, key: "1")

            let expectation1 = self.expectationWithDescription("")

            stream.observe { ev -> Void in

                switch ev {
                case .Success(let value):
                    deinitTest.description
                    resultValue1 = value
                    expectation1.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1
                }
            }

            let dispose2 = stream.observe { ev -> Void in

                deinitTest.description
                XCTFail()
            }

            dispose2.dispose()

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(5, progressCalledCount1)
        XCTAssertEqual("ok", resultValue1)

        XCTAssertEqual(numberOfObservers1, 1)
    }

    func testDisposeSecondStreamOnNext() {
    }

    //TODO use merger
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
