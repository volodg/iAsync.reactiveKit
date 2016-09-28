//
//  Stream.swift
//  Pods
//
//  Created by Gorbenko Vladimir on 28/09/16.
//
//

import Foundation

import ReactiveKit
import ReactiveKit_old

extension Stream_old {

    public func toStream() -> Stream<Event> {

        return Stream { observer in

            return self.observe { value in

                observer.next(value)
            }
        }
    }
}

extension Stream {

    public func toStream() -> Stream_old<Element> {

        return create_old { observer in

            return self.observe { value in

                if let val = value.element {
                    observer(val)
                } else {
                    fatalError()
                }
            }
        }
    }
}
