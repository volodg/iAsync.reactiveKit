//
//  ReactiveKit+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 10/02/16.
//  Copyright © 2016 AppDaddy. All rights reserved.
//

import Foundation

import ReactiveKit

public func combineLatest<S: SequenceType, T where S.Generator.Element == Stream<T>>(producers: S) -> Stream<[T]> {

    let size = Array(producers).count

    if size == 0 {
        return Stream<[T]>.just([])
    }

    return Stream { observer in

        let queue = Queue(name: "com.ReactiveKit.ReactiveKit.combineLatest")

        var results = [Int:T]()

        var varEvent: [T]! = nil

        let dispatchIfPossible = { (currIndex: Int) -> () in

            if results.count == size {

                if varEvent == nil {
                    varEvent = [T]()

                    for i in 0..<size {
                        varEvent.append(results[i]!)
                    }
                } else {

                    varEvent[currIndex] = results[currIndex]!
                }

                observer.next(varEvent)
            }
        }

        var disposes = [Disposable]()

        for (index, stream) in producers.enumerate() {

            let dispose = stream.observeNext { event in
                queue.sync {
                    results[index] = event
                    dispatchIfPossible(index)
                }
            }

            disposes.append(dispose)
        }

        return CompositeDisposable(disposes)
    }
}

public extension RawStreamType where Event.Element: OptionalType, Event.Element.Wrapped: Equatable {

    public func distinctOptional2() -> Stream<Event.Element.Wrapped?> {

        return Stream { observer in
            var lastEvent: Event.Element.Wrapped? = nil
            var firstEvent: Bool = true
            return self.observe { event in

                if event.isTermination {

                    observer.completed()
                    return
                }

                if let value = event.element {

                    switch (lastEvent, value._unbox) {
                    case (.None, .Some(let new)):
                        firstEvent = false
                        observer.next(new)
                    case (.Some, .None):
                        firstEvent = false
                        observer.next(nil)
                    case (.None, .None) where firstEvent:
                        firstEvent = false
                        observer.next(nil)
                    case (.Some(let old), .Some(let new)) where old != new:
                        firstEvent = false
                        observer.next(new)
                    default:
                        break
                    }

                    lastEvent = value._unbox
                }
            }
        }
    }
}

public extension StreamType where Element: OptionalType, Element.Wrapped: Equatable {

    public func distinctOptional2() -> Stream<Element.Wrapped?> {
        return rawStream.distinctOptional2()
    }
}
