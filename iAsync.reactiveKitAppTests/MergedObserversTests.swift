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

        numberOfObservers1 = 0
    }

    func testTwoObservsers() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var nextCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let expectation1 = expectation(description: "")

            _ = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest1.description
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount1, next)
                    nextCalledCount1 += 1
                }
            }

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let expectation2 = expectation(description: "")

            _ = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest2.description
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount2, next)
                    nextCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest1)
            XCTAssertNotNil(weakDeinitTest2)

            waitForExpectations(timeout: 0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(5, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(1, numberOfObservers1)
    }

    func testTwoObservsersDisposeFirst() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var nextCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            autoreleasepool {

                let deinitTest1 = NSObject()
                weakDeinitTest1 = deinitTest1

                let dispose1 = stream.observe { ev in

                    switch ev {
                    case .success(let value):
                        _ = deinitTest1.description
                        resultValue1 = value
                    case .failure:
                        XCTFail()
                    case .next(let next):
                        XCTAssertEqual(nextCalledCount1, next)
                        nextCalledCount1 += 1
                    }
                }

                let deinitTest2 = NSObject()
                weakDeinitTest2 = deinitTest2

                let expectation2 = expectation(description: "")

                _ = stream.observe { ev in

                    switch ev {
                    case .success(let value):
                        _ = deinitTest2.description
                        resultValue2 = value
                        expectation2.fulfill()
                    case .failure:
                        XCTFail()
                    case .next(let next):
                        XCTAssertEqual(nextCalledCount2, next)
                        nextCalledCount2 += 1
                    }
                }

                XCTAssertNotNil(weakDeinitTest1)
                XCTAssertNotNil(weakDeinitTest2)

                dispose1.dispose()
            }

            XCTAssertNil(weakDeinitTest1)

            waitForExpectations(timeout: 0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(1, numberOfObservers1)
    }

    func testTwoObservsersDisposeFirstImmediately() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var nextCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {
            autoreleasepool {

                let deinitTest1 = NSObject()
                weakDeinitTest1 = deinitTest1

                let dispose1 = stream.observe { ev in

                    switch ev {
                    case .success(let value):
                        _ = deinitTest1.description
                        resultValue1 = value
                    case .failure:
                        XCTFail()
                    case .next(let next):
                        XCTAssertEqual(nextCalledCount1, next)
                        nextCalledCount1 += 1
                    }
                }

                dispose1.dispose()
            }
            XCTAssertNil(weakDeinitTest1)

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let expectation2 = expectation(description: "")

            _ = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest2.description
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount2, next)
                    nextCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest2)

            waitForExpectations(timeout: 0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(5, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(2, numberOfObservers1)
    }

    func testTwoObservsersDisposeSecond() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var nextCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let expectation1 = expectation(description: "")

            _ = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest1.description
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount1, next)
                    nextCalledCount1 += 1
                }
            }

            autoreleasepool {

                let deinitTest2 = NSObject()
                weakDeinitTest2 = deinitTest2

                let dispose2 = stream.observe { ev in

                    switch ev {
                    case .success(let value):
                        _ = deinitTest2.description
                        resultValue2 = value
                    case .failure:
                        XCTFail()
                    case .next(let next):
                        XCTAssertEqual(nextCalledCount2, next)
                        nextCalledCount2 += 1
                    }
                }

                dispose2.dispose()
            }

            XCTAssertNotNil(weakDeinitTest1)
            XCTAssertNil(weakDeinitTest2)

            waitForExpectations(timeout: 0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest1)

        XCTAssertEqual(5, nextCalledCount1)
        XCTAssertEqual(0, nextCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertNil(resultValue2)

        XCTAssertEqual(1, numberOfObservers1)
    }

    func testTwoObservsersDisposeBoth() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var nextCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let dispose1 = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest1.description
                    resultValue1 = value
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount1, next)
                    nextCalledCount1 += 1
                }
            }

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let dispose2 = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest2.description
                    resultValue2 = value
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount2, next)
                    nextCalledCount2 += 1
                }
            }

            dispose1.dispose()
            dispose2.dispose()
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(0, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertNil(resultValue2)

        XCTAssertEqual(1, numberOfObservers1)
    }

    func testTwoObservsersDisposeReverseBoth() {

        let stream = testStream().mergedObservers()

        var nextCalledCount1 = 0
        var resultValue1: String?

        var nextCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let dispose1 = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest1.description
                    resultValue1 = value
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount1, next)
                    nextCalledCount1 += 1
                }
            }

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let dispose2 = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest2.description
                    resultValue2 = value
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(nextCalledCount2, next)
                    nextCalledCount2 += 1
                }
            }

            dispose2.dispose()
            dispose1.dispose()
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(0, nextCalledCount1)
        XCTAssertEqual(0, nextCalledCount2)
        XCTAssertNil(resultValue1)
        XCTAssertNil(resultValue2)

        XCTAssertEqual(1, numberOfObservers1)
    }
}
