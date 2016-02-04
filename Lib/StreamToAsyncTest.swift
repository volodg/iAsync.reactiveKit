//
//  StreamToAsyncTest.swift
//  AppDaddy
//
//  Created by Gorbenko Vladimir on 03/02/16.
//  Copyright © 2016 Volodymyr. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import ReactiveKit

//streamToAsync<
//Value, Error: ErrorType, Input: StreamType where Input.Event == AsyncEvent<Value, AnyObject, Error>>(input: Input)
//-> AsyncTypes<Value, Error>.Async

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
        }, duration: 0.1)

        return BlockDisposable({ () -> () in
            cancel()
        })
    })

    return stream
}

private func testNormalFinishStream() {

    let stream = testStream()
    let loader = streamToAsync(stream)

    let _ = loader(progressCallback: { (progressInfo) -> () in

        print("progressInfo: \(progressInfo)")
    }, stateCallback: { (state) -> () in

        fatalError()
    }) { (result) -> Void in

        switch result {
        case .Success(let value):
            print("finish with: \(value)")
        case .Failure:
            fatalError()
        case .Interrupted:
            fatalError()
        case .Unsubscribed:
            fatalError()
        }
    }
}

func testAll() {

//    testUnsubscribeStream()
//    testNormalFinishStream()
    print("----------------------------------------------")
}
