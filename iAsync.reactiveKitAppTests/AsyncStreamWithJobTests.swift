//
//  AsyncStreamWithJobTests.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 06/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import XCTest

import iAsync_reactiveKit

import ReactiveKit

private var numberOfJobs = 0

private func testJobStream() -> AsyncStream<String, Int, NSError> {

    return asyncStreamWithJob(job: { (next: (Int) -> Void) -> Result<String, NSError> in

        numberOfJobs += 1

        for i in 0..<5 {
            next(i)
            usleep(1)
        }

        return .success("ok")
    })
}

class AsyncStreamWithJobTests: XCTestCase {

    override func setUp() {

        numberOfJobs = 0
    }

    func testDisposeStream() {

        let stream = testJobStream()

        weak var weakDeinitTest: NSObject? = nil

        autoreleasepool {

            let deinitTest = NSObject()
            weakDeinitTest = deinitTest

            let dispose = stream.observe { result in

                _ = deinitTest.description
                XCTFail()
            }

            dispose.dispose()

            XCTAssertNotNil(weakDeinitTest)
        }

        XCTAssertNil(weakDeinitTest)

        XCTAssertTrue(numberOfJobs <= 1)
    }
    
    func testNormalFinishStream() {

        let stream = testJobStream()

        let testFunc = { (numberOfCalls: Int) in

            var progressCalledCount = 0
            var resultValue: String?

            weak var weakDeinitTest: NSObject? = nil

            autoreleasepool {

                let deinitTest = NSObject()
                weakDeinitTest = deinitTest

                let expectation = self.expectation(description: "")

                _ = stream.observe { ev in

                    switch ev {
                    case .success(let value):
                        XCTAssertTrue(Thread.isMainThread)
                        _ = deinitTest.description
                        resultValue = value
                        expectation.fulfill()
                    case .failure:
                        XCTFail()
                    case .next(let next):
                        XCTAssertTrue(Thread.isMainThread)
                        XCTAssertEqual(progressCalledCount, next)
                        progressCalledCount += 1
                    }
                }

                XCTAssertNotNil(weakDeinitTest)

                self.waitForExpectations(timeout: 0.5, handler: nil)
            }

            XCTAssertNil(weakDeinitTest)

            XCTAssertEqual(5, progressCalledCount)
            XCTAssertEqual("ok", resultValue)

            XCTAssertEqual(numberOfCalls, numberOfJobs)
        }

        testFunc(1)
        testFunc(2)
    }

    func testNumberOfStream() {

        let stream = testJobStream()

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
                    XCTAssertTrue(Thread.isMainThread)
                    resultValue1 = value
                    expectation1.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertTrue(Thread.isMainThread)
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
                    XCTAssertTrue(Thread.isMainThread)
                    resultValue2 = value
                    expectation2.fulfill()
                case .failure:
                    XCTFail()
                case .next(let next):
                    XCTAssertTrue(Thread.isMainThread)
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

        XCTAssertEqual(2, numberOfJobs)
    }
}
