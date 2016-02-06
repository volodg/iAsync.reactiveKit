//
//  MergedAsyncStream.swift
//  iAsync.reactiveKit
//
//  Created by Gorbenko Vladimir on 06/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

final public class MergedAsyncStream<Key: Hashable, Value, Next, Error: ErrorType> {

    public init() {}

    private var streamsByKey  = [Key:AsyncStream<Value, Next, Error>]()
    private var disposesByKey = [Key:[SerialDisposable]]()

    public func mergedStream<T: AsyncStreamType where T.Value == Value, T.Next == Next, T.Error == Error>
        (factory: () -> T, key: Key) -> AsyncStream<Value, Next, Error> {

        return create(producer: { observer -> DisposableType? in

            let resultStream: AsyncStream<Value, Next, Error>

            if let stream = self.streamsByKey[key] {
                resultStream = stream
            } else {
                resultStream = factory().on(completed: { () -> Void in
                    self.streamsByKey.removeValueForKey(key)
                    self.disposesByKey.removeValueForKey(key)
                }).mergedObservers()
                self.streamsByKey[key] = resultStream
            }

            let dispose = SerialDisposable(otherDisposable: resultStream.observe(observer: observer))

            var disposes: [SerialDisposable]
            if let disposes_ = self.disposesByKey[key] {
                disposes = disposes_ + [dispose]
            } else {
                disposes = [dispose]
            }
            self.disposesByKey[key] = disposes

            return BlockDisposable { () -> Void in

                self.streamsByKey.removeValueForKey(key)

                if var disposes_ = self.disposesByKey[key] {
                    for (index, dispose_) in disposes_.enumerate() {
                        if dispose_ === dispose {
                            disposes_.removeAtIndex(index)
                            if disposes_.isEmpty {
                                self.disposesByKey.removeValueForKey(key)
                            }
                            break
                        }
                    }
                }

                dispose.dispose()
            }
        })
    }
}
