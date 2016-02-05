//
//  TestCommons.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils
import iAsync_reactiveKit

import ReactiveKit

var numberOfObservers = 0

typealias Event = AsyncEvent<String, Int, NSError>

func testStream() -> AsyncStream<String, Int, NSError> {

    let stream = AsyncStream(producer: { (observer: Event -> ()) -> DisposableType? in

        numberOfObservers += 1

        var next = 0

        let cancel = Timer.sharedByThreadTimer().addBlock({ (cancel) -> Void in

            if next == 5 {
                cancel()
                observer(.Success("ok"))
                observer(.Success("ok2"))

                observer(.Next(next))
                next += 1
            }

            observer(.Next(next))
            next += 1
        }, duration: 0.01)

        return BlockDisposable({ () -> () in
            cancel()
        })
    })

    return stream
}

func testStreamWithValue<Value, Next>(value: Value, next: Next) -> AsyncStream<Value, Next, NSError> {

    let stream = AsyncStream(producer: { (observer: AsyncEvent<Value, Next, NSError> -> ()) -> DisposableType? in

        var nextCount = 0

        let cancel = Timer.sharedByThreadTimer().addBlock({ (cancel) -> Void in

            if nextCount == 2 {
                cancel()
                observer(.Success(value))
            } else {
                observer(.Next(next))
                nextCount += 1
            }
        }, duration: 0.01)

        return BlockDisposable({ () -> () in
            cancel()
        })
    })

    return stream
}
