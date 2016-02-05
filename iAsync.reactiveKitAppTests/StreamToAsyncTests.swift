//
//  StreamToAsyncTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 04/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

import iAsync_async
import iAsync_utils
import iAsync_reactiveKit

import ReactiveKit

var numberOfObservers = 0

typealias Event = AsyncEvent<String, AnyObject, NSError>

private func testStream() -> AsyncStream<String, AnyObject, NSError> {

    let stream = AsyncStream(producer: { (observer: Event -> ()) -> DisposableType? in

        numberOfObservers += 1

        var progress = 0

        let cancel = Timer.sharedByThreadTimer().addBlock({ (cancel) -> Void in

            if progress == 5 {
                cancel()
                observer(.Success("ok"))
                observer(.Success("ok2"))

                observer(.Progress(progress))
                progress += 1
            }

            observer(.Progress(progress))
            progress += 1
        }, duration: 0.01)

        return BlockDisposable({ () -> () in
            cancel()
        })
    })

    return stream
}

class StreamToAsyncTests: XCTestCase {

    override func setUp() {

        numberOfObservers = 0
    }

    func testCancelAsync() {

        let stream = testStream()
        let loader = stream.streamToAsync()

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
        let loader = stream.streamToAsync()

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
        let loader = stream.streamToAsync()

        var progressCalledCount = 0
        var resultValue: String?

        var deinitTest: NSObject? = NSObject()
        weak var weakDeinitTest = deinitTest

        let expectation = expectationWithDescription("")

        let _ = loader(progressCallback: { (progress) -> () in

            XCTAssertEqual(progressCalledCount, progress as? Int)
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
        let loader = stream.streamToAsync()

        var progressCalledCount1 = 0
        var resultValue1: String?

        var deinitTest1: NSObject? = NSObject()
        weak var weakDeinitTest1 = deinitTest1

        let expectation1 = expectationWithDescription("")

        let _ = loader(progressCallback: { (progress) -> () in

            XCTAssertEqual(progressCalledCount1, progress as? Int)
            progressCalledCount1 += 1
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

        var progressCalledCount2 = 0
        var resultValue2: String?

        var deinitTest2: NSObject? = NSObject()
        weak var weakDeinitTest2 = deinitTest2

        let expectation2 = expectationWithDescription("")

        let _ = loader(progressCallback: { (progress) -> () in

            XCTAssertEqual(progressCalledCount2, progress as? Int)
            progressCalledCount2 += 1
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

        XCTAssertEqual(5, progressCalledCount1)
        XCTAssertEqual(5, progressCalledCount2)
        XCTAssertEqual("ok", resultValue1)
        XCTAssertEqual("ok", resultValue2)

        XCTAssertEqual(2, numberOfObservers)
    }
}
