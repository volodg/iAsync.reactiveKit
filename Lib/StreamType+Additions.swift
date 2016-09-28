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

    @warn_unused_result
    public func pausable2<R: _StreamType where R.Event.Element == Bool>(by: R) -> RawStream<Event> {

        let result = RawStream<Event> { observer in

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

        return result
    }
}

public extension StreamType {

    public func flatMap<U: StreamType>(transform: Element -> U) -> Stream<U.Element> {
        return flatMap(.Latest, transform: transform)
    }

    @warn_unused_result
    public func pausable2<S: _StreamType where S.Event.Element == Bool>(by other: S) -> Stream<Element> {
        return lift { $0.pausable2(other) }
    }
}
