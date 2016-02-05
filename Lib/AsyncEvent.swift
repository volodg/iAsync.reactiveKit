//
//  AsyncEvent.swift
//  iAsync.reactiveKit
//
//  Created by Gorbenko Vladimir on 03/02/16.
//  Copyright © 2016 Volodymyr. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import ReactiveKit

public enum AsyncEvent<ValueT, ProgressT, ErrorT: ErrorType> {

    case Success(ValueT)
    case Failure(ErrorT)
    case Progress(ProgressT)

    public var isTerminal: Bool {
        switch self {
        case .Success, .Failure:
            return true
        case .Progress:
            return false
        }
    }
}

public protocol AsyncStreamType: StreamType {
    typealias Value
    typealias Progress
    typealias Error: ErrorType

    func lift<R, P, E: ErrorType>(transform: Stream<AsyncEvent<Value, Progress, Error>> -> Stream<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E>
}

public struct AsyncStream<ValueT, ProgressT, ErrorT: ErrorType>: AsyncStreamType {

    public typealias Value    = ValueT
    public typealias Progress = ProgressT
    public typealias Error    = ErrorT
    public typealias Event    = AsyncEvent<Value, Progress, Error>

    private let stream: Stream<Event>

    public typealias Observer = Event -> ()
    
    public init(producer: (Observer -> DisposableType?)) {
        stream = Stream  { observer in
            var completed: Bool = false

            return producer { event in
                if !completed {
                    completed = event.isTerminal
                    observer(event)
                }
            }
        }
    }

    public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
        return stream.observe(on: context, observer: observer)
    }

    public static func succeeded(with value: Value) -> Operation<Value, Error> {
        return create { observer in
            observer.next(value)
            observer.success()
            return nil
        }
    }

    public static func failed(with error: Error) -> Operation<Value, Error> {
        return create { observer in
            observer.failure(error)
            return nil
        }
    }

    public func lift<R, P, E: ErrorType>(transform: Stream<AsyncEvent<Value, Progress, Error>> -> Stream<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E> {
        return create { observer in
            return transform(self.stream).observe(on: nil, observer: observer)
        }
    }
}

public func create<Value, Progress, Error: ErrorType>(producer producer: (AsyncEvent<Value, Progress, Error> -> ()) -> DisposableType?) -> AsyncStream<Value, Progress, Error> {
    return AsyncStream<Value, Progress, Error> { observer in
        return producer(observer)
    }
}
