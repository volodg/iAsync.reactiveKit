//
//  QueueState.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final public class QueueState<Value, Next, Error: ErrorType>  {

    typealias OwnerT = StreamOwner<Value, Next, Error>

    var activeStreams  = [OwnerT]()
    var pendingStreams = [OwnerT]()

    func tryRemoveActiveStream(activeStream: OwnerT) -> Bool {

        for (index, object) in activeStreams.enumerate() {
            if object === activeStream {
                activeStreams.removeAtIndex(index)
                return true
            }
        }
        return false
    }

    func tryRemovePendingStream(activeStream: OwnerT) {

        for (index, object) in pendingStreams.enumerate() {
            if object === activeStream {
                pendingStreams.removeAtIndex(index)
                return
            }
        }
    }
}
