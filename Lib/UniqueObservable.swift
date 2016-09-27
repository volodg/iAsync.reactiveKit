//
//  UniqueObservable.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit_old

public final class UniqueObservable<Value: Equatable>: ActiveStream<Value>, ObservableType {

    private var _value: Value!

    public var value: Value {
        get {
            return _value
        }
        set {
            if _value != newValue {
                _value = newValue
                super.next(newValue)
            }
        }
    }

    public override func next(event: Value) {

        self.value = event
    }

    public override func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
        let disposable = super.observe(on: context, observer: observer)
        observer(value)
        return disposable
    }

    public init(_ value: Value) {
        super.init()
        self.value = value
    }
}
