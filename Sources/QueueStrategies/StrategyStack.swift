//
//  StrategyStack.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final internal class StrategyStack<ValueT, NextT, ErrorT: Error> : QueueStrategy {

    static func nextPendingStream(queueState: QueueState<ValueT, NextT, ErrorT>) -> StreamOwner<ValueT, NextT, ErrorT>? {
        let result = queueState.pendingStreams.last
        return result
    }
}
