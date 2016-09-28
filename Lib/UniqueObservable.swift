//
//  UniqueObservable.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit
import ReactiveKit_old//???

public final class UniqueProperty<Value: Equatable>: Property<Value> {

    public override init(_ value: Value) {
        super.init(value)
    }

    override public var value: Value {
        get {
            return super.value
        }
        set {
            if super.value != newValue {
                super.value = newValue
                super.next(newValue)
            }
        }
    }
}
