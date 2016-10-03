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

public struct AsyncValue<ValueT, ErrorT: Error> {

    public var result: Result<ValueT, ErrorT>? = nil
    public var loading: Bool = false

    public init() {}

    public init(result: Result<ValueT, ErrorT>?, loading: Bool) {
        self.result  = result
        self.loading = loading
    }

    public func mapStream<R>(_ f: (ValueT) -> Signal1<R>) -> Signal1<AsyncValue<R, ErrorT>> {

        switch result {
        case .some(.success(let v)):
            return f(v).map { (val: R) -> AsyncValue<R, ErrorT> in
                let result = AsyncValue<R, ErrorT>(result: .success(val), loading: self.loading)
                return result
            }
        case .some(.failure(let error)):
            let value = AsyncValue<R, ErrorT>(result: .failure(error), loading: self.loading)
            return Signal.next(value)
        case .none:
            let value = AsyncValue<R, ErrorT>(result: .none, loading: self.loading)
            return Signal.next(value)
        }
    }

    public func mapStream2<R>(_ f: (ValueT) -> Signal1<AsyncValue<R, ErrorT>>) -> Signal1<AsyncValue<R, ErrorT>> {

        switch result {
        case .some(.success(let v)):
            return f(v)
        case .some(.failure(let error)):
            let value = AsyncValue<R, ErrorT>(result: .failure(error), loading: self.loading)
            return Signal1.next(value)
        case .none:
            let value = AsyncValue<R, ErrorT>(result: .none, loading: self.loading)
            return Signal1.next(value)
        }
    }
}

public extension AsyncStreamType {

    func bindedToObservableAsyncVal<B : BindableProtocol>
        (_ bindable: B) -> AsyncStream<ValueT, NextT, ErrorT> where
        B.Element == AsyncValue<ValueT, ErrorT>, B.Error == NoError, B: PropertyProtocol, B.ProperyElement == AsyncValue<ValueT, ErrorT> {

        return AsyncStream { observer -> Disposable in

            var result = bindable.value
            result.loading = true

            let bindedSignal = Property(result)

            let disposes = CompositeDisposable()

            let dispose1 = bindable.bind(signal: bindedSignal.toSignal())
            disposes.add(disposable: dispose1)

            let dispose2 = self.observe { event -> () in

                switch event {
                case .success(let value):
                    result.result  = .success(value)
                    result.loading = false
                    bindedSignal.value = result
                case .failure(let error):
                    if bindable.value.result?.value == nil {
                        result.result = .failure(error)
                    }
                    result.loading = false
                    bindedSignal.value = result
                default:
                    break
                }

                observer(event)
            }
            disposes.add(disposable: dispose2)

            return disposes
        }
    }
}

extension MergedAsyncStream {

    public func mergedStream<
        T: AsyncStreamType,
        B: BindableProtocol>(
        _ factory : @escaping () -> T,
        key     : KeyT,//TODO remove key parameter
        bindable: B,
        lazy    : Bool = true
        ) -> StreamT where T.ValueT == ValueT, T.NextT == NextT, T.ErrorT == ErrorT,
        B.Element == AsyncValue<ValueT, ErrorT>,
        B: PropertyProtocol, B.Error == NoError, B.ProperyElement == AsyncValue<ValueT, ErrorT> {

        let bindedFactory = { () -> AsyncStream<ValueT, NextT, ErrorT> in
            let stream = factory()
            return stream.bindedToObservableAsyncVal(bindable)
        }

        return mergedStream(bindedFactory, key: key, getter: { () -> AsyncEvent<ValueT, NextT, ErrorT>? in
            guard let result = bindable.value.result else { return nil }
            switch result {
            case .success(let value) where lazy:
                return .success(value)
            default:
                return nil
            }
        })
    }

     public func mergedStream<
        T: AsyncStreamType,
        B: BindableProtocol>(
        _ factory: @escaping () -> T,
        key    : KeyT,
        holder : inout B,
        lazy   : Bool = true
        ) -> StreamT where T.ValueT == ValueT, T.NextT == NextT, T.ErrorT == ErrorT,
        B: NSObjectProtocol,
        B: PropertyProtocol, B.Error == NoError, B.ProperyElement == [KeyT:AsyncValue<ValueT, ErrorT>] {

        let bindedFactory = { [weak holder] () -> AsyncStream<ValueT, NextT, ErrorT> in

            let stream = factory()

            let bindable = BindableWithBlock<ValueT, ErrorT>(putVal: { val in

                holder?.value[key] = val
            }, getVal: { () -> AsyncValue<ValueT, ErrorT> in

                if let result = holder?.value[key] {
                    return result
                }
                let result = AsyncValue<ValueT, ErrorT>()
                holder?.value[key] = result
                return result
            })

            return stream.bindedToObservableAsyncVal(bindable)
        }

        return mergedStream(bindedFactory, key: key, getter: { [weak holder] () -> AsyncEvent<ValueT, NextT, ErrorT>? in
            guard let result = holder?.value[key]?.result else { return nil }
            switch result {
            case .success(let value) where lazy:
                return .success(value)
            default:
                return nil
            }
        })
    }
}

private struct BindableWithBlock<ValueT, ErrorT: Error> : PropertyProtocol, BindableProtocol {

    typealias Event   = AsyncValue<ValueT, ErrorT>
    typealias Element = AsyncValue<ValueT, ErrorT>
    typealias Error   = NoError
    typealias ProperyElement = AsyncValue<ValueT, ErrorT>

    fileprivate let stream = PublishSubject<Element, NoError>()

    public var value: AsyncValue<ValueT, ErrorT> {
        get {
            return getVal()
        }
        set {
            putVal(newValue)
            stream.next(newValue)
        }
    }

    fileprivate let getVal: () -> Event
    fileprivate let putVal: (Event) -> ()

    init(putVal: @escaping (Event) -> (), getVal: @escaping () -> Event) {
        self.putVal = putVal
        self.getVal = getVal
    }

    func bind(_ signal: Signal<Element, NoError>) -> Disposable {

        return signal.observe { event in

            switch event {
            case .next(let val):
                self.putVal(val)
            default:
                fatalError()
            }
            self.stream.on(event)
        }
    }
}
