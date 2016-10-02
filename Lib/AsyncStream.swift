//
//  AsyncStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit

public protocol AsyncStreamType {
    associatedtype ValueT
    associatedtype NextT
    associatedtype ErrorT: Error

    typealias Event = AsyncEvent<ValueT, NextT, ErrorT>
    typealias ObserverT = (AsyncEvent<ValueT, NextT, ErrorT>) -> ()

    func observe(_ observer: @escaping ObserverT) -> Disposable

    func lift<R, P, E: Error>(_ transform: @escaping (Signal1<Event>) -> Signal1<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E>
}

public struct AsyncStream<ValueT_, NextT_, ErrorT_: Error>: AsyncStreamType {

    public typealias ValueT = ValueT_
    public typealias NextT  = NextT_
    public typealias ErrorT = ErrorT_

    public typealias Event = AsyncEvent<ValueT, NextT, ErrorT>

    fileprivate let stream: Signal1<AsyncEvent<ValueT, NextT, ErrorT>>

    public typealias ObserverT = (AsyncEvent<ValueT, NextT, ErrorT>) -> ()

    public init(producer: @escaping (@escaping ObserverT) -> Disposable) {

        stream = Signal1 { observer in
            var observerHolder: Observer? = observer

            let dispose = producer { event in
                if let observer = observerHolder {
                    if event.isTerminal {
                        observerHolder = nil
                    }
                    observer.observer(.next(event))
                }
            }

            return BlockDisposable { _ in
                //observerHolder = nil
                dispose.dispose()
            }
        }
    }

    public func observe(_ observer: @escaping ObserverT) -> Disposable {

        return stream.observeNext(with: { event in
            observer(event)
        })
    }

    public func after(_ delay: TimeInterval) -> AsyncStream<ValueT, NextT, ErrorT> {

        let delayStream = AsyncStream<Void, NextT, ErrorT>.succeededAfter(delay: delay, with: ())
        return delayStream.flatMap { self }
    }

    public static func succeeded(with value: ValueT) -> AsyncStream<ValueT, NextT, ErrorT> {
        return AsyncStream { observer in
            observer(.success(value))
            return NonDisposable.instance
        }
    }

    public static func value(with value: Result<ValueT, ErrorT>) -> AsyncStream<ValueT, NextT, ErrorT> {
        return AsyncStream { observer in
            switch value {
            case .success(let value):
                observer(.success(value))
            case .failure(let error):
                observer(.failure(error))
            }
            return NonDisposable.instance
        }
    }

    public static func succeededAfter(delay: TimeInterval, with value: ValueT) -> AsyncStream<ValueT, NextT, ErrorT> {
        return AsyncStream { observer in

            let cancel = Timer.sharedByThreadTimer().addBlock({ cancel in
                cancel()
                observer(.success(value))
            }, duration: delay)

            return BlockDisposable(cancel)
        }
    }

    public static func failed(with error: ErrorT) -> AsyncStream<ValueT, NextT, ErrorT> {
        return AsyncStream { observer in
            observer(.failure(error))
            return NonDisposable.instance
        }
    }

    public func lift<R, P, E : Error>(_ transform: @escaping (Signal1<Event>) -> Signal<AsyncEvent<R, P, E>, NoError>) -> AsyncStream<R, P, E> {
        return AsyncStream<R, P, E> { observer in
            return transform(self.stream).observeNext(with: { event in
                observer(event)
            })
        }
    }
}

public extension AsyncStreamType {

    public func on(next: ((NextT) -> ())? = nil, success: ((ValueT) -> ())? = nil, failure: ((ErrorT) -> ())? = nil, start: (() -> Void)? = nil, completed: (() -> Void)? = nil) -> AsyncStream<ValueT, NextT, ErrorT> {
        return AsyncStream { observer in
            start?()
            return self.observe { event in
                switch event {
                case .next(let value):
                    next?(value)
                case .failure(let error):
                    failure?(error)
                    completed?()
                case .success(let value):
                    success?(value)
                    completed?()
                }

                observer(event)
            }
        }
    }

    public func observeNext(_ observer: @escaping (NextT) -> ()) -> Disposable {
        return self.observe { event in
            switch event {
            case .next(let event):
                observer(event)
            default: break
            }
        }
    }

    public func observeError(_ observer: @escaping (ErrorT) -> ()) -> Disposable {
        return self.observe { event in
            switch event {
            case .failure(let error):
                observer(error)
            default:
                break
            }
        }
    }

