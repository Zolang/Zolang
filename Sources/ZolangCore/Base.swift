//
//  Base.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

public protocol BaseType {
    associatedtype T
    var t: T { get }

    init(_ t: T)
}

public struct Base<T>: BaseType {
    public let t: T
    
    public init(_ t: T) {
        self.t = t
    }
}
