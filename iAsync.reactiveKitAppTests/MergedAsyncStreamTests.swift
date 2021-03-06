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
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount1 += 1
                        dispose.dispose()
                    }
                }
            }, key: "1")
            let stream2 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount2 += 1
                        dispose.dispose()
                    }
                }
            }, key: "2")

            let dispose1 = stream1.observe { result in

                _ = deinitTest.description
                XCTFail()
            }
            let dispose2 = stream1.observe { result in

                _ = deinitTest.description
                XCTFail()
            }
            let dispose3 = stream2.observe { result in

                _ = deinitTest.description
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

    func testNormalFinishStreamWithSharedNextBuffer() {

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

            let merger = MergerType(sharedNextLimit: 1)
            weakMerger = merger

            let stream = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in

                let stream = testStream().withEventValue(setter: { event in
                    _ = deinitTest.description

                    setterEventCallsCount += 1
                    switch event {
                    case .success(let value):
                        setterResult = value
                        setterValueCallsCount += 1
                    default:
                        break
                    }
                }).withEventValue(getter: { () -> AsyncEvent<String, Int, NSError>? in

                    getterCallsCount += 1
                    _ = deinitTest.description
                    return .next(-1)
                })

                return stream
            }, key: "1")

            let expectation1 = self.expectation(description: "")
            let expectation2 = self.expectation(description: "")

            _ = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    nextValues1.append(next)
                    if progressCalledCount1 == 0 {
                        XCTAssertEqual(-1, next)
                    } else {
                        XCTAssertEqual(progressCalledCount1, next + 1)
                    }
                    progressCalledCount1 += 1
                }
            }
            _ = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
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

            self.waitForExpectations(timeout: 0.5, handler: nil)
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

                let stream = testStream().withEventValue(setter: { _ in
                    _ = deinitTest.description
                    XCTFail()
                }).withEventValue(getter: { () -> AsyncEvent<String, Int, NSError>? in
                    getterCallsCount += 1
                    _ = deinitTest.description
                    return .success("ok1")
                })

                return stream
            }, key: "1")

            let expectation1 = self.expectation(description: "")
            let expectation2 = self.expectation(description: "")

            _ = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1
                }
            }
            _ = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(progressCalledCount2, next)
                    progressCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectations(timeout: 0.5, handler: nil)
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
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                }
            }, key: "1")

            let expectation2 = self.expectation(description: "")

            let dispose1 = stream.observe { ev in

                _ = deinitTest.description
                XCTFail()
            }

            dispose1.dispose()

            _ = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest.description
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(progressCalledCount2, next)
                    progressCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectations(timeout: 0.5, handler: nil)
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
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                }
            }, key: "1")

            let expectation1 = self.expectation(description: "")
            let expectation2 = self.expectation(description: "")

            var dispose: Disposable?

            dispose = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success:
                    XCTFail()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1

                    if next == 2 {
                        dispose?.dispose()
                        expectation1.fulfill()
                        return
                    }
                }
            }
            _ = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest.description
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(progressCalledCount2, next)
                    progressCalledCount2 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectations(timeout: 0.5, handler: nil)
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
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                }
            }, key: "1")

            let expectation1 = self.expectation(description: "")

            _ = stream.observe { ev in

                switch ev {
                case .success(let value):
                    _ = deinitTest.description
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1
                }
            }

            let dispose2 = stream.observe { ev in

                _ = deinitTest.description
                XCTFail()
            }

            dispose2.dispose()

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectations(timeout: 0.5, handler: nil)
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
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount += 1
                        dispose.dispose()
                    }
                }
            }, key: "1")

            let expectation1 = self.expectation(description: "")
            let expectation2 = self.expectation(description: "")

            var dispose: Disposable?

            _ = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1
                }
            }
            dispose = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success:
                    XCTFail()
                case .failure:
                    XCTFail()
                case .next(let next):
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

            self.waitForExpectations(timeout: 0.5, handler: nil)
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
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount1 += 1
                        dispose.dispose()
                    }
                }
            }, key: "1")
            let stream2 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount2 += 1
                        dispose.dispose()
                    }
                }
            }, key: "2")

            let dispose1 = stream1.observe { result in

                _ = deinitTest.description
                XCTFail()
            }
            dispose1.dispose()

            let dispose2 = stream1.observe { result in

                _ = deinitTest.description
                XCTFail()
            }
            dispose2.dispose()

            let dispose3 = stream2.observe { result in

                _ = deinitTest.description
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
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount1 += 1
                        dispose.dispose()
                    }
                }
            }, key: "1")
            let stream2 = merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                return AsyncStream { observer in
                    let dispose = testStream().observe(observer)
                    return BlockDisposable {
                        disposeCount2 += 1
                        dispose.dispose()
                    }
                }
            }, key: "2")

            let dispose1 = stream1.observe { result in

                _ = deinitTest.description
                XCTFail()
            }

            let dispose2 = stream1.observe { result in

                _ = deinitTest.description
                XCTFail()
            }
            dispose2.dispose()
            dispose1.dispose()

            let dispose3 = stream2.observe { result in

                _ = deinitTest.description
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

            let stream = merger.mergedStream({ testStream() }, key: "1", getter: { () -> AsyncEvent<String, Int, NSError>? in

                getterCallsCount += 1
                _ = deinitTest.description
                return .next(-1)
            }, setter: { event in

                _ = deinitTest.description

                setterEventCallsCount += 1
                switch event {
                case .success(let value):
                    setterResult = value
                    setterValueCallsCount += 1
                default:
                    break
                }
            })

            let expectation1 = self.expectation(description: "")
            let expectation2 = self.expectation(description: "")

            _ = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    nextValues1.append(next)
                    if progressCalledCount1 == 0 {
                        XCTAssertEqual(-1, next)
                    } else {
                        XCTAssertEqual(progressCalledCount1, next + 1)
                    }
                    progressCalledCount1 += 1
                }
            }
            _ = stream.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
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

            self.waitForExpectations(timeout: 0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(2, getterCallsCount)
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

    func testNormalFinishStreamFactoryCountCalls() {

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
        var factoryCountCalls = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let createStream = { (force: Bool) -> AsyncStream<String, Int, NSError> in

                return merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                    factoryCountCalls += 1
                    return testStream()
                }, key: "1", getter: { () -> AsyncEvent<String, Int, NSError>? in

                    getterCallsCount += 1
                    _ = deinitTest.description
                    //return .successs("sucess-ok")
                    return .next(-1)
                }, setter: { event in

                    _ = deinitTest.description

                    setterEventCallsCount += 1
                    switch event {
                    case .success(let value):
                        setterResult = value
                        setterValueCallsCount += 1
                    default:
                        break
                    }
                })
            }

            let stream1 = createStream(false)
            let stream2 = createStream(false)

            let expectation1 = self.expectation(description: "")
            let expectation2 = self.expectation(description: "")

            _ = stream1.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    nextValues1.append(next)
                    if progressCalledCount1 == 0 {
                        XCTAssertEqual(-1, next)
                    } else {
                        XCTAssertEqual(progressCalledCount1, next + 1)
                    }
                    progressCalledCount1 += 1
                }
            }
            _ = stream2.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
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

            self.waitForExpectations(timeout: 0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(2, getterCallsCount)
        XCTAssertEqual(setterResult, "ok")
        XCTAssertEqual(6, setterEventCallsCount)
        XCTAssertEqual(1, setterValueCallsCount)

        XCTAssertEqual(6, progressCalledCount1)
        XCTAssertEqual([-1, 0, 1, 2, 3, 4], nextValues1)
        XCTAssertEqual("ok", resultValue1)

        XCTAssertEqual(6, progressCalledCount2)
        XCTAssertEqual([-1, 0, 1, 2, 3, 4], nextValues2)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(factoryCountCalls, 1)
        XCTAssertEqual(numberOfObservers1, 1)
    }

    func testForceLoad() {

        var progressCalledCount0 = 0
        var resultValue0: String?
        var nextValues0 = [Int]()

        var progressCalledCount1 = 0
        var resultValue1: String?
        var nextValues1 = [Int]()

        var progressCalledCount2 = 0
        var resultValue2: String?
        var nextValues2 = [Int]()

        var progressCalledCount3 = 0
        var resultValue3: String?
        var nextValues3 = [Int]()

        weak var weakDeinitTest: NSObject? = nil
        weak var weakMerger: MergerType?

        var getterCallsCount = 0
        var setterResult: String?
        var setterEventCallsCount = 0
        var setterValueCallsCount = 0
        var factoryCountCalls = 0

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let merger = MergerType()
            weakMerger = merger

            let createStream = { (force: Bool) -> AsyncStream<String, Int, NSError> in

                return merger.mergedStream({ () -> AsyncStream<String, Int, NSError> in
                    factoryCountCalls += 1
                    return testStream()
                }, key: "1", getter: { () -> AsyncEvent<String, Int, NSError>? in

                    getterCallsCount += 1

                    if force {
                        return nil
                    }

                    _ = deinitTest.description
                    return .success("sucess-ok")
                }, setter: { event in

                    _ = deinitTest.description

                    setterEventCallsCount += 1
                    switch event {
                    case .success(let value):
                        setterResult = value
                        setterValueCallsCount += 1
                    default:
                        break
                    }
                })
            }

            let stream0 = createStream(false)
            let stream1 = createStream(true)
            let stream2 = createStream(true)
            let stream3 = createStream(false)

            let expectation0 = self.expectation(description: "")
            let expectation1 = self.expectation(description: "")
            let expectation2 = self.expectation(description: "")
            let expectation3 = self.expectation(description: "")

            _ = stream0.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue0 = value
                    expectation0.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    nextValues0.append(next)
                    XCTAssertEqual(progressCalledCount0, next)
                    progressCalledCount0 += 1
                }
            }
            _ = stream1.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    nextValues1.append(next)
                    XCTAssertEqual(progressCalledCount1, next)
                    progressCalledCount1 += 1
                }
            }
            _ = stream2.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    nextValues2.append(next)
                    XCTAssertEqual(progressCalledCount2, next)
                    progressCalledCount2 += 1
                }
            }
            _ = stream3.observe { ev in

                _ = deinitTest.description

                switch ev {
                case .success(let value):
                    resultValue3 = value
                    expectation3.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    nextValues3.append(next)
                    XCTAssertEqual(progressCalledCount3, next)
                    progressCalledCount3 += 1
                }
            }

            XCTAssertNotNil(weakDeinitTest)

            self.waitForExpectations(timeout: 0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest)
        XCTAssertNil(weakMerger)

        XCTAssertEqual(4, getterCallsCount)
        XCTAssertEqual(setterResult, "ok")
        XCTAssertEqual(6, setterEventCallsCount)
        XCTAssertEqual(1, setterValueCallsCount)

        XCTAssertEqual(0, progressCalledCount0)
        XCTAssertEqual([], nextValues0)
        XCTAssertEqual("sucess-ok", resultValue0)

        XCTAssertEqual(5, progressCalledCount1)
        XCTAssertEqual([0, 1, 2, 3, 4], nextValues1)
        XCTAssertEqual("ok", resultValue1)

        XCTAssertEqual(5, progressCalledCount2)
        XCTAssertEqual([0, 1, 2, 3, 4], nextValues2)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(0, progressCalledCount3)
        XCTAssertEqual([], nextValues3)
        XCTAssertEqual("sucess-ok", resultValue3)

        XCTAssertEqual(factoryCountCalls, 1)
        XCTAssertEqual(numberOfObservers1, 1)
    }

    //TODO test dealloc merger while loading
}
