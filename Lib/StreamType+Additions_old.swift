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

    public func flatMap<S : StreamType_old>(transform: Self.Event -> S) -> Stream_old<S.Event> {
        return flatMap(.Latest, transform: transform)
    }

    public func pausable_old<S: StreamType_old where S.Event == Bool>(by: S, delayAfterPause: Double, on queue: Queue) -> Stream_old<Event> {
        return create_old { observer in

            var allowed: Bool = false

            var skipedEvent: Event?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable.addDisposable(by.observe(on: nil) { value in
                allowed = value
                if allowed {
                    queue.after(delayAfterPause, block: {

                        guard let skipedEvent_ = skipedEvent else { return }
                        skipedEvent = nil

                        if allowed {
                            observer(skipedEvent_)
                        }
                    })
                }
            })

            compositeDisposable.addDisposable(self.observe(on: nil) { event in
                if allowed {
                    skipedEvent = nil
                    observer(event)
                } else {
                    skipedEvent = event
                }
            })

            return compositeDisposable
        }
    }

    public func pausable2_old<S: StreamType_old where S.Event == Bool>(by: S) -> Stream_old<Event> {
        return create_old { observer in

            var allowed: Bool = false

            var skipedEvent: Event?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable.addDisposable(by.observe(on: nil) { value in
                allowed = value
                if allowed, let skipedEvent_ = skipedEvent {
                    skipedEvent = nil
                    observer(skipedEvent_)
                }
            })

            compositeDisposable.addDisposable(self.observe(on: nil) { event in
                if allowed {
                    observer(event)
                } else {
                    skipedEvent = event
                }
            })

            return compositeDisposable
        }
    }

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
