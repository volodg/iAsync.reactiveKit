//
//  AsyncEvent.swift
//  iAsync.reactiveKit
//
//  Created by Gorbenko Vladimir on 03/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

public enum AsyncEvent<ValueT, NextT, ErrorT: ErrorType> {

    case Success(ValueT)
    case Failure(ErrorT)
    case Next(NextT)

    public var isTerminal: Bool {
        switch self {
        case .Success, .Failure:
            return true
        case .Next:
            return false
        }
    }

    public func map<U>(transform: ValueT -> U) -> AsyncEvent<U, NextT, ErrorT> {
        switch self {
        case .Next(let event):
            return .Next(event)
        case .Failure(let error):
            return .Failure(error)
        case .Success(let event):
            return .Success(transform(event))
        }
    }

    public func mapError<F>(transform: ErrorT -> F) -> AsyncEvent<ValueT, NextT, F> {
        switch self {
        case .Next(let event):
            return .Next(event)
        case .Failure(let error):
            return .Failure(transform(error))
        case .Success(let event):
            return .Success(event)
        }
    }

    public func filter(include: ValueT -> Bool) -> Bool {
        switch self {
        case .Success(let value):
            if include(value) {
                return true
            } else {
                return false
            }
        default:
            return true
        }
    }
}
