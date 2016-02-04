//
//  AsyncToStreamTests.swift
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

private func testAsync() -> AsyncTypes<String, NSError>.Async {

    return { (
        progressCallback: AsyncProgressCallback?,
        stateCallback   : AsyncChangeStateCallback?,
        finishCallback  : AsyncTypes<String, NSError>.DidFinishAsyncCallback?) -> AsyncHandler in

        var progress = 0

        var progressCallbackHolder = progressCallback
        var finishCallbackHolder   = finishCallback

        let cancel = Timer.sharedByThreadTimer().addBlock({ (cancel) -> Void in

            if progress == 5 {
                cancel()
                if let finishCallback = finishCallbackHolder {
                    progressCallbackHolder = nil
                    finishCallbackHolder   = nil
                    finishCallback(result: .Success("ok"))
                }
            }

            progressCallbackHolder?(progressInfo: progress)
            progress += 1
        }, duration: 0.01)

        return { (task: AsyncHandlerTask) -> Void in

            switch task {
            case .Cancel:
                cancel()
                if let finishCallback = finishCallbackHolder {
                    progressCallbackHolder = nil
                    finishCallbackHolder   = nil
                    finishCallback(result: .Interrupted)
                }
            case .UnSubscribe:
                cancel()
                if let finishCallback = finishCallbackHolder {
                    progressCallbackHolder = nil
                    finishCallbackHolder   = nil
                    finishCallback(result: .Unsubscribed)
                }
            case .Resume:
                fatalError()
            case .Suspend:
                fatalError()
            }
        }
    }
}

class AsyncToStreamTests: XCTestCase {

    func testDisposeStream() {

        let loader = testAsync()
        let stream = asyncToStream(loader)

        var deinitTest: NSObject? = NSObject()
        weak var weakDeinitTest = deinitTest

        let dispose = stream.observe { result -> Void in

            if deinitTest != nil {
                XCTFail()
            } else {
                XCTFail()
            }
        }

        dispose.dispose()

        XCTAssertNotNil(weakDeinitTest)
        deinitTest = nil

        XCTAssertNil(weakDeinitTest)
    }

    func testNormalFinishStream() {

        let loader = testAsync()
        let stream = asyncToStream(loader)

        var progressCalledCount = 0
        var resultValue: String?

        var deinitTest: NSObject? = NSObject()
        weak var weakDeinitTest = deinitTest

        let expectation = expectationWithDescription("")

        stream.observe { ev -> Void in

            switch ev {
            case .Success(let value):
                if deinitTest != nil {
                    deinitTest = nil
                    resultValue = value
                    expectation.fulfill()
                }
            case .Failure:
                XCTFail()
            case .Progress(let progress):
                XCTAssertEqual(progressCalledCount, progress as? Int)
                progressCalledCount += 1
            }
        }

        XCTAssertNotNil(weakDeinitTest)

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertNil(weakDeinitTest)

        XCTAssertEqual(5, progressCalledCount)
        XCTAssertEqual("ok", resultValue)
    }
}
