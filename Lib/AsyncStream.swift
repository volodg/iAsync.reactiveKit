//
//  AsyncStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import enum ReactiveKit.Result
import struct ReactiveKit.Queue
import protocol ReactiveKit.Disposable
import ReactiveKit_old//???

public protocol AsyncStreamType: StreamType_old {
    associatedtype Value
    associatedtype Next
    associatedtype Error: ErrorType

    func lift<R, P, E: ErrorType>(transform: Stream_old<AsyncEvent<Value, Next, Error>> -> Stream_old<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E>
}

public struct AsyncObserver<Value, Next, Error: ErrorType> {

    public let observer: AsyncEvent<Value, Next, Error> -> ()

    public func next(event: Next) {
        observer(.Next(event))
    }

    public func success(value: Value) {
        observer(.Success(value))
    }

    public func failure(error: Error) {
        observer(.Failure(error))
    }
}

public struct AsyncStream<Value, Next, Error: ErrorType>: AsyncStreamType {

    public typealias Event = AsyncEvent<Value, Next, Error>

    private let stream: Stream_old<Event>

    public typealias Observer = Event -> ()

    public init(producer: Observer -> Disposable?) {
        stream = Stream_old  { observer in
            var observerHolder: Observer? = observer

            let dispose = producer { event in
                if let observer = observerHolder {
                    if event.isTerminal {
                        observerHolder = nil
                    }
                    observer(event)
                }
            }

            return BlockDisposable { _ in
                //observerHolder = nil
                dispose?.dispose()
            }
        }
    }

    public func observe(on context: ExecutionContext_old? = ImmediateOnMainExecutionContext, observer: Observer) -> Disposable {
        return stream.observe(on: context, observer: observer)
    }

    public func after(delay: NSTimeInterval) -> AsyncStream<Value, Next, Error> {

        let delayStream = AsyncStream<Void, Next, Error>.succeededAfter(delay: delay, with: ())
        return delayStream.flatMap { self }
    }

    public static func succeeded(with value: Value) -> AsyncStream<Value, Next, Error> {
        return create { observer in
            observer(.Success(value))
            return nil
        }
    }

    public static func value(with value: Result<Value, Error>) -> AsyncStream<Value, Next, Error> {
        return create { observer in
            switch value {
            case .Success(let value):
                observer(.Success(value))
            case .Failure(let error):
                observer(.Failure(error))
            }
            return nil
        }
    }

    public static func succeededAfter(delay delay: NSTimeInterval, with value: Value) -> AsyncStream<Value, Next, Error> {
        return create { observer in

            let cancel = Timer.sharedByThreadTimer().addBlock({ cancel in
                cancel()
                observer(.Success(value))
            }, duration: delay)

            return BlockDisposable(cancel)
        }
    }

    public static func failed(with error: Error) -> AsyncStream<Value, Next, Error> {
        return create { observer in
            observer(.Failure(error))
            return nil
        }
    }

    public func lift<R, P, E: ErrorType>(transform: Stream_old<AsyncEvent<Value, Next, Error>> -> Stream_old<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E> {
        return create { observer in
            return transform(self.stream).observe(on: nil, observer: observer)
        }
    }
}

public func create<Value, Next, Error: ErrorType>(producer producer: (AsyncEvent<Value, Next, Error> -> ()) -> Disposable?) -> AsyncStream<Value, Next, Error> {
    return AsyncStream<Value, Next, Error> { observer in
        return producer(observer)
    }
}

public extension AsyncStreamType {

    public func on(next next: (Next -> ())? = nil, success: (Value -> ())? = nil, failure: (Error -> ())? = nil, start: (() -> Void)? = nil, completed: (() -> Void)? = nil, context: ExecutionContext_old? = ImmediateOnMainExecutionContext) -> AsyncStream<Value, Next, Error> {
        return create { observer in
            start?()
            return self.observe(on: context) { event in
                switch event {
                case .Next(let value):
                    next?(value)
                case .Failure(let error):
                    failure?(error)
                    completed?()
                case .Success(let value):
                    success?(value)
                    completed?()
                }

                observer(event)
            }
        }
    }

