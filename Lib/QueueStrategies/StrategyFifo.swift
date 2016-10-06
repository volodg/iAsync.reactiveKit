//
//  StrategyFifo.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final public class StrategyFifo<ValueT, NextT, ErrorT: Error> : QueueStrategy {

    public static func nextPendingStream(_ queueState: QueueState<ValueT, NextT, ErrorT>) -> StreamOwner<ValueT, NextT, ErrorT>? {
        return queueState.pendingStreams.first
    }
}
