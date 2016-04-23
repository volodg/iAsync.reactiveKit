//
//  StreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 09/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

extension StreamType {

    @warn_unused_result
    public func flatMap<S : StreamType>(transform: Self.Event -> S) -> Stream<S.Event> {
        return flatMap(.Latest, transform: transform)
    }

    @warn_unused_result
    public func pausable<S: StreamType where S.Event == Bool>(by: S, delayAfterPause: Double, on queue: Queue) -> Stream<Event> {
        return create { observer in

            var allowed: Bool = false

            var skipedEvent: Event?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable += by.observe(on: nil) { value in
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
            }

            compositeDisposable += self.observe(on: nil) { event in
                if allowed {
                    skipedEvent = nil
                    observer(event)
                } else {
                    skipedEvent = event
                }
            }

            return compositeDisposable
        }
    }

    @warn_unused_result
    public func pausable2<S: StreamType where S.Event == Bool>(by: S) -> Stream<Event> {
        return create { observer in

            var allowed: Bool = false

            var skipedEvent: Event?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable += by.observe(on: nil) { value in
                allowed = value
                if allowed, let skipedEvent_ = skipedEvent {
                    skipedEvent = nil
                    observer(skipedEvent_)
                }
            }

            compositeDisposable += self.observe(on: nil) { event in
                if allowed {
                    observer(event)
                } else {
                    skipedEvent = event
                }
            }

            return compositeDisposable
        }
    }
}
