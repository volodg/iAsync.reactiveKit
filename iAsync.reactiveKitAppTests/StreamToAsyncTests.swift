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

import ReactiveKit

//@testable
import iAsync_reactiveKit

typealias Event = AsyncEvent<String, AnyObject, NSError>

private func testStream() -> Stream<AsyncEvent<String, AnyObject, NSError>> {

    let stream = Stream(producer: { (observer: Event -> ()) -> DisposableType? in

        var progress = 0

        let cancel = Timer.sharedByThreadTimer().addBlock({ (cancel) -> Void in

            if progress == 5 {
                cancel()
                observer(.Success("ok"))
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
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCancelStream() {

        let stream = testStream()
        let loader = streamToAsync(stream)

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

        autoreleasepool { () -> () in
            handler(task: .Cancel)
        }

        if weakDeinitTest != nil {
            XCTFail()
        }

        XCTAssertTrue(testPassed)
    }

    func testUnsubscribeStream() {

        let stream = testStream()
        let loader = streamToAsync(stream)

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

        autoreleasepool { () -> () in
            handler(task: .UnSubscribe)
        }

        if weakDeinitTest != nil {
            XCTFail()
        }

        XCTAssertTrue(testPassed)
    }

    func testNormalFinishStream() {

        let stream = testStream()
        let loader = streamToAsync(stream)

        var progressCalledCount = 0
        var resultValue: String?

        let expectation = expectationWithDescription("")

        let _ = loader(progressCallback: { (progressInfo) -> () in

            progressCalledCount += 1
        }, stateCallback: { (state) -> () in

            XCTFail()
        }) { (result) -> Void in

            switch result {
            case .Success(let value):
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

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertEqual(5, progressCalledCount)
        XCTAssertEqual("ok", resultValue)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
