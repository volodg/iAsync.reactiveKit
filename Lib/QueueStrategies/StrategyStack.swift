//
//  StrategyStack.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final internal class StrategyStack<Value, Next, Error: ErrorType> : QueueStrategy {

    static func nextPendingStream(queueState: QueueState<Value, Next, Error>) -> StreamOwner<Value, Next, Error>? {
        let result = queueState.pendingStreams.last
        return result
    }
}
