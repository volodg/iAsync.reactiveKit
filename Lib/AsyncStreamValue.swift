//
//  AsyncStreamValue.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 10/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

public struct AsyncValue<Value, Error: ErrorType> {

    public var result: Result<Value, Error>? = nil
    public var loading: Bool = false
}

//BindableType
extension AsyncStreamType {

    public func bindToAsyncVal<B : BindableType where B.Event == AsyncEvent<Value, Next, Error>>(bindable: B, context: ExecutionContext?) -> DisposableType! {

        return nil
    }
}

public class AsyncStreamValue<Value, Error: ErrorType> {

    public private(set) var asyncValue = AsyncValue<Value, Error>()
    private let asyncValueStreamChanged = ActiveStream<Void>()

    public var asyncValueStream: Stream<AsyncValue<Value, Error>> {
        return asyncValueStreamChanged.map { [weak self] () -> AsyncValue<Value, Error> in
            return self?.asyncValue ?? AsyncValue<Value, Error>()
        }
    }

    init() {}

    private let merged = MergedAsyncStream<Int, Value, Void, Error>()

    public func valueAsyncStream(streamF: () -> AsyncStream<Value, Void, Error>, force: Bool) -> AsyncStream<Value, Void, Error> {

        let streamF2 = { () -> AsyncStream<Value, Void, Error> in

            let stream = streamF()
            return stream.on(start: { [weak self] () -> Void in
                self?.asyncValue.loading = true
                self?.asyncValueStreamChanged.next(())
            }, completed: { [weak self] () -> Void in
                self?.asyncValue.loading = false
                self?.asyncValueStreamChanged.next(())
            })
        }

        return merged.mergedStream(streamF2, key: 0, getter: { [weak self] () -> AsyncEvent<Value, Void, Error>? in
            guard let self_ = self, result = self_.asyncValue.result else { return nil }
            switch result {
            case .Success(let value) where !force:
                return .Success(value)
            default:
                return nil
            }
        }, setter: { [weak self] event -> Void in
            guard let self_ = self else { return }
            switch event {
            case .Success(let value):
                self_.asyncValue.result = .Success(value)
            case .Failure(let error):
                if self_.asyncValue.result == nil || force {
                    self_.asyncValue.result = .Failure(error)
                }
            case .Next:
                break
            }
        })
    }
}
