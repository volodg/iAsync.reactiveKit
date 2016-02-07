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

    func testDisposeBothStream() {

        weak var weakDeinitTest: NSObject?
        weak var weakMerger: MergerType?

        var disposeCount1 = 0
        var disposeCount2 = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream1 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount1 += 1
                        dispose.dispose()
                    }
                })
            }, key: "1")
            let stream2 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount2 += 1
                        dispose.dispose()
                    }
                })
            }, key: "2")

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

        XCTAssertEqual(1, disposeCount1)
        XCTAssertEqual(1, disposeCount2)

        XCTAssertNil(weakMerger)
        XCTAssertNil(weakDeinitTest)
    }

    func testNormalFinishStream() {

        var progressCalledCount1 = 0
        var resultValue1: String?
        var nextValues1 = [Int]()

        var progressCalledCount2 = 0
        var resultValue2: String?
        var nextValues2 = [Int]()

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        var getterCallsCount = 0
        var setterResult: String?
        var setterEventCallsCount = 0
        var setterValueCallsCount = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in

                let stream = testStream().withEventValue({ () -> AsyncEvent<String, Int, NSError>? in

                    getterCallsCount += 1
                    deinitTest.description
                    return .Next(-1)
                }, setter: { event -> Void in

                    deinitTest.description

                    setterEventCallsCount += 1
                    switch event {
                    case .Success(let value):
                        setterResult = value
                        setterValueCallsCount += 1
                    default:
                        break
                    }
                })

                return stream
            }, key: "1")

            let expectation1 = self.expectationWithDescription("")
            let expectation2 = self.expectationWithDescription("")

            stream.observe { ev -> Void in

                deinitTest.description

                switch ev {
                case .Success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    nextValues1.append(next)
                    if progressCalledCount1 == 0 {
                        XCTAssertEqual(-1, next)
                    } else {
                        XCTAssertEqual(progressCalledCount1, next + 1)
                    }
                    progressCalledCount1 += 1
                }
            }
            stream.observe { ev -> Void in

                deinitTest.description

                switch ev {
                case .Success(let value):
                    resultValue2 = value
                    expectation2.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    nextValues2.append(next)
                    if progressCalledCount2 == 0 {
                        XCTAssertEqual(-1, next)
                    } else {
                        XCTAssertEqual(progressCalledCount2, next + 1)
                    }
                    progressCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(1, getterCallsCount)
        XCTAssertEqual(setterResult, "ok")
        XCTAssertEqual(6, setterEventCallsCount)
        XCTAssertEqual(1, setterValueCallsCount)

        XCTAssertEqual(6, progressCalledCount1)
        XCTAssertEqual([-1, 0, 1, 2, 3, 4], nextValues1)
        XCTAssertEqual("ok", resultValue1)

        XCTAssertEqual(6, progressCalledCount2)
        XCTAssertEqual([-1, 0, 1, 2, 3, 4], nextValues2)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(numberOfObservers1, 1)
    }

    func testNormalImmediatelyFinishStream() {

        var progressCalledCount1 = 0
        var resultValue1: String?

        var progressCalledCount2 = 0
        var resultValue2: String?

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        var getterCallsCount = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in

                let stream = testStream().withEventValue({ () -> AsyncEvent<String, Int, NSError>? in

                    getterCallsCount += 1
                    deinitTest.description
                    return .Success("ok1")
                }, setter: { event -> Void in

                    deinitTest.description
                    XCTFail()
                })

                return stream
            }, key: "1")

            let expectation1 = self.expectationWithDescription("")
            let expectation2 = self.expectationWithDescription("")

            stream.observe { ev -> Void in

                deinitTest.description

                switch ev {
                case .Success(let value):
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

                deinitTest.description

                switch ev {
                case .Success(let value):
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

        XCTAssertEqual(2, getterCallsCount)

        XCTAssertEqual(0, progressCalledCount1)
        XCTAssertEqual("ok1", resultValue1)

        XCTAssertEqual(0, progressCalledCount2)
        XCTAssertEqual("ok1", resultValue2)

        XCTAssertEqual(numberOfObservers1, 0)
    }

    func testDisposeFirstStreamImmediately() {

        var progressCalledCount2 = 0
        var disposeCount = 0
        var resultValue2: String?

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                })
            }, key: "1")

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
        XCTAssertEqual(1, disposeCount)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(numberOfObservers1, 2)
    }

    func testDisposeFirstStreamOnNext() {

        var progressCalledCount1 = 0

        var progressCalledCount2 = 0
        var resultValue2: String?
        var disposeCount = 0

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                })
            }, key: "1")

            let expectation1 = self.expectationWithDescription("")
            let expectation2 = self.expectationWithDescription("")

            var dispose: DisposableType?

            dispose = stream.observe { ev -> Void in

                deinitTest.description

                switch ev {
                case .Success:
                    XCTFail()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1

                    if next == 2 {
                        dispose?.dispose()
                        expectation1.fulfill()
                        return
                    }
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

        XCTAssertEqual(3, progressCalledCount1)
        XCTAssertEqual(0, disposeCount)

        XCTAssertEqual(5, progressCalledCount2)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(numberOfObservers1, 1)
    }

    func testDisposeSecondStreamImmediately() {

        var progressCalledCount1 = 0
        var resultValue1: String?

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        var disposeCount = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                })
            }, key: "1")

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
        XCTAssertEqual(0, disposeCount)
        XCTAssertEqual("ok", resultValue1)

        XCTAssertEqual(numberOfObservers1, 1)
    }

    func testDisposeSecondStreamOnNext() {

        var progressCalledCount2 = 0

        var progressCalledCount1 = 0
        var resultValue1: String?

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        var disposeCount = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                })
            }, key: "1")

            let expectation1 = self.expectationWithDescription("")
            let expectation2 = self.expectationWithDescription("")

            var dispose: DisposableType?

            stream.observe { ev -> Void in

                deinitTest.description

                switch ev {
                case .Success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1
                }
            }
            dispose = stream.observe { ev -> Void in

                deinitTest.description

                switch ev {
                case .Success:
                    XCTFail()
                case .Failure:
                    XCTFail()
                case .Next(let next):
                    XCTAssertEqual(progressCalledCount2, next)
                    progressCalledCount2 += 1

                    if next == 2 {
                        dispose?.dispose()
                        expectation2.fulfill()
                        return
                    }
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(3, progressCalledCount2)
        XCTAssertEqual(0, disposeCount)

        XCTAssertEqual(5, progressCalledCount1)
        XCTAssertEqual("ok", resultValue1)

        XCTAssertEqual(numberOfObservers1, 1)
    }

    func testDisposeBothFirstImmediately() {

        weak var weakDeinitTest: NSObject?
        weak var weakMerger: MergerType?

        var disposeCount1 = 0
        var disposeCount2 = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream1 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount1 += 1
                        dispose.dispose()
                    }
                })
            }, key: "1")
            let stream2 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount2 += 1
                        dispose.dispose()
                    }
                })
            }, key: "2")

            let dispose1 = stream1.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }
            dispose1.dispose()

            let dispose2 = stream1.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }
            dispose2.dispose()

            let dispose3 = stream2.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }
            dispose3.dispose()

            XCTAssertNotNil(weakDeinitTest)
        }

        XCTAssertEqual(2, disposeCount1)
        XCTAssertEqual(1, disposeCount2)

        XCTAssertNil(weakMerger)
        XCTAssertNil(weakDeinitTest)

        XCTAssertEqual(3, numberOfObservers1)
    }

    func testDisposeBothSecondImmediately() {

        weak var weakDeinitTest: NSObject?
        weak var weakMerger: MergerType?

        var disposeCount1 = 0
        var disposeCount2 = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let stream1 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount1 += 1
                        dispose.dispose()
                    }
                })
            }, key: "1")
            let stream2 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return create(producer: { observer -> DisposableType? in
                    let dispose = testStream().observe(observer: observer)
                    return BlockDisposable {
                        disposeCount2 += 1
                        dispose.dispose()
                    }
                })
            }, key: "2")

            let dispose1 = stream1.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }

            let dispose2 = stream1.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }
            dispose2.dispose()
            dispose1.dispose()

            let dispose3 = stream2.observe { result -> Void in

                deinitTest.description
                XCTFail()
            }
            dispose3.dispose()

            XCTAssertNotNil(weakDeinitTest)
        }

        XCTAssertEqual(1, disposeCount1)
        XCTAssertEqual(1, disposeCount2)

        XCTAssertNil(weakMerger)
        XCTAssertNil(weakDeinitTest)

        XCTAssertEqual(2, numberOfObservers1)
    }
}
