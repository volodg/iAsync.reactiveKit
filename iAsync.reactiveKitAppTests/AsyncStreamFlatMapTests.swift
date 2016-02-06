//
//  AsyncStreamFlatMapTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

import iAsync_reactiveKit

import ReactiveKit

class AsyncStreamFlatMapTests: XCTestCase {

    override func setUp() {
        super.setUp()

        numberOfObservers1 = 0
        numberOfObservers2 = 0
    }

    func testNormalBehaviour() {

        let stream1 = testStream()

        var nexts: [Int] = []
        var firstResult: String?
        var secondResult: Int?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

                deinitTest1.description
                firstResult = result
                return testStreamWithValue(32, next: 16)
            }

            let expectation = expectationWithDescription("")

            stream.observe { event -> () in

                switch event {
                case .Success(let value):
                    deinitTest2.description
                    secondResult = value
                    expectation.fulfill()
                case .Next(let next):
                    nexts.append(next)
                case .Failure:
                    XCTFail()
                }
            }

            XCTAssertNotNil(weakDeinitTest1)
            XCTAssertNotNil(weakDeinitTest2)

            waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        let expectedNexts = [0,1,2,3,4,16,16]
        XCTAssertEqual(expectedNexts, nexts)

        XCTAssertEqual(firstResult, "ok")
        XCTAssertEqual(secondResult, 32)

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 1)
    }

    func testCancelAfterStart() {

        let stream1 = testStream()

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

                deinitTest1.description
                XCTFail()
                return testStreamWithValue(32, next: 16)
            }

            let dispose = stream.observe { event -> () in

                deinitTest2.description
                XCTFail()
            }

            dispose.dispose()
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 0)
    }

    func testCancelAfterNextOfFirst() {

        let stream1 = testStream()

        var nexts: [Int] = []

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

                deinitTest1.description
                return testStreamWithValue(32, next: 16)
            }

            let expectation = expectationWithDescription("")

            let dispose = stream.observe { event -> () in

                switch event {
                case .Success:
                    deinitTest2.description
                    XCTFail()
                case .Next(let next):
                    if next == 2 {
                        expectation.fulfill()
                        return
                    }
                    nexts.append(next)
                case .Failure:
                    XCTFail()
                }
            }

            XCTAssertNotNil(weakDeinitTest1)
            XCTAssertNotNil(weakDeinitTest2)

            waitForExpectationsWithTimeout(0.5, handler: nil)
            dispose.dispose()
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        let expectedNexts = [0,1]
        XCTAssertEqual(expectedNexts, nexts)

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 0)
    }

    func testCancelAfterFirst() {

        let stream1 = testStream()

        var nexts: [Int] = []
        var firstResult: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            var dispose: DisposableType?

            let expectation = expectationWithDescription("")

            let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

                dispose?.dispose()
                expectation.fulfill()
                //dispose = nil
                deinitTest1.description
                firstResult = result
                return testStreamWithValue(32, next: 16)
            }

            dispose = stream.observe { event -> () in

                deinitTest2.description

                switch event {
                case .Success:
                    XCTFail()
                case .Next(let next):
                    nexts.append(next)
                case .Failure:
                    XCTFail()
                }
            }

            XCTAssertNotNil(weakDeinitTest1)
            XCTAssertNotNil(weakDeinitTest2)

            waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        let expectedNexts = [0,1,2,3,4]
        XCTAssertEqual(expectedNexts, nexts)

        XCTAssertEqual(firstResult, "ok")

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 0)
    }

    func testCancelAfterRunSecond() {

        let stream1 = testStream()

        var nexts: [Int] = []
        var firstResult: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            var dispose: DisposableType?

            let expectation = expectationWithDescription("")

            let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

                let stream2 = testStreamWithValue(32, next: 16).on(start: { () -> Void in
                    dispose?.dispose()
                    expectation.fulfill()
                })

                deinitTest1.description
                firstResult = result
                return stream2
            }

            dispose = stream.observe { event -> () in

                deinitTest2.description

                switch event {
                case .Success:
                    XCTFail()
                case .Next(let next):
                    nexts.append(next)
                case .Failure:
                    XCTFail()
                }
            }

            XCTAssertNotNil(weakDeinitTest1)
            XCTAssertNotNil(weakDeinitTest2)

            waitForExpectationsWithTimeout(0.5, handler: nil)
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        let expectedNexts = [0,1,2,3,4]
        XCTAssertEqual(expectedNexts, nexts)

        XCTAssertEqual(firstResult, "ok")

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 1)
    }

    func testCancelAfterNextOfSecond() {

        let stream1 = testStream()

        var nexts: [Int] = []
        var firstResult: String?

        weak var weakDeinitTest1: NSObject? = nil
        weak var weakDeinitTest2: NSObject? = nil

        autoreleasepool {

            let deinitTest1 = NSObject()
            weakDeinitTest1 = deinitTest1

            let deinitTest2 = NSObject()
            weakDeinitTest2 = deinitTest2

            let stream = stream1.flatMap(.Latest) { result -> AsyncStream<Int, Int, NSError> in

                firstResult = result
                deinitTest1.description
                return testStreamWithValue(32, next: 16)
            }

            let expectation = expectationWithDescription("")

            let dispose = stream.observe { event -> () in

                switch event {
                case .Success:
                    deinitTest2.description
                    XCTFail()
                case .Next(let next):
                    if next == 16 {
                        nexts.append(next)
                        expectation.fulfill()
                        return
                    }
                    nexts.append(next)
                case .Failure:
                    XCTFail()
                }
            }

            XCTAssertNotNil(weakDeinitTest1)
            XCTAssertNotNil(weakDeinitTest2)

            waitForExpectationsWithTimeout(0.5, handler: nil)
            dispose.dispose()
        }

        XCTAssertNil(weakDeinitTest1)
        XCTAssertNil(weakDeinitTest2)

        let expectedNexts = [0,1,2,3,4,16]
        XCTAssertEqual(expectedNexts, nexts)
        XCTAssertEqual(firstResult, "ok")

        XCTAssertEqual(numberOfObservers1, 1)
        XCTAssertEqual(numberOfObservers2, 1)
    }
}
