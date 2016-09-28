//
//  ReactiveKit+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 10/02/16.
//  Copyright © 2016 AppDaddy. All rights reserved.
//

import Foundation

import struct ReactiveKit.Queue
import protocol ReactiveKit.OptionalType
import protocol ReactiveKit.Disposable
import class ReactiveKit.CompositeDisposable
import ReactiveKit_old//???

public func combineLatest_old<S: SequenceType, T where S.Generator.Element == Stream_old<T>>(producers: S) -> Stream_old<[T]> {

    let size = Array(producers).count

    if size == 0 {
        return Stream_old<[T]>(value: [])
    }

    return create_old { observer in

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

        var disposes = [Disposable]()

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

//TODO test
public func combineLatest_old<S: SequenceType, T, N, E where S.Generator.Element == AsyncStream<T, N, E>, E: ErrorType>(producers: S) -> AsyncStream<[T], N, E> {

    let size = Array(producers).count

    if size == 0 {
        return AsyncStream.succeeded(with: [])
    }

    return create { observer in

        let queue = Queue(name: "com.ReactiveKit.ReactiveKit.combineLatest")

        var results = [Int:AsyncEvent<T, N, E>]()

        let dispatchIfPossible = { (currIndex: Int, currEv: AsyncEvent<T, N, E>) -> () in

            if let index = results.indexOf({ $0.1.isFailure }) {

                let el = results[index]
                observer(.Failure(el.1.error!))
            }

            if results.count == size && results.all({ $0.1.isSuccess }) {

                let els = results.map { $0.1.value! }
                observer(.Success(els))
            }

            if case .Next(let val) = currEv {
                observer(.Next(val))
            }
        }

        var disposes = [Disposable]()

        for (index, stream) in producers.enumerate() {

            let dispose = stream.observe(on: nil) { event in
                queue.sync {
                    results[index] = event
                    dispatchIfPossible(index, event)
                }
            }

            disposes.append(dispose)
        }

        return CompositeDisposable(disposes)
    }
}

extension Stream_old {

    public init(value: Event) {

        self.init { handler -> Disposable? in

            handler(value)
            return nil
        }
    }
}
