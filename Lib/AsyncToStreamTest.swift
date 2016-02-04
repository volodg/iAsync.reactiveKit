//
//  AsyncToStreamTest.swift
//  AppDaddy
//
//  Created by Gorbenko Vladimir on 03/02/16.
//  Copyright © 2016 Volodymyr. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import ReactiveKit

//func asyncToStream<Value, Error: ErrorType>(loader: AsyncTypes<Value, Error>.Async) -> Stream<AsyncEvent<Value, AnyObject, Error>>

private func testAsync() -> AsyncTypes<String, NSError>.Async {

    return { (
        progressCallback: AsyncProgressCallback?,
        stateCallback   : AsyncChangeStateCallback?,
        finishCallback  : AsyncTypes<String, NSError>.DidFinishAsyncCallback?) -> AsyncHandler in

        var progress = 0

        let cancel = Timer.sharedByThreadTimer().addBlock({ (cancel) -> Void in

            if progress == 5 {
                cancel()
                finishCallback?(result: .Success("ok"))
            }

            progressCallback?(progressInfo: progress)
            progress += 1
        }, duration: 0.1)

        return { (task: AsyncHandlerTask) -> Void in

            switch task {
            case .Cancel:
                cancel()
                finishCallback?(result: .Interrupted)
            case .UnSubscribe:
                cancel()
                finishCallback?(result: .Unsubscribed)
            case .Resume:
                fatalError()
            case .Suspend:
                fatalError()
            }
        }
    }
}

private func testCancelStream() {

    let loader = testAsync()
    let stream = asyncToStream(loader)

    let dispose = stream.observe { result -> Void in

        switch result {
        case .Success:
            fatalError()
        case .Failure:
            fatalError()
//        case .Interrupted:
//            print("ok1")
//        case .Unsubscribed:
//            fatalError()
        case .Progress:
            fatalError()
        }
    }

    dispose.dispose()
    //stream.o
}

private func _testAll() {

    testCancelStream()
//    testUnsubscribeStream()
//    testNormalFinishStream()
    print("----------------------------------------------")
}

