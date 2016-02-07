//
//  MergedAsyncStream.swift
//  iAsync_reactiveKit
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

            //TODO test - when immediately finished
            if self.streamsByKey[key] == nil {
                return nil
            }

            var disposes: [SerialDisposable]
            if let disposes_ = self.disposesByKey[key] {
                disposes = disposes_ + [dispose]
            } else {
                disposes = [dispose]
            }
            self.disposesByKey[key] = disposes

            return BlockDisposable { () -> Void in

                if var disposes_ = self.disposesByKey[key] {
                    for (index, dispose_) in disposes_.enumerate() {
                        guard dispose_ === dispose else { continue }
                        disposes_.removeAtIndex(index)
                        self.disposesByKey[key] = disposes_
                        if disposes_.isEmpty {
                            self.disposesByKey.removeValueForKey(key)
                            self.streamsByKey.removeValueForKey(key)
                        }
                        break
                    }
                }

                dispose.dispose()
            }
        })
    }
}
