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

typealias Event = AsyncEvent<String, AnyObject, NSError>

func testStream() -> AsyncStream<String, AnyObject, NSError> {

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
