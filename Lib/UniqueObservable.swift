//
//  UniqueProperty.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

private protocol Lock {
    func lock()
    func unlock()
    func atomic<T>(@noescape body: () -> T) -> T
}

private extension Lock {
    func atomic<T>(@noescape body: () -> T) -> T {
        lock(); defer { unlock() }
        return body()
    }
}

/// Recursive Lock
private final class RecursiveLock: NSRecursiveLock, Lock {

    private init(name: String) {
        super.init()
        self.name = name
    }
}

public final class UniqueProperty<T: Equatable>: PropertyType, StreamType, SubjectType {

    private var _value: T
    private let subject = PublishSubject<StreamEvent<T>>()
    private let lock = RecursiveLock(name: "iAsync_reactiveKit.UniqueProperty")
    private let disposeBag = DisposeBag()

    public var rawStream: RawStream<StreamEvent<T>> {
        return subject.toRawStream().startWith(.Next(value))
    }

    /// Underlying value. Changing it emits `.Next` event with new value.
    public var value: T {
        get {
            return lock.atomic { _value }
        }
        set {
            lock.atomic {
                _value = newValue
                if _value != newValue {
                    _value = newValue
                    subject.next(newValue)
                }
            }
        }
    }

    public func on(event: StreamEvent<T>) {
        subject.on(event)
    }

//    public var readOnlyView: AnyProperty<T> {
//        return AnyProperty(property: self)
//    }

    public init(_ value: T) {
        _value = value
    }

    public func silentUpdate(value: T) {
        _value = value
    }

    deinit {
        subject.completed()
    }
}