    public func map<U>(_ transform: @escaping (ValueT) -> U) -> AsyncStream<U, NextT, ErrorT> {
        return lift { $0.map { $0.map(transform) } }
    }

    public func mapValue<U>(_ transform: @escaping (ValueT) -> U) -> AsyncStream<U, NextT, ErrorT> {
        return lift { $0.map { $0.map(transform) } }
    }

    public func tryMap<U>(_ transform: @escaping (ValueT) -> Result<U, ErrorT>) -> AsyncStream<U, NextT, ErrorT> {
        return lift { $0.map { operationEvent in
            switch operationEvent {
            case .success(let value):
                switch transform(value) {
                case let .success(value):
                    return .success(value)
                case let .failure(error):
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            case .next(let event):
                return .next(event)
            }
            }
        }
    }

    //tryMapError
    public func tryMapError<F>(_ transform: @escaping (ErrorT) -> Result<ValueT, F>) -> AsyncStream<ValueT, NextT, F> {
        return lift { $0.map { operationEvent in
            switch operationEvent {
            case .success(let value):
                return .success(value)
            case .failure(let error):
                switch transform(error) {
                case let .success(value):
                    return .success(value)
                case let .failure(error):
                    return .failure(error)
                }
            case .next(let event):
                return .next(event)
            }
            }
        }
    }

    public func mapNext<F>(_ transform: @escaping (NextT) -> F) -> AsyncStream<ValueT, F, ErrorT> {
        return AsyncStream { observer in
            return self.observe { event -> () in
                switch event {
                case .next(let next):
                    observer(.next(transform(next)))
                case .failure(let error):
                    observer(.failure(error))
                case .success(let value):
                    observer(.success(value))
                }
            }
        }
    }

    public func mapError<F>(_ transform: @escaping (ErrorT) -> F) -> AsyncStream<ValueT, NextT, F> {
        return lift { $0.map { $0.mapError(transform) } }
    }

    //TODO test
    public func retry(_ count: Int?, delay: TimeInterval? = nil, until: @escaping (Result<ValueT, ErrorT>) -> Bool) -> AsyncStream<ValueT, NextT, ErrorT> {

        var count_ = count

        return AsyncStream { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)

            var attempt: (() -> Void)?

            let observer = { (event: AsyncEvent<ValueT, NextT, ErrorT>) in

                let rertyOrFinish = { (result: Result<ValueT, ErrorT>) in
                    let count = count_ ?? 1
                    if !until(result) && count > 0 {
                        if let count = count_ {
                            count_ = count - 1
                        }
                        attempt?()
                    } else {
                        attempt = nil
                        observer(event)
                    }
                }

                switch event {
                case .failure(let error):
                    rertyOrFinish(.failure(error))
                case .success(let value):
                    rertyOrFinish(.success(value))
                case .next:
                    observer(event)
                }
            }

            attempt = {
                let delayStream: AsyncStream<Void, NextT, ErrorT>
                if let delay = delay {
                    delayStream = AsyncStream<Void, NextT, ErrorT>.succeededAfter(delay: delay, with: ())
                } else {
                    delayStream = AsyncStream<Void, NextT, ErrorT>.succeeded(with: ())
                }

                serialDisposable.otherDisposable?.dispose()
                serialDisposable.otherDisposable = nil
                let dispose = delayStream.flatMap { self }.observe(observer)
                if serialDisposable.otherDisposable == nil {
                    serialDisposable.otherDisposable = dispose
                }
            }

            let dispose = self.observe(observer)
            if serialDisposable.otherDisposable == nil {
                serialDisposable.otherDisposable = dispose
            }

            return BlockDisposable {
                serialDisposable.dispose()
                attempt = nil
            }
        }
    }

    public func retry(_ count: Int) -> AsyncStream<ValueT, NextT, ErrorT> {

        return retry(count, until: { result -> Bool in
            switch result {
            case .failure:
                return false
            default:
                return true
            }
        })
    }

