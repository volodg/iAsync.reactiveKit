//
//  QueueState.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final public class QueueState<ValueT, NextT, ErrorT: Error>  {

    typealias OwnerT = StreamOwner<ValueT, NextT, ErrorT>

    var activeStreams  = [OwnerT]()
    var pendingStreams = [OwnerT]()

    func tryRemove(activeStream: OwnerT) -> Bool {

        for (index, object) in activeStreams.enumerated() {
            if object === activeStream {
                activeStreams.remove(at: index)
                return true
            }
        }
        return false
    }

    func tryRemove(pendingStream: OwnerT) {

        for (index, object) in pendingStreams.enumerated() {
            if object === pendingStream {
                pendingStreams.remove(at: index)
                return
            }
        }
    }
}
