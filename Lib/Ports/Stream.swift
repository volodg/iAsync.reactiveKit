//
//  Stream.swift
//  Pods
//
//  Created by Gorbenko Vladimir on 28/09/16.
//
//

import Foundation

import ReactiveKit

public extension Stream {

    /// Create a stream that emits given element and then completes.
    public static func next(element: Element) -> Stream<Element> {
        return Stream { observer in
            observer.next(element)
            return NotDisposable
        }
    }
}

extension RawStream {

    public func toStream() -> Stream<Event> {

        return Stream { observer in

            return self.observe { value in

                observer.next(value)
            }
        }
    }
}

extension Property {

    public func toStream() -> Stream<ProperyElement> {

        return Stream { observer in

            return self.observe { value in

                observer.on(value)
            }
        }
    }
}
