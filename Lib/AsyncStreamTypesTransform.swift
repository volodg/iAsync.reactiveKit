//
//  AsyncStreamTypesTransform.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 07/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

public enum PackedValue<Value1, Value2> {
    case First(Value1)
    case Second(Value2)
}

public enum PackedError<Error1: ErrorType, Error2: ErrorType>: ErrorType {
    case First(Error1)
    case Second(Error2)
}

public enum AsyncStreamTypesTransform<Value1, Value2, Next1, Next2, Error1: ErrorType, Error2: ErrorType> {

    public typealias Stream1 = AsyncStream<Value1, Next1, Error1>
    public typealias Stream2 = AsyncStream<Value2, Next2, Error2>

    public typealias PackedValueT = PackedValue<Value1, Value2>
    public typealias PackedNextT  = PackedValue<Next1, Next2>
    public typealias PackedErrorT = PackedError<Error1, Error2>

    public typealias PackedAsyncStream = AsyncStream<PackedValueT, PackedNextT, PackedErrorT>

    public typealias AsyncStreamTransformer = PackedAsyncStream -> PackedAsyncStream

    public static func transformStreamsType(stream: Stream1, transformer: AsyncStreamTransformer) -> Stream1 {

        let packedStream = stream.lift { $0.map { (ev: Stream1.Event) -> PackedAsyncStream.Event in
            switch ev {
            case .Success(let value):
                return .Success(.First(value))
            case .Failure(let value):
                return .Failure(.First(value))
            case .Next(let value):
                return .Next(.First(value))
            }
        }}

        let transformedStream = transformer(packedStream)

        return transformedStream.lift { $0.map { ev -> Stream1.Event in
            switch ev {
            case .Success(.First(let value)):
                return .Success(value)
            case .Failure(.First(let value)):
                return .Failure(value)
            case .Next(.First(let value)):
                return .Next(value)
            default:
                fatalError()
            }
        }}
    }

    public static func transformStreamsType(stream: Stream2, transformer: AsyncStreamTransformer) -> Stream2 {

        let packedStream = stream.lift { $0.map { ev -> PackedAsyncStream.Event in
            switch ev {
            case .Success(let value):
                return .Success(.Second(value))
            case .Failure(let value):
                return .Failure(.Second(value))
            case .Next(let value):
                return .Next(.Second(value))
            }
        }}

        let transformedStream = transformer(packedStream)

        return transformedStream.lift { $0.map { ev -> Stream2.Event in
            switch ev {
            case .Success(.Second(let value)):
                return .Success(value)
            case .Failure(.Second(let value)):
                return .Failure(value)
            case .Next(.Second(let value)):
                return .Next(value)
            default:
                fatalError()
            }
        }}
    }
}
