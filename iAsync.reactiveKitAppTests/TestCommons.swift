//
//  TestCommons.swift
//  iAsync.reactiveKitApp
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_reactiveKit

import ReactiveKit

extension Stream : AsyncStreamType {

    public typealias Value    = String
    public typealias Progress = AnyObject
    public typealias Error    = NSError
}