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

//TODO test
public func combineLatest<S: SequenceType, T, N, E where S.Generator.Element == AsyncStream<T, N, E>, E: ErrorType>(producers: S) -> AsyncStream<[T], N, E> {

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

            let dispose = stream.observe { event in
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