    public func observeNext(on context: ExecutionContext_old? = ImmediateOnMainExecutionContext, observer: Next -> ()) -> Disposable {
        return self.observe(on: context) { event in
            switch event {
            case .Next(let event):
                observer(event)
            default: break
            }
        }
    }

    public func observeError(on context: ExecutionContext_old? = ImmediateOnMainExecutionContext, observer: Error -> ()) -> Disposable {
        return self.observe(on: context) { event in
            switch event {
            case .Failure(let error):
                observer(error)
            default: break
            }
        }
    }

    public func shareNext(limit: Int = Int.max, context: ExecutionContext_old? = nil) -> ObservableBuffer<Next> {
        return ObservableBuffer(limit: limit) { observer in
            return self.observeNext(on: context, observer: observer)
        }
    }

    public func map<U>(transform: Value -> U) -> AsyncStream<U, Next, Error> {
        return lift { $0.map { $0.map(transform) } }
    }

    public func mapValue<U>(transform: Value -> U) -> AsyncStream<U, Next, Error> {
        return lift { $0.map { $0.map(transform) } }
    }

    public func tryMap<U>(transform: Value -> Result<U, Error>) -> AsyncStream<U, Next, Error> {
        return lift { $0.map { operationEvent in
            switch operationEvent {
            case .Success(let value):
                switch transform(value) {
                case let .Success(value):
                    return .Success(value)
                case let .Failure(error):
                    return .Failure(error)
                }
            case .Failure(let error):
                return .Failure(error)
            case .Next(let event):
                return .Next(event)
            }
            }
        }
    }

    //tryMapError
    public func tryMapError<F>(transform: Error -> Result<Value, F>) -> AsyncStream<Value, Next, F> {
        return lift { $0.map { operationEvent in
            switch operationEvent {
            case .Success(let value):
                return .Success(value)
            case .Failure(let error):
                switch transform(error) {
                case let .Success(value):
                    return .Success(value)
                case let .Failure(error):
                    return .Failure(error)
                }
            case .Next(let event):
                return .Next(event)
            }
            }
        }
    }

    public func mapNext<F>(transform: Next -> F) -> AsyncStream<Value, F, Error> {
        return create { observer in
            return self.observe(on: nil, observer: { event -> () in
                switch event {
                case .Next(let next):
                    observer(.Next(transform(next)))
                case .Failure(let error):
                    observer(.Failure(error))
                case .Success(let value):
                    observer(.Success(value))
                }
            })
        }
    }

    public func mapError<F>(transform: Error -> F) -> AsyncStream<Value, Next, F> {
        return lift { $0.map { $0.mapError(transform) } }
    }

    public func filter(include: Value -> Bool) -> AsyncStream<Value, Next, Error> {
        return lift { $0.filter { $0.filter(include) } }
    }

    public func switchTo(context: ExecutionContext_old) -> AsyncStream<Value, Next, Error> {
        return lift { $0.switchTo(context) }
    }

    public func throttle(seconds: Double, on queue: Queue) -> AsyncStream<Value, Next, Error> {
        return lift { $0.throttle(seconds, on: queue) }
    }

    //TODO test
    public func retry(count: Int?, delay: NSTimeInterval? = nil, until: Result<Value, Error> -> Bool) -> AsyncStream<Value, Next, Error> {

        var count_ = count

        return create { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)

            var attempt: (() -> Void)?

            let observer = { (event: AsyncEvent<Value, Next, Error>) in

                let rertyOrFinish = { (result: Result<Value, Error>) in
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
                case .Failure(let error):
                    rertyOrFinish(.Failure(error))
                case .Success(let value):
                    rertyOrFinish(.Success(value))
                case .Next:
                    observer(event)
                }
            }

            attempt = {
                let delayStream: AsyncStream<Void, Next, Error>
                if let delay = delay {
                    delayStream = AsyncStream<Void, Next, Error>.succeededAfter(delay: delay, with: ())
                } else {
                    delayStream = AsyncStream<Void, Next, Error>.succeeded(with: ())
                }

                serialDisposable.otherDisposable?.dispose()
                serialDisposable.otherDisposable = nil
                let dispose = delayStream.flatMap { self }.observe(on: nil, observer: observer)
                if serialDisposable.otherDisposable == nil {
                    serialDisposable.otherDisposable = dispose
                }
            }

            let dispose = self.observe(on: nil, observer: observer)
            if serialDisposable.otherDisposable == nil {
                serialDisposable.otherDisposable = dispose
            }

            return BlockDisposable {
                serialDisposable.dispose()
                attempt = nil
            }
        }
    }

