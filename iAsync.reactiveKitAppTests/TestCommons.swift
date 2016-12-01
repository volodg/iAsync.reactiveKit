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

var numberOfObservers1 = 0
var numberOfObservers2 = 0

typealias Event = AsyncEvent<String, Int, NSError>

func testStream() -> AsyncStream<String, Int, NSError> {

    let stream: AsyncStream<String, Int, NSError> = AsyncStream { observer in

        numberOfObservers1 += 1

        var next = 0

        let cancel = Timer.sharedByThreadTimer().add(actionBlock: { cancel in

            if next == 5 {
                cancel()
                observer(.success("ok"))
                observer(.success("ok2"))

                observer(.next(next))
                next += 1
            }

            observer(.next(next))
            next += 1
        }, delay: .milliseconds(10))

        return BlockDisposable(cancel)
    }

    return stream
}

func testStreamWithValue<Value, Next>(_ value: Value, next: Next) -> AsyncStream<Value, Next, NSError> {

    let stream: AsyncStream<Value, Next, NSError> = AsyncStream { observer in

        numberOfObservers2 += 1
        var nextCount = 0

        let cancel = Timer.sharedByThreadTimer().add(actionBlock: { cancel in

            if nextCount == 2 {
                cancel()
                observer(.success(value))
            } else {
                observer(.next(next))
                nextCount += 1
            }
        }, delay: .milliseconds(10))

        return BlockDisposable({ () -> () in
            cancel()
        })
    }

    return stream
}
