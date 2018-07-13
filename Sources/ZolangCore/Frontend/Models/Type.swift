//
//  Type.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public indirect enum Type {
    case text
    case number
    case list(Type)
    case custom(String)
}

extension Type: Equatable {
    public static func == (lhs: Type, rhs: Type) -> Bool {
        switch (lhs, rhs) {
        case (.text, .text): return true
        case (.number, .number): return true
        case (.list(let lt), .list(let rt)): return lt == rt
        case (.custom(let ls), .custom(let rs)): return ls == rs
        default: return false
        }
    }
}