    public func retry(count: Int) -> AsyncStream<Value, Next, Error> {

        return retry(count, until: { result -> Bool in
            switch result {
            case .Failure:
                return false
            default:
                return true
            }
        })
    }

    //TODO test
    public func combineLatestWith<S: AsyncStreamType where S.Error == Error>(other: S) -> AsyncStream<(Value, S.Value), (Next?, S.Next?), Error> {
        return create { observer in

            var latestSelfEvent : AsyncEvent<Value, Next, Error>? = nil
            var latestOtherEvent: AsyncEvent<S.Value, S.Next, S.Error>? = nil

            let dispatchNextIfPossible = { () -> () in

                var latestSelfNext : Next? = nil
                var latestOtherNext: S.Next? = nil

                if case .Some(.Next(let selfNext)) = latestSelfEvent {
                    latestSelfNext = selfNext
                }
                if case .Some(.Next(let otherNext)) = latestOtherEvent {
                    latestOtherNext = otherNext
                }

                if latestSelfNext != nil || latestOtherNext != nil {
                    let next = (latestSelfNext, latestOtherNext)
                    observer(.Next(next))
                }
            }

            let onBoth = { () -> () in
                guard latestSelfEvent != nil || latestOtherEvent != nil else { return }
                switch (latestSelfEvent, latestOtherEvent) {
                case (.Some(.Success(let selfValue)), .Some(.Success(let otherValue))):
                    observer(.Success(selfValue, otherValue))
                default:
                    dispatchNextIfPossible()
                }
            }

            let selfDisposable = self.observe(on: nil) { event in
                if case .Failure(let error) = event {
                    observer(.Failure(error))
                } else {
                    latestSelfEvent = event
                    onBoth()
                }
            }

            let otherDisposable = other.observe(on: nil) { event in
                if case .Failure(let error) = event {
                    observer(.Failure(error))
                } else {
                    latestOtherEvent = event
                    onBoth()
                }
            }

            return CompositeDisposable([selfDisposable, otherDisposable])
        }
    }

