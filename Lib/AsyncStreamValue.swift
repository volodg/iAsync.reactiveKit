//
//  AsyncStreamValue.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 10/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit

public struct AsyncValue<Value, Error: ErrorType> {

    public var result: Result<Value, Error>? = nil
    public var loading: Bool = false

    public init() {}

    public init(result: Result<Value, Error>?, loading: Bool) {
        self.result  = result
        self.loading = loading
    }

    public func mapStream<R>(f: Value -> Stream<R>) -> Stream<AsyncValue<R, Error>> {

        switch result {
        case .Some(.Success(let v)):
            return f(v).map { (val: R) -> AsyncValue<R, Error> in
                return AsyncValue<R, Error>(result: .Success(val), loading: self.loading)
            }
        case .Some(.Failure(let error)):
            let value = AsyncValue<R, Error>(result: .Failure(error), loading: self.loading)
            return Stream(value: value)
        case .None:
            let value = AsyncValue<R, Error>(result: .None, loading: self.loading)
            return Stream(value: value)
        }
    }

    public func mapStream2<R>(f: Value -> Stream<AsyncValue<R, Error>>) -> Stream<AsyncValue<R, Error>> {

        switch result {
        case .Some(.Success(let v)):
            return f(v)
        case .Some(.Failure(let error)):
            let value = AsyncValue<R, Error>(result: .Failure(error), loading: self.loading)
            return Stream(value: value)
        case .None:
            let value = AsyncValue<R, Error>(result: .None, loading: self.loading)
            return Stream(value: value)
        }
    }
}

public extension AsyncStreamType {

    func bindedToObservableAsyncVal<B : BindableType where
        B.Event == AsyncValue<Value, Error>, B: ObservableType, B.Value == AsyncValue<Value, Error>>
        (bindable: B) -> AsyncStream<Value, Next, Error> {

        return create(producer: { observer -> DisposableType? in

            var result = bindable.value
            result.loading = true

            let bindObserver = bindable.observer(nil)
            bindObserver(result)

            return self.observe(on: nil, observer: { event -> () in

                switch event {
                case .Success(let value):
                    result.result  = .Success(value)
                    result.loading = false
                    bindObserver(result)
                case .Failure(let error):
                    if bindable.value.result?.value == nil {
                        result.result  = .Failure(error)
                    }
                    result.loading = false
                    bindObserver(result)
                default:
                    break
                }

                observer(event)
            })
        })
    }
}

extension MergedAsyncStream {

    public func mergedStream<T: AsyncStreamType,
        B : BindableType where T.Value == Value, T.Next == Next, T.Error == Error,
        B.Event == AsyncValue<Value, Error>,
        B: ObservableType, B.Value == AsyncValue<Value, Error>>(
        factory : () -> T,
        key     : Key,
        bindable: B,
        lazy    : Bool = true
        ) -> StreamT {

        let bindedFactory = { () -> AsyncStream<Value, Next, Error> in
            let stream = factory()
            return stream.bindedToObservableAsyncVal(bindable)
        }

        return mergedStream(bindedFactory, key: key, getter: { () -> AsyncEvent<Value, Next, Error>? in
            guard let result = bindable.value.result else { return nil }
            switch result {
            case .Success(let value) where lazy:
                return .Success(value)
            default:
                return nil
            }
        })
    }
}
