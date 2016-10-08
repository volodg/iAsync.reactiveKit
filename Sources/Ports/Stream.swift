//
//  Stream.swift
//  Pods
//
//  Created by Gorbenko Vladimir on 28/09/16.
//
//

import Foundation

import ReactiveKit

public extension SignalProtocol {

    /// Create a stream that emits given element and then completes.
    public static func next(_ element: Element) -> Signal<Element, Error> {
        return Signal { observer in
            observer.next(element)
            return NonDisposable.instance
        }
    }
}
