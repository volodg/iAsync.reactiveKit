//
//  MergedAsyncStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 06/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit

final public class MergedAsyncStream<KeyT: Hashable, ValueT, NextT, ErrorT: Error> {

    fileprivate let sharedNextLimit: Int

    public init(sharedNextLimit: Int = Int.max) {
        self.sharedNextLimit = sharedNextLimit
    }

    public typealias StreamT = AsyncStream<ValueT, NextT, ErrorT>

    fileprivate var streamsByKey  = [KeyT:AsyncStream<ValueT, NextT, ErrorT>]()
    fileprivate var disposesByKey = [KeyT:[SerialDisposable]]()

    public func mergedStream<
        T: AsyncStreamType>(
        _ factory: @escaping () -> T,
        key    : KeyT,
        getter : (() -> StreamT.Event?)? = nil,
        setter : ((StreamT.Event) -> Void)? = nil
        ) -> StreamT where T.ValueT == ValueT, T.NextT == NextT, T.ErrorT == ErrorT {

        let result: StreamT = StreamT { observer -> Disposable in

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
                    self.streamsByKey.removeValue(forKey: key)
                    self.disposesByKey.removeValue(forKey: key)
                }).mergedObservers(self.sharedNextLimit)
                self.streamsByKey[key] = resultStream
            }

            let dispose = SerialDisposable(otherDisposable: resultStream.observe(observer))

            //TODO test - when immediately finished
            if self.streamsByKey[key] == nil {
                return NonDisposable.instance
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
                    for (index, dispose_) in disposes_.enumerated() {
                        guard dispose_ === dispose else { continue }
                        disposes_.remove(at: index)
                        self.disposesByKey[key] = disposes_
                        if disposes_.isEmpty {
                            self.disposesByKey.removeValue(forKey: key)
                            self.streamsByKey.removeValue(forKey: key)
                        }
                        break
                    }
                }

                dispose.dispose()
            }
        }

        if let getter = getter {
            return result.withEventValueGetter(getter)
        }

        return result
    }
}
