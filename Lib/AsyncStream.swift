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

public protocol AsyncStreamType: StreamType {
    typealias Value
    typealias Next
    typealias Error: ErrorType

    func lift<R, P, E: ErrorType>(transform: Stream<AsyncEvent<Value, Next, Error>> -> Stream<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E>
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

    private let stream: Stream<Event>

    public typealias Observer = Event -> ()

    public init(producer: (Observer -> DisposableType?)) {
        stream = Stream  { observer in
            var observerHolder: Observer? = observer

            let dispose = producer { event in
                if let observer = observerHolder {
                    if event.isTerminal {
                        observerHolder = nil
                    }
                    observer(event)
                }
            }

            return BlockDisposable { () -> Void in
                //observerHolder = nil
                dispose?.dispose()
            }
        }
    }

    public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
        return stream.observe(on: context, observer: observer)
    }

    public func run() {
        stream.observe(observer: {_ in})
    }

    public func after(delay: NSTimeInterval) -> AsyncStream<Value, Next, Error> {

        let delayStream = AsyncStream<Void, Next, Error>.succeededAfter(delay: delay, with: ())
        return delayStream.flatMap(.Latest) { _ in self }
    }

    public static func succeeded(with value: Value) -> AsyncStream<Value, Next, Error> {
        return create { observer in
            observer(.Success(value))
            return nil
        }
    }

