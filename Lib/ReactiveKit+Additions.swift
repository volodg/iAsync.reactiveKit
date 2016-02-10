//
//  ReactiveKit+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 10/02/16.
//  Copyright (c) 2016 AppDaddy. All rights reserved.
//

import Foundation

import ReactiveKit

@warn_unused_result(message="Did you forget to call `start` on the producer?")
public func combineLatest<S: SequenceType, T where S.Generator.Element == Stream<T>>(producers: S) -> Stream<[T]> {

    let size = Array(producers).count

    if size == 0 {
        return Stream<[T]>(value: [])
    }

    return create { observer in

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

                observer(varEvent)
            }
        }

        var disposes = [DisposableType]()

        for (index, stream) in producers.enumerate() {

            let dispose = stream.observe(on: nil) { event in
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

extension Stream {

    public init(value: Event) {

        self.init { handler -> DisposableType? in

            handler(value)
            return nil
        }
    }
}

public extension StreamType where Event: OptionalType, Event.Wrapped: Equatable {

    @warn_unused_result
    public func distinctOptional2() -> Stream<Event.Wrapped?> {
        return create { observer in
            var lastEvent: Event.Wrapped? = nil
            var firstEvent: Bool = true
            return self.observe(on: nil) { event in

                switch (lastEvent, event._unbox) {
                case (.None, .Some(let new)):
                    firstEvent = false
                    observer(new)
                case (.Some, .None):
                    firstEvent = false
                    observer(nil)
                case (.None, .None) where firstEvent:
                    firstEvent = false
                    observer(nil)
                case (.Some(let old), .Some(let new)) where old != new:
                    firstEvent = false
                    observer(new)
                default:
                    break
                }

                lastEvent = event._unbox
            }
        }
    }
}
