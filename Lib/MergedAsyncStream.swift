//
//  MergedAsyncStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 06/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import protocol ReactiveKit.Disposable
import class ReactiveKit.SerialDisposable
import class ReactiveKit.BlockDisposable
import ReactiveKit_old//???

final public class MergedAsyncStream<Key: Hashable, Value, Next, Error: ErrorType> {

    private let sharedNextLimit: Int

    public init(sharedNextLimit: Int = Int.max) {
        self.sharedNextLimit = sharedNextLimit
    }

    public typealias StreamT = AsyncStream<Value, Next, Error>

    private var streamsByKey  = [Key:AsyncStream<Value, Next, Error>]()
    private var disposesByKey = [Key:[SerialDisposable]]()

    public func mergedStream<
        T: AsyncStreamType where T.Value == Value, T.Next == Next, T.Error == Error>(
        factory: () -> T,
        key    : Key,
        getter : (() -> StreamT.Event?)? = nil,
        setter : (StreamT.Event -> Void)? = nil
        ) -> StreamT {

        let result: StreamT = create(producer: { observer -> Disposable? in

            let resultStream: StreamT

            if let stream = self.streamsByKey[key] {
                resultStream = stream
            } else {
                let stream: StreamT
                if let setter = setter {
                    stream = factory().withEventValueSetter(setter)
                } else {
                    stream = factory().map(id_)
                }

                resultStream = stream.on(completed: { _ in
                    self.streamsByKey.removeValueForKey(key)
                    self.disposesByKey.removeValueForKey(key)
                }).mergedObservers(self.sharedNextLimit)
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

            return BlockDisposable { _ in

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

        if let getter = getter {
            return result.withEventValueGetter(getter)
        }

        return result
    }
}
