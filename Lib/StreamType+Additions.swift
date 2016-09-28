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

    public func pausable<S: _StreamType where S.Event.Element == Bool>(by: S, delayAfterPause: Double, on queue: Queue) -> RawStream<Event> {

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

    public func pausable2<R: _StreamType where R.Event.Element == Bool>(by: R) -> RawStream<Event> {

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

    public func flatMap<U: StreamType>(transform: Element -> U) -> Stream<U.Element> {
        return flatMap(.Latest, transform: transform)
    }

    public func pausable<S: StreamType where S.Event.Element == Bool>(by: S, delayAfterPause: Double, on queue: Queue) -> Stream<Element> {
        return lift { $0.pausable(by, delayAfterPause: delayAfterPause, on: queue) }
    }

    public func pausable2<S: _StreamType where S.Event.Element == Bool>(by other: S) -> Stream<Element> {
        return lift { $0.pausable2(other) }
    }
}