    public func zipWith<S: AsyncStreamType where S.Error == Error>(other: S) -> AsyncStream<(Value, S.Value), (Next, S.Next), Error> {
        return create { observer in
            let queue = Queue(name: "com.ReactiveKit.ReactiveKit.ZipWith")

            var selfNextBuffer = Array<Next>()
            var selfValue: Value?

            var otherNextBuffer = Array<S.Next>()
            var otherValue: S.Value?

            let dispatchNextIfPossible = {
                while selfNextBuffer.count > 0 && otherNextBuffer.count > 0 {
                    let next = (selfNextBuffer[0], otherNextBuffer[0])
                    selfNextBuffer.removeAtIndex(0)
                    otherNextBuffer.removeAtIndex(0)
                    observer(.Next(next))
                }
            }

            let dispatchValueIfPossible = {
                if let selfValue = selfValue, let otherValue = otherValue {
                    observer(.Success(selfValue, otherValue))
                }
            }

            let selfDisposable = self.observe(on: nil) { event in
                switch event {
                case .Failure(let error):
                    observer(.Failure(error))
                case .Success(let value):
                    queue.sync {
                        selfValue = value
                        dispatchValueIfPossible()
                    }
                case .Next(let value):
                    queue.sync {
                        selfNextBuffer.append(value)
                        dispatchNextIfPossible()
                    }
                }
            }

            let otherDisposable = other.observe(on: nil) { event in
                switch event {
                case .Failure(let error):
                    observer(.Failure(error))
                case .Success(let value):
                    queue.sync {
                        otherValue = value
                        dispatchValueIfPossible()
                    }
                case .Next(let value):
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

public extension AsyncStreamType where Value: AsyncStreamType, Value.Next == Next, Value.Error == Error {

    public func merge() -> AsyncStream<Value.Value, Value.Next, Value.Error> {

        fatalError()
    }

    public func switchToLatest() -> AsyncStream<Value.Value, Value.Next, Value.Error> {

        return create { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            let compositeDisposable = CompositeDisposable([serialDisposable])

            compositeDisposable += self.observe(on: nil) { taskEvent in

                switch taskEvent {
                case .Failure(let error):
                    observer(.Failure(error))
                case .Success(let value):
                    serialDisposable.otherDisposable?.dispose()
                    serialDisposable.otherDisposable = value.observe(on: nil, observer: { (value) -> () in
                        observer(value)
                    })
                case .Next(let next):
                    observer(.Next(next))
                }
            }

            return compositeDisposable
        }
    }

    public func concat() -> AsyncStream<Value.Value, Value.Next, Value.Error> {

        fatalError()
    }
}

public enum AsyncStreamFlatMapStrategy {
    case Latest
    case Merge
    case Concat
}

public extension AsyncStreamType {

    public func flatMap<T: AsyncStreamType where T.Next == Next, T.Error == Error>(strategy: AsyncStreamFlatMapStrategy, transform: Value -> T) -> AsyncStream<T.Value, T.Next, T.Error> {
        switch strategy {
        case .Latest:
            return map(transform).switchToLatest()
        case .Merge:
            return map(transform).merge()
        case .Concat:
            return map(transform).concat()
        }
    }

    public func flatMap<T: AsyncStreamType where T.Next == Next, T.Error == Error>(transform: Value -> T) -> AsyncStream<T.Value, T.Next, T.Error> {
        return flatMap(.Latest, transform: transform)
    }

    public func flatMapError<T: AsyncStreamType where T.Value == Value, T.Next == Next>(recover: Error -> T) -> AsyncStream<T.Value, T.Next, T.Error> {
        return create { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)

            serialDisposable.otherDisposable = self.observe(on: nil) { taskEvent in
                switch taskEvent {
                case .Next(let value):
                    observer(.Next(value))
                case .Success(let value):
                    observer(.Success(value))
                case .Failure(let error):
                    serialDisposable.otherDisposable = recover(error).observe(on: nil) { event in
                        observer(event)
                    }
                }
            }

            return serialDisposable
        }
    }
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType where A.Error == B.Error>(a: A, _ b: B) -> AsyncStream<(A.Value, B.Value), (A.Next?, B.Next?), A.Error> {
    return a.combineLatestWith(b)
}

public func zip<A: AsyncStreamType, B: AsyncStreamType where A.Error == B.Error>(a: A, _ b: B) -> AsyncStream<(A.Value, B.Value), (A.Next, B.Next), A.Error> {
    return a.zipWith(b)
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType where A.Error == B.Error, A.Error == C.Error>(a: A, _ b: B, _ c: C) -> AsyncStream<(A.Value, B.Value, C.Value), (A.Next?, B.Next?, C.Next?), A.Error> {
    return combineLatest(a, b).combineLatestWith(c).mapNext { ($0?.0, $0?.1, $1) }.map { ($0.0, $0.1, $1) }
}

public func zip<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType where A.Error == B.Error, A.Error == C.Error>(a: A, _ b: B, _ c: C) -> AsyncStream<(A.Value, B.Value, C.Value), (A.Next?, B.Next?, C.Next?), A.Error> {
    return zip(a, b).zipWith(c).mapNext { ($0.0, $0.1, $1) }.map { ($0.0, $0.1, $1) }
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType, D: AsyncStreamType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error>(a: A, _ b: B, _ c: C, _ d: D) -> AsyncStream<(A.Value, B.Value, C.Value, D.Value), (A.Next?, B.Next?, C.Next?, D.Next?), A.Error> {
    return combineLatest(a, b, c).combineLatestWith(d).mapNext { ($0?.0, $0?.1, $0?.2, $1) }.map { ($0.0, $0.1, $0.2, $1) }
}

public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType, D: AsyncStreamType, E: AsyncStreamType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error>
    (a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> AsyncStream<(A.Value, B.Value, C.Value, D.Value, E.Value), (A.Next?, B.Next?, C.Next?, D.Next?, E.Next?), A.Error>
{
    return combineLatest(a, b, c, d).combineLatestWith(e).mapNext { ($0?.0, $0?.1, $0?.2, $0?.3, $1) }.map { ($0.0, $0.1, $0.2, $0.3, $1) }
}
