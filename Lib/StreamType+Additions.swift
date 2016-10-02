//
//  StreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 09/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

extension RawStreamType {

    public func throttleIf(_ seconds: Double, predicate: (Event.Element) -> Bool, on queue: Queue) -> RawStream<Event> {

        return RawStream { observer in

            var timerInFlight: Bool = false
            var latestEvent: Event.Element! = nil
            var latestEventDate: NSDate! = nil

            var tryDispatch: (() -> Void)?
            tryDispatch = {
                if latestEventDate.dateByAddingTimeInterval(seconds).compare(NSDate()) == NSComparisonResult.OrderedAscending {
                    observer.next(latestEvent)
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
            compositeDisposable.addDisposable(self.observe { event in

                if let element = event.element {

                    if !predicate(element) {

                        latestEvent     = nil
                        latestEventDate = nil
                        timerInFlight   = false

                        observer.next(element)
                        return
                    }

                    latestEvent = element
                    latestEventDate = NSDate()

                    guard timerInFlight == false else { return }
                    tryDispatch?()
                } else {

                    observer.on(event)
                }
            })
            return compositeDisposable
        }
    }

    public func pausable<S: _StreamType>(_ by: S, delayAfterPause: Double, on queue: Queue) -> RawStream<Event> where S.Event.Element == Bool {

        return RawStream { observer in

            var allowed: Bool = false

            var skipedEvent: Event?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable.addDisposable(by.observeNext { value in
                allowed = value
                if allowed {
                    queue.after(delayAfterPause, block: {

                        guard let skipedEvent_ = skipedEvent else { return }
                        skipedEvent = nil

                        if allowed {
                            observer.on(skipedEvent_)
                        }
                    })
                }
            })

            compositeDisposable.addDisposable(self.observe { event in
                if allowed {
                    skipedEvent = nil
                    observer.on(event)
                } else {
                    skipedEvent = event
                }
            })

            return compositeDisposable
        }
    }

    public func pausable2<R: _StreamType>(_ by: R) -> RawStream<Event> where R.Event.Element == Bool {

        return RawStream { observer in

            var allowed: Bool = true

            var skipedEvent: Event?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable += by.observe { value in
                if let element = value.element {
                    allowed = element

                    if allowed, let skipedEvent_ = skipedEvent {
                        skipedEvent = nil
                        observer.observer(skipedEvent_)
                    }
                } else {
                    // ignore?
                }
            }

            compositeDisposable += self.observe { event in
                if event.isTermination {
                    skipedEvent = nil
                    observer.observer(event)
                } else if allowed {
                    skipedEvent = nil
                    observer.observer(event)
                } else {
                    skipedEvent = event
                }
            }

            return compositeDisposable
        }
    }
}

public extension StreamType {

    public func flatMap<U: StreamType>(_ transform: (Element) -> U) -> Stream {
        return flatMap(.Latest, transform: transform)
    }

    public func throttleIf(_ seconds: Double, predicate: (Element) -> Bool, on queue: Queue) -> Stream {
        return lift { $0.throttleIf(seconds, predicate: predicate, on: queue) }
    }

    public func pausable<S: StreamType>(_ by: S, delayAfterPause: Double, on queue: Queue) -> Stream where S.Event.Element == Bool {
        return lift { $0.pausable(by, delayAfterPause: delayAfterPause, on: queue) }
    }

    public func pausable2<S: _StreamType>(by other: S) -> Stream where S.Event.Element == Bool {
        return lift { $0.pausable2(other) }
    }
}
