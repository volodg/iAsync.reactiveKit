//
//  QueueStrategy.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

public protocol QueueStrategy {

    typealias Value
    typealias Next
    typealias Error: ErrorType

    static func nextPendingStream(queueState: QueueState<Value, Next, Error>) -> StreamOwner<Value, Next, Error>?
}

extension QueueStrategy {

    internal static func executePendingStream(queueState: QueueState<Value, Next, Error>, pendingStream: StreamOwner<Value, Next, Error>) {

        var objectIndex: Int?

        for (index, loader) in queueState.pendingStreams.enumerate() {
            if loader === pendingStream {
                objectIndex = index
                break
            }
        }

        if let objectIndex = objectIndex {
            queueState.pendingStreams.removeAtIndex(objectIndex)
        }

        queueState.activeStreams.append(pendingStream)

        pendingStream.performStream()
    }
}