    //TODO test
    public func combineLatestWith<S: AsyncStreamType>(_ other: S) -> AsyncStream<(ValueT, S.ValueT), (NextT?, S.NextT?), ErrorT> where S.ErrorT == ErrorT {
        return AsyncStream { observer in

            var latestSelfEvent : AsyncEvent<ValueT, NextT, ErrorT>? = nil
            var latestOtherEvent: AsyncEvent<S.ValueT, S.NextT, S.ErrorT>? = nil

            let dispatchNextIfPossible = { () -> () in

                var latestSelfNext : NextT? = nil
                var latestOtherNext: S.NextT? = nil

                if case .some(.next(let selfNext)) = latestSelfEvent {
                    latestSelfNext = selfNext
                }
                if case .some(.next(let otherNext)) = latestOtherEvent {
                    latestOtherNext = otherNext
                }

                if latestSelfNext != nil || latestOtherNext != nil {
                    let next = (latestSelfNext, latestOtherNext)
                    observer(.next(next))
                }
            }

            let onBoth = { () -> () in
                guard latestSelfEvent != nil || latestOtherEvent != nil else { return }
                switch (latestSelfEvent, latestOtherEvent) {
                case (.some(.success(let selfValue)), .some(.success(let otherValue))):
                    observer(.success(selfValue, otherValue))
                default:
                    dispatchNextIfPossible()
                }
            }

            let selfDisposable = self.observe { event in
                if case .failure(let error) = event {
                    observer(.failure(error))
                } else {
                    latestSelfEvent = event
                    onBoth()
                }
            }

            let otherDisposable = other.observe { event in
                if case .failure(let error) = event {
                    observer(.failure(error))
                } else {
                    latestOtherEvent = event
                    onBoth()
                }
            }

            return CompositeDisposable([selfDisposable, otherDisposable])
        }
    }

    public func zipWith<S: AsyncStreamType>(_ other: S) -> AsyncStream<(ValueT, S.ValueT), (NextT, S.NextT), ErrorT> where S.ErrorT == ErrorT {
        return AsyncStream { observer in
            let queue = DispatchQueue(label: "com.ReactiveKit.ReactiveKit.ZipWith")

            var selfNextBuffer = Array<NextT>()
            var selfValue: ValueT?

            var otherNextBuffer = Array<S.NextT>()
            var otherValue: S.ValueT?

            let dispatchNextIfPossible = {
                while selfNextBuffer.count > 0 && otherNextBuffer.count > 0 {
                    let next = (selfNextBuffer[0], otherNextBuffer[0])
                    selfNextBuffer.remove(at: 0)
                    otherNextBuffer.remove(at: 0)
                    observer(.next(next))
                }
            }

            let dispatchValueIfPossible = {
                if let selfValue = selfValue, let otherValue = otherValue {
                    observer(.success(selfValue, otherValue))
                }
            }

            let selfDisposable = self.observe { event in
                switch event {
                case .failure(let error):
                    observer(.failure(error))
                case .success(let value):
                    queue.sync {
                        selfValue = value
                        dispatchValueIfPossible()
                    }
                case .next(let value):
                    queue.sync {
                        selfNextBuffer.append(value)
                        dispatchNextIfPossible()
                    }
                }
            }

            let otherDisposable = other.observe { event in
                switch event {
                case .failure(let error):
                    observer(.failure(error))
                case .success(let value):
                    queue.sync {
                        otherValue = value
                        dispatchValueIfPossible()
                    }
                case .next(let value):
                    queue.sync {
                        otherNextBuffer.append(value)
                        dispatchNextIfPossible()
                    }
                }
            }

            return CompositeDisposable([selfDisposable, otherDisposable])
        }
    }
}

public extension AsyncStreamType where ValueT: AsyncStreamType, ValueT.NextT == NextT, ValueT.ErrorT == ErrorT {

    public func merge() -> AsyncStream<ValueT.ValueT, ValueT.NextT, ValueT.ErrorT> {

        fatalError()
    }

    public func switchToLatest() -> AsyncStream<ValueT.ValueT, ValueT.NextT, ValueT.ErrorT> {

        return AsyncStream { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            let compositeDisposable = CompositeDisposable([serialDisposable])

            compositeDisposable.add(disposable: self.observe { taskEvent in

                switch taskEvent {
                case .failure(let error):
                    observer(.failure(error))
                case .success(let value):
                    serialDisposable.otherDisposable?.dispose()
                    serialDisposable.otherDisposable = value.observe { value in
                        observer(value)
                    }
                case .next(let next):
                    observer(.next(next))
                }
            })

            return compositeDisposable
        }
    }

