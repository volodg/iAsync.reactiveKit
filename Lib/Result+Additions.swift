//
//  Result+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 08/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import enum ReactiveKit.Result

public extension Result {

    func map<U>(_ f: (T) -> U) -> Result<U, Error> {

        switch self {
        case .success(let value):
            return .success(f(value))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Case analysis for Result.
    ///
    /// Returns the value produced by applying `ifFailure` to `Failure` Results, or `ifSuccess` to `Success` Results.
    public func analysis<Result>(ifSuccess: (T) -> Result, ifFailure: (Error) -> Result) -> Result {
        switch self {
        case let .success(value):
            return ifSuccess(value)
        case let .failure(value):
            return ifFailure(value)
        }
    }

    /// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
    public func flatMap<U>( _ transform: (T) -> Result<U, Error>) -> Result<U, Error> {
        return analysis(
            ifSuccess: transform,
            ifFailure: Result<U, Error>.failure)
    }

    /// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
    public func flatMapError<Error2>( _ transform: (Error) -> Result<T, Error2>) -> Result<T, Error2> {
        return analysis(
            ifSuccess: Result<T, Error2>.success,
            ifFailure: transform)
    }
}
