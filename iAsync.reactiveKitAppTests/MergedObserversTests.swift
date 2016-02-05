//
//  MergedObserversTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

class MergedObserversTests: XCTestCase {

    override func setUp() {

        numberOfObservers = 0
    }

    func testTwoObservsers() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let expectation1 = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                    expectation1.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }
        }

        var nextCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let expectation2 = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                    expectation2.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
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

        XCTAssertEqual(1, numberOfObservers)
    }

    func testTwoObservsersDisposeFirst() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let dispose1 = stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }
        }

        var nextCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let expectation2 = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                    expectation2.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
            }
        }

        XCTAssertNotNil(weakDeinitTest1)
        XCTAssertNotNil(weakDeinitTest2)

        dispose1.dispose()
        deinitTest1 = nil

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(1, numberOfObservers)
    }

    func testTwoObservsersDisposeFirstImmediately() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let dispose1 = stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }
        }

        dispose1.dispose()
        deinitTest1 = nil

        var nextCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let expectation2 = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                    expectation2.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
            }
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNotNil(weakDeinitTest2)

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(2, numberOfObservers)
    }

    func testTwoObservsersDisposeSecond() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let expectation1 = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                    expectation1.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }
        }

        var nextCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let dispose2 = stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
            }
        }

        deinitTest2 = nil
        dispose2.dispose()

        XCTAssertNotNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertNil(weakDeinitTest1)

        XCTAssertEqual(5, nextCalledCount1)
        XCTAssertEqual(0, nextCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertNil(resultValue2)

        XCTAssertEqual(1, numberOfObservers)
    }

    func testTwoObservsersDisposeBoth() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let dispose1 = stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }
        }

        var nextCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let dispose2 = stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
            }
        }

        deinitTest1 = nil
        dispose1.dispose()
        deinitTest2 = nil
        dispose2.dispose()

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(0, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertNil(resultValue2)

        XCTAssertEqual(1, numberOfObservers)
    }

    func testTwoObservsersDisposeReverseBoth() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let dispose1 = stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest1 != nil {
                    deinitTest1 = nil
                    resultValue1 = value
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount1, next as? Int)
                nextCalledCount1 += 1
            }
        }

        var nextCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let dispose2 = stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest2 != nil {
                    deinitTest2 = nil
                    resultValue2 = value
                }
            case .Failure:
                XCTFail()
            case .Next(let next):
                XCTAssertEqual(nextCalledCount2, next as? Int)
                nextCalledCount2 += 1
            }
        }

        deinitTest2 = nil
        dispose2.dispose()
        deinitTest1 = nil
        dispose1.dispose()

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(0, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertNil(resultValue2)

        XCTAssertEqual(1, numberOfObservers)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}
