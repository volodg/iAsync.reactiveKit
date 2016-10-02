//
//  AsyncEvent.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 03/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

public enum AsyncEvent<ValueT, NextT, ErrorT: Error> {

    case success(ValueT)
    case failure(ErrorT)
    case next(NextT)

    public var value: ValueT? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }

    public var error: ErrorT? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }

    public var isTerminal: Bool {
        switch self {
        case .success, .failure:
            return true
        case .next:
            return false
        }
    }

    public var isSuccess: Bool {
        return value != nil
    }

    public var isFailure: Bool {
        return error != nil
    }

    public func map<U>(_ transform: (ValueT) -> U) -> AsyncEvent<U, NextT, ErrorT> {
        switch self {
        case .next(let event):
            return .next(event)
        case .failure(let error):
            return .failure(error)
        case .success(let event):
            return .success(transform(event))
        }
    }

    public func mapError<F>(_ transform: (ErrorT) -> F) -> AsyncEvent<ValueT, NextT, F> {
        switch self {
        case .next(let event):
            return .next(event)
        case .failure(let error):
            return .failure(transform(error))
        case .success(let event):
            return .success(event)
        }
    }

    public func filter(_ include: (ValueT) -> Bool) -> Bool {
        switch self {
        case .success(let value):
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
