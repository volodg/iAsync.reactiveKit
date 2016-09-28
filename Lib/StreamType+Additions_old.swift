//
//  StreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 09/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import struct ReactiveKit.Queue
import class ReactiveKit.CompositeDisposable
import class ReactiveKit.BlockDisposable
import ReactiveKit_old//???

extension StreamType_old {

    public func throttleIf(seconds: Double, predicate: (Event) -> Bool, on queue: Queue) -> Stream_old<Event> {
        return create_old { observer in

            var timerInFlight: Bool = false
            var latestEvent: Event! = nil
            var latestEventDate: NSDate! = nil

            var tryDispatch: (() -> Void)?
            tryDispatch = {
                if latestEventDate.dateByAddingTimeInterval(seconds).compare(NSDate()) == NSComparisonResult.OrderedAscending {
                    observer(latestEvent)
                } else {
                    timerInFlight = true
                    queue.after(seconds) {
                        if timerInFlight {
                            timerInFlight = false
                            tryDispatch?()
                        }
                    }
                }
            }

            let blockDisposable = BlockDisposable { tryDispatch = nil }
            let compositeDisposable = CompositeDisposable([blockDisposable])
            compositeDisposable.addDisposable(self.observe(on: nil) { event in

                if !predicate(event) {

                    latestEvent     = nil
                    latestEventDate = nil
                    timerInFlight   = false

                    observer(event)
                    return
                }

                latestEvent = event
                latestEventDate = NSDate()

                guard timerInFlight == false else { return }
                tryDispatch?()
            })
            return compositeDisposable
        }
    }
}