    public func concat() -> AsyncStream<ValueT.ValueT, ValueT.NextT, ValueT.ErrorT> {

        fatalError()
    }
}

public enum AsyncStreamFlatMapStrategy {
    case latest
    case merge
    case concat
}

public extension AsyncStreamType {

    public func flatMap<T: AsyncStreamType>(_ strategy: AsyncStreamFlatMapStrategy, transform: @escaping (ValueT) -> T) -> AsyncStream<T.ValueT, T.NextT, T.ErrorT> where T.NextT == NextT, T.ErrorT == ErrorT {
        switch strategy {
        case .latest:
            return map(transform).switchToLatest()
        case .merge:
            return map(transform).merge()
        case .concat:
            return map(transform).concat()
        }
    }

    public func flatMap<T: AsyncStreamType>(_ transform: @escaping (ValueT) -> T) -> AsyncStream<T.ValueT, T.NextT, T.ErrorT> where T.NextT == NextT, T.ErrorT == ErrorT {
        return flatMap(.latest, transform: transform)
    }

    public func flatMapError<T: AsyncStreamType>(_ recover: @escaping (ErrorT) -> T) -> AsyncStream<T.ValueT, T.NextT, T.ErrorT> where T.ValueT == ValueT, T.NextT == NextT {
        return AsyncStream { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)

            serialDisposable.otherDisposable = self.observe { taskEvent in
                switch taskEvent {
                case .next(let value):
                    observer(.next(value))
                case .success(let value):
                    observer(.success(value))
                case .failure(let error):
                    serialDisposable.otherDisposable = recover(error).observe { event in
                        observer(event)
                    }
                }
            }

            return serialDisposable
        }
    }
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType>(_ a: A, _ b: B) -> AsyncStream<(A.ValueT, B.ValueT), (A.NextT?, B.NextT?), A.ErrorT> where A.ErrorT == B.ErrorT {
    return a.combineLatestWith(b)
}

public func zip<A: AsyncStreamType, B: AsyncStreamType>(_ a: A, _ b: B) -> AsyncStream<(A.ValueT, B.ValueT), (A.NextT, B.NextT), A.ErrorT> where A.ErrorT == B.ErrorT {
    return a.zipWith(b)
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType>(_ a: A, _ b: B, _ c: C) -> AsyncStream<(A.ValueT, B.ValueT, C.ValueT), (A.NextT?, B.NextT?, C.NextT?), A.ErrorT> where A.ErrorT == B.ErrorT, A.ErrorT == C.ErrorT {
    return combineLatest(a, b).combineLatestWith(c).mapNext { ($0?.0, $0?.1, $1) }.map { ($0.0, $0.1, $1) }
}

public func zip<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType>(_ a: A, _ b: B, _ c: C) -> AsyncStream<(A.ValueT, B.ValueT, C.ValueT), (A.NextT?, B.NextT?, C.NextT?), A.ErrorT> where A.ErrorT == B.ErrorT, A.ErrorT == C.ErrorT {
    return zip(a, b).zipWith(c).mapNext { ($0.0, $0.1, $1) }.map { ($0.0, $0.1, $1) }
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType, D: AsyncStreamType>(_ a: A, _ b: B, _ c: C, _ d: D) -> AsyncStream<(A.ValueT, B.ValueT, C.ValueT, D.ValueT), (A.NextT?, B.NextT?, C.NextT?, D.NextT?), A.ErrorT> where A.ErrorT == B.ErrorT, A.ErrorT == C.ErrorT, A.ErrorT == D.ErrorT {
    return combineLatest(a, b, c).combineLatestWith(d).mapNext { ($0?.0, $0?.1, $0?.2, $1) }.map { ($0.0, $0.1, $0.2, $1) }
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType, D: AsyncStreamType, E: AsyncStreamType>
    (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> AsyncStream<(A.ValueT, B.ValueT, C.ValueT, D.ValueT, E.ValueT), (A.NextT?, B.NextT?, C.NextT?, D.NextT?, E.NextT?), A.ErrorT> where A.ErrorT == B.ErrorT, A.ErrorT == C.ErrorT, A.ErrorT == D.ErrorT, A.ErrorT == E.ErrorT
{
    return combineLatest(a, b, c, d).combineLatestWith(e).mapNext { ($0?.0, $0?.1, $0?.2, $0?.3, $1) }.map { ($0.0, $0.1, $0.2, $0.3, $1) }
}
