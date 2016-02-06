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

    private var streamsByKey = [Key:AsyncStream<Value, Next, Error>]()

    public func mergedStream<T: AsyncStreamType where T.Value == Value, T.Next == Next, T.Error == Error>
        (factory: () -> T, key: Key) -> AsyncStream<Value, Next, Error> {

        return create(producer: { observer -> DisposableType? in

            let resultStream: AsyncStream<Value, Next, Error>

            if let stream = self.streamsByKey[key] {
                resultStream = stream
            } else {
                resultStream = factory().on(completed: { () -> Void in
                    self.streamsByKey.removeValueForKey(key)
                }).mergedObservers()
                self.streamsByKey[key] = resultStream
            }

            return resultStream.observe(observer: observer)
        })
    }
}
