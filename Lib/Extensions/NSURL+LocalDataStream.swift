//
//  NSURL+LocalDataStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 25.11.15.
//  Copyright © 2015 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit_old//???

extension NSURL {

    @warn_unused_result
    public func localDataStream() -> AsyncStream<NSData, AnyObject, ErrorWithContext> {

        return create { observer -> DisposableType? in

            self.localDataWithCallbacks({ data in

                observer(.Success(data))
            }) { error in

                observer(.Failure(error))
            }
            return nil
        }
    }
}
