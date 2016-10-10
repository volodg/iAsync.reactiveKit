//
//  AsyncStreamTypesTransform.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 07/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

public enum PackedValue<Value1, Value2> {
    case first(Value1)
    case second(Value2)
}

public enum PackedError<Error1: Error, Error2: Error>: Error {
    case first(Error1)
    case second(Error2)
}

public enum AsyncStreamTypesTransform<Value1, Value2, Next1, Next2, Error1: Error, Error2: Error> {

    public typealias Stream1 = AsyncStream<Value1, Next1, Error1>
    public typealias Stream2 = AsyncStream<Value2, Next2, Error2>

    public typealias PackedValueT = PackedValue<Value1, Value2>
    public typealias PackedNextT  = PackedValue<Next1, Next2>
    public typealias PackedErrorT = PackedError<Error1, Error2>

    public typealias PackedAsyncStream = AsyncStream<PackedValueT, PackedNextT, PackedErrorT>

    public typealias AsyncStreamTransformer = (PackedAsyncStream) -> PackedAsyncStream

    public static func transform(stream: Stream1, transformer: AsyncStreamTransformer) -> Stream1 {

        let packedStream = stream.lift { $0.map { (ev: Stream1.Event) -> PackedAsyncStream.Event in
            switch ev {
            case .success(let value):
                return .success(.first(value))
            case .failure(let value):
                return .failure(.first(value))
            case .next(let value):
                return .next(.first(value))
            }
        }}

        let transformedStream = transformer(packedStream)

        return transformedStream.lift { $0.map { ev -> Stream1.Event in
            switch ev {
            case .success(.first(let value)):
                return .success(value)
            case .failure(.first(let value)):
                return .failure(value)
            case .next(.first(let value)):
                return .next(value)
            default:
                fatalError()
            }
        }}
    }

    public static func transform(stream: Stream2, transformer: AsyncStreamTransformer) -> Stream2 {

        let packedStream = stream.lift { $0.map { ev -> PackedAsyncStream.Event in
            switch ev {
            case .success(let value):
                return .success(.second(value))
            case .failure(let value):
                return .failure(.second(value))
            case .next(let value):
                return .next(.second(value))
            }
        }}

        let transformedStream = transformer(packedStream)

        return transformedStream.lift { $0.map { ev -> Stream2.Event in
            switch ev {
            case .success(.second(let value)):
                return .success(value)
            case .failure(.second(let value)):
                return .failure(value)
            case .next(.second(let value)):
                return .next(value)
            default:
                fatalError()
            }
        }}
    }
}