    public static func succeededAfter(delay delay: NSTimeInterval, with value: Value) -> AsyncStream<Value, Next, Error> {
        return create { observer in

            let cancel = Timer.sharedByThreadTimer().addBlock({ cancel -> Void in
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

    public func lift<R, P, E: ErrorType>(transform: Stream<AsyncEvent<Value, Next, Error>> -> Stream<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E> {
        return create { observer in
            return transform(self.stream).observe(on: nil, observer: observer)
        }
    }
}

public func create<Value, Next, Error: ErrorType>(producer producer: (AsyncEvent<Value, Next, Error> -> ()) -> DisposableType?) -> AsyncStream<Value, Next, Error> {
    return AsyncStream<Value, Next, Error> { observer in
        return producer(observer)
    }
}

public extension AsyncStreamType {

    public func on(next next: (Next -> ())? = nil, success: (Value -> ())? = nil, failure: (Error -> ())? = nil, start: (() -> Void)? = nil, completed: (() -> Void)? = nil, context: ExecutionContext? = ImmediateOnMainExecutionContext) -> AsyncStream<Value, Next, Error> {
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

    public func observeNext(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Next -> ()) -> DisposableType {
        return self.observe(on: context) { event in
            switch event {
            case .Next(let event):
                observer(event)
            default: break
            }
        }
    }

    public func observeError(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Error -> ()) -> DisposableType {
        return self.observe(on: context) { event in
            switch event {
            case .Failure(let error):
                observer(error)
            default: break
            }
        }
    }

    @warn_unused_result
    public func shareNext(limit: Int = Int.max, context: ExecutionContext? = nil) -> ObservableBuffer<Next> {
        return ObservableBuffer(limit: limit) { observer in
            return self.observeNext(on: context, observer: observer)
        }
    }

    @warn_unused_result
    public func map<U>(transform: Value -> U) -> AsyncStream<U, Next, Error> {
        return lift { $0.map { $0.map(transform) } }
    }

    @warn_unused_result
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

    @warn_unused_result
    public func mapError<F>(transform: Error -> F) -> AsyncStream<Value, Next, F> {
        return lift { $0.map { $0.mapError(transform) } }
    }

    @warn_unused_result
    public func filter(include: Value -> Bool) -> AsyncStream<Value, Next, Error> {
        return lift { $0.filter { $0.filter(include) } }
    }

    @warn_unused_result
    public func switchTo(context: ExecutionContext) -> AsyncStream<Value, Next, Error> {
        return lift { $0.switchTo(context) }
    }

    @warn_unused_result
    public func throttle(seconds: Double, on queue: Queue) -> AsyncStream<Value, Next, Error> {
        return lift { $0.throttle(seconds, on: queue) }
    }

    @warn_unused_result
    public func skip(count: Int) -> AsyncStream<Value, Next, Error> {
        return lift { $0.skip(count) }
    }

    @warn_unused_result
    public func startWith(event: Next) -> AsyncStream<Value, Next, Error> {
        return lift { $0.startWith(.Next(event)) }
    }

    //TODO test
    @warn_unused_result
    public func retry(var count: Int, delay: NSTimeInterval? = nil, until: Result<Value, Error> -> Bool) -> AsyncStream<Value, Next, Error> {
        return create { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)

            var attempt: (() -> Void)?

            let observer = { (event: AsyncEvent<Value, Next, Error>) -> Void in

                let rertyOrFinish = { (result: Result<Value, Error>) in
                    if !until(result) && count > 0 {
                        count -= 1
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
                let dispose = delayStream.flatMap(.Latest) { self }.observe(on: nil, observer: observer)
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

//    @warn_unused_result
//    public func take(count: Int) -> Operation<Value, Error> {
//        return create { observer in
//            
//            if count <= 0 {
//                observer.success()
//                return nil
//            }
//            
//            var taken = 0
//            
//            let serialDisposable = SerialDisposable(otherDisposable: nil)
//            serialDisposable.otherDisposable = self.observe(on: nil) { event in
//                
//                switch event {
//                case .Next(let value):
//                    if taken < count {
//                        taken += 1
//                        observer.next(value)
//                    }
//                    if taken == count {
//                        observer.success()
//                        serialDisposable.otherDisposable?.dispose()
//                    }
//                default:
//                    observer.observer(event)
//                }
//            }
//            
//            return serialDisposable
//        }
//    }
//    
//    @warn_unused_result
//    public func first() -> Operation<Value, Error> {
//        return take(1)
//    }
//    
//    @warn_unused_result
//    public func takeLast(count: Int = 1) -> Operation<Value, Error> {
//        return create { observer in
//            
//            var values: [Value] = []
//            values.reserveCapacity(count)
//            
//            return self.observe(on: nil) { event in
//                
//                switch event {
//                case .Next(let value):
//                    while values.count + 1 > count {
//                        values.removeFirst()
//                    }
//                    values.append(value)
//                case .Success:
//                    values.forEach(observer.next)
//                    observer.success()
//                default:
//                    observer.observer(event)
//                }
//            }
//        }
//    }
//    
//    @warn_unused_result
//    public func last() -> Operation<Value, Error> {
//        return takeLast(1)
//    }
//    
//    @warn_unused_result
//    public func pausable<S: StreamType where S.Event == Bool>(by: S) -> Operation<Value, Error> {
//        return create { observer in
//            
//            var allowed: Bool = true
//            
//            let compositeDisposable = CompositeDisposable()
//            compositeDisposable += by.observe(on: nil) { value in
//                allowed = value
//            }
//            
//            compositeDisposable += self.observe(on: nil) { event in
//                switch event {
//                case .Next(let value):
//                    if allowed {
//                        observer.next(value)
//                    }
//                default:
//                    observer.observer(event)
//                }
//            }
//            
//            return compositeDisposable
//        }
//    }
//    
//    @warn_unused_result
//    public func scan<U>(initial: U, _ combine: (U, Value) -> U) -> Operation<U, Error> {
//        return create { observer in
//            
//            var scanned = initial
//            
//            return self.observe(on: nil) { event in
//                observer.observer(event.map { value in
//                    scanned = combine(scanned, value)
//                    return scanned
//                })
//            }
//        }
//    }
//
//    @warn_unused_result
//    public func reduce<U>(initial: U, _ combine: (U, Value) -> U) -> Operation<U, Error> {
//        return Operation<U, Error> { observer in
//            observer.next(initial)
//            return self.scan(initial, combine).observe(on: nil, observer: observer.observer)
//            }.takeLast()
//    }
//    
//    @warn_unused_result
//    public func collect() -> Operation<[Value], Error> {
//        return reduce([], { memo, new in memo + [new] })
//    }

    //TODO test
    @warn_unused_result
    public func combineLatestWith<S: AsyncStreamType where S.Error == Error>(other: S) -> AsyncStream<(Value, S.Value), (Next?, S.Next?), Error> {
        return create { observer in
            let queue = Queue(name: "com.ReactiveKit.ReactiveKit.Operation.CombineLatestWith")

            var latestSelfNext : Next? = nil
            var latestOtherNext: S.Next? = nil

            var latestSelfEvent : AsyncEvent<Value, Next, Error>! = nil
            var latestOtherEvent: AsyncEvent<S.Value, S.Next, S.Error>! = nil

            let dispatchNextIfPossible = { () -> () in
                if latestSelfNext != nil || latestOtherNext != nil {
                    let next = (latestSelfNext, latestOtherNext)
                    observer(.Next(next))
                }
            }

            let onBoth = { () -> () in
                if latestSelfEvent != nil || latestOtherEvent != nil {
                    switch (latestSelfEvent, latestOtherEvent) {
                    case (.Some(.Success(let selfValue)), .Some(.Success(let otherValue))):
                        observer(.Success(selfValue, otherValue))
                    case (.Some(.Next(let selfNext)), .Some(.Next(let otherNext))):
                        latestSelfNext  = selfNext
                        latestOtherNext = otherNext
                        dispatchNextIfPossible()
                    case (.Some(.Next(let selfNext)), _):
                        latestSelfNext = selfNext
                        dispatchNextIfPossible()
                    case (_, .Some(.Next(let otherNext))):
                        latestOtherNext = otherNext
                        dispatchNextIfPossible()
                    default:
                        dispatchNextIfPossible()
                    }
                }
            }

            let selfDisposable = self.observe(on: nil) { event in
                if case .Failure(let error) = event {
                    observer(.Failure(error))
                } else {
                    queue.sync {
                        latestSelfEvent = event
                        onBoth()
                    }
                }
            }

            let otherDisposable = other.observe(on: nil) { event in
                if case .Failure(let error) = event {
                    observer(.Failure(error))
                } else {
                    queue.sync {
                        latestOtherEvent = event
                        onBoth()
                    }
                }
            }

            return CompositeDisposable([selfDisposable, otherDisposable])
        }
    }

    @warn_unused_result
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
                if let selfValue = selfValue, otherValue = otherValue {
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

//public extension OperationType where Value: OptionalType {
//    
//    @warn_unused_result
//    public func ignoreNil() -> Operation<Value.Wrapped?, Error> {
//        return lift { $0.filter { $0.filter { $0._unbox != nil } }.map { $0.map { $0._unbox! } } }
//    }
//}

public extension AsyncStreamType where Value: AsyncStreamType, Value.Next == Next, Value.Error == Error {

    @warn_unused_result
    public func merge() -> AsyncStream<Value.Value, Value.Next, Value.Error> {

        fatalError()
//        return create { observer in
//            let queue = Queue(name: "com.ReactiveKit.ReactiveKit.Operation.Merge")
//
//            var numberOfOperations = 1
//            let compositeDisposable = CompositeDisposable()
//
//            let decrementNumberOfOperations = { () -> () in
//                queue.sync {
//                    numberOfOperations -= 1
//                    if numberOfOperations == 0 {
//                        observer.success()
//                    }
//                }
//            }
//
//            compositeDisposable += self.observe(on: nil) { taskEvent in
//
//                switch taskEvent {
//                case .Failure(let error):
//                    return observer.failure(error)
//                case .Success:
//                    decrementNumberOfOperations()
//                case .Next(let task):
//                    queue.sync {
//                        numberOfOperations += 1
//                    }
//                    compositeDisposable += task.observe(on: nil) { event in
//                        switch event {
//                        case .Next, .Failure:
//                            observer.observer(event)
//                        case .Success:
//                            decrementNumberOfOperations()
//                        }
//                    }
//                }
//            }
//            return compositeDisposable
//        }
    }

    @warn_unused_result
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

    @warn_unused_result
    public func concat() -> AsyncStream<Value.Value, Value.Next, Value.Error> {

        fatalError()
//        return create { observer in
//            let queue = Queue(name: "com.ReactiveKit.ReactiveKit.Operation.Concat")
//
//            let serialDisposable = SerialDisposable(otherDisposable: nil)
//            let compositeDisposable = CompositeDisposable([serialDisposable])
//
//            var outerCompleted: Bool = false
//            var innerCompleted: Bool = true
//
//            var taskQueue: [Value] = []
//
//            var startNextOperation: (() -> ())! = nil
//            startNextOperation = {
//                innerCompleted = false
//
//                let task: Value = queue.sync {
//                    return taskQueue.removeAtIndex(0)
//                }
//
//                serialDisposable.otherDisposable?.dispose()
//                serialDisposable.otherDisposable = task.observe(on: nil) { event in
//                    switch event {
//                    case .Failure(let error):
//                        observer.failure(error)
//                    case .Success:
//                        innerCompleted = true
//                        if taskQueue.count > 0 {
//                            startNextOperation()
//                        } else if outerCompleted {
//                            observer.success()
//                        }
//                    case .Next(let value):
//                        observer.next(value)
//                    }
//                }
//            }
//
//            let addToQueue = { (task: Value) -> () in
//                queue.sync {
//                    taskQueue.append(task)
//                }
//
//                if innerCompleted {
//                    startNextOperation()
//                }
//            }
//
//            compositeDisposable += self.observe(on: nil) { taskEvent in
//
//                switch taskEvent {
//                case .Failure(let error):
//                    observer.failure(error)
//                case .Success:
//                    outerCompleted = true
//                    if innerCompleted {
//                        observer.success()
//                    }
//                case .Next(let innerOperation):
//                    addToQueue(innerOperation)
//                }
//            }
//
//            return compositeDisposable
//        }
    }
}

public enum AsyncStreamFlatMapStrategy {
    case Latest
    case Merge
    case Concat
}

public extension AsyncStreamType {

    //TODO test
    @warn_unused_result
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

//    @warn_unused_result
//    public func flatMapError<T: OperationType where T.Value == Value>(recover: Error -> T) -> Operation<T.Value, T.Error> {
//        return create { observer in
//            let serialDisposable = SerialDisposable(otherDisposable: nil)
//
//            serialDisposable.otherDisposable = self.observe(on: nil) { taskEvent in
//                switch taskEvent {
//                case .Next(let value):
//                    observer.next(value)
//                case .Success:
//                    observer.success()
//                case .Failure(let error):
//                    serialDisposable.otherDisposable = recover(error).observe(on: nil) { event in
//                        observer.observer(event)
//                    }
//                }
//            }
//
//            return serialDisposable
//        }
//    }
}

@warn_unused_result
public func combineLatest<A: AsyncStreamType, B: AsyncStreamType where A.Error == B.Error>(a: A, _ b: B) -> AsyncStream<(A.Value, B.Value), (A.Next?, B.Next?), A.Error> {
    return a.combineLatestWith(b)
}

@warn_unused_result
public func zip<A: AsyncStreamType, B: AsyncStreamType where A.Error == B.Error>(a: A, _ b: B) -> AsyncStream<(A.Value, B.Value), (A.Next, B.Next), A.Error> {
    return a.zipWith(b)
}

@warn_unused_result
public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType where A.Error == B.Error, A.Error == C.Error>(a: A, _ b: B, _ c: C) -> AsyncStream<(A.Value, B.Value, C.Value), (A.Next?, B.Next?, C.Next?), A.Error> {
    return combineLatest(a, b).combineLatestWith(c).mapNext { ($0?.0, $0?.1, $1) }.map { ($0.0, $0.1, $1) }
}

@warn_unused_result
public func zip<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType where A.Error == B.Error, A.Error == C.Error>(a: A, _ b: B, _ c: C) -> AsyncStream<(A.Value, B.Value, C.Value), (A.Next?, B.Next?, C.Next?), A.Error> {
    return zip(a, b).zipWith(c).mapNext { ($0.0, $0.1, $1) }.map { ($0.0, $0.1, $1) }
}

@warn_unused_result
public func combineLatest<A: AsyncStreamType, B: AsyncStreamType, C: AsyncStreamType, D: AsyncStreamType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error>(a: A, _ b: B, _ c: C, _ d: D) -> AsyncStream<(A.Value, B.Value, C.Value, D.Value), (A.Next?, B.Next?, C.Next?, D.Next?), A.Error> {
    return combineLatest(a, b, c).combineLatestWith(d).mapNext { ($0?.0, $0?.1, $0?.2, $1) }.map { ($0.0, $0.1, $0.2, $1) }
}

//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error>(a: A, _ b: B, _ c: C, _ d: D) -> Operation<(A.Value, B.Value, C.Value, D.Value), A.Error> {
//    return zip(a, b, c).zipWith(d).map { ($0.0, $0.1, $0.2, $1) }
//}
//
//@warn_unused_result
//public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error>
//    (a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value), A.Error>
//{
//    return combineLatest(a, b, c, d).combineLatestWith(e).map { ($0.0, $0.1, $0.2, $0.3, $1) }
//}
//
//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error>
//    (a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value), A.Error>
//{
//    return zip(a, b, c, d).zipWith(e).map { ($0.0, $0.1, $0.2, $0.3, $1) }
//}
//
//@warn_unused_result
//public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value), A.Error>
//{
//    return combineLatest(a, b, c, d, e).combineLatestWith(f).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $1) }
//}
//
//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value), A.Error>
//{
//    return zip(a, b, c, d, e).zipWith(f).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $1) }
//}
//
//@warn_unused_result
//public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value), A.Error>
//{
//    return combineLatest(a, b, c, d, e, f).combineLatestWith(g).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $1) }
//}

//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value), A.Error>
//{
//    return zip(a, b, c, d, e, f).zipWith(g).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $1) }
//}
//
//@warn_unused_result
//public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value), A.Error>
//{
//    return combineLatest(a, b, c, d, e, f, g).combineLatestWith(h).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $1) }
//}
//
//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value), A.Error>
//{
//    return zip(a, b, c, d, e, f, g).zipWith(h).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $1) }
//}
//
//@warn_unused_result
//public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value), A.Error>
//{
//    return combineLatest(a, b, c, d, e, f, g, h).combineLatestWith(i).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $1) }
//}
//
//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value), A.Error>
//{
//    return zip(a, b, c, d, e, f, g, h).zipWith(i).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $1) }
//}
//
//@warn_unused_result
//public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value), A.Error>
//{
//    return combineLatest(a, b, c, d, e, f, g, h, i).combineLatestWith(j).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $1) }
//}
//
//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value), A.Error>
//{
//    return zip(a, b, c, d, e, f, g, h, i).zipWith(j).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $1) }
//}
//
//@warn_unused_result
//public func combineLatest<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType, K: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error, A.Error == K.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J, _ k: K) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value, K.Value), A.Error>
//{
//    return combineLatest(a, b, c, d, e, f, g, h, i, j).combineLatestWith(k).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $0.9, $1) }
//}
//
//@warn_unused_result
//public func zip<A: OperationType, B: OperationType, C: OperationType, D: OperationType, E: OperationType, F: OperationType, G: OperationType, H: OperationType, I: OperationType, J: OperationType, K: OperationType where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error, A.Error == G.Error, A.Error == H.Error, A.Error == I.Error, A.Error == J.Error, A.Error == K.Error>
//    ( a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J, _ k: K) -> Operation<(A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value, K.Value), A.Error>
//{
//    return zip(a, b, c, d, e, f, g, h, i, j).zipWith(k).map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7, $0.8, $0.9, $1) }
//}
