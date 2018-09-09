//
//  Type.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public enum PrimitiveType: String {
    case text
    case number
    case boolean
}

public indirect enum Type {
    case primitive(PrimitiveType)
    case list(Type)
    case custom(String)
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        guard tokens.hasPrefixTypes(types: [ .identifier ]) else {
            throw ZolangError(type: .unexpectedToken(tokens[0], TokenType.identifier),
                              file: context.file,
                              line: context.line)
        }
        
        guard tokens.filter({ $0.type != .newline }).count != 1 else {
            guard let prim = PrimitiveType(rawValue: tokens[0].payload!) else {
                self = .custom(tokens[0].payload!)
                return
            }
            self = .primitive(prim)
            return
        }

        guard let ofIndex = tokens.index(of: [ .of ]) else {
            throw ZolangError(type: .invalidType,
                              file: context.file,
                              line: context.line)
        }
        
        guard ofIndex + 1 < tokens.count else {
            throw ZolangError(type: .invalidType,
                              file: context.file,
                              line: context.line + tokens.newLineCount(to: ofIndex))
        }
        
        context.line += tokens.newLineCount(to: ofIndex)
        
        let rest = Array(tokens.suffix(from: ofIndex + 1))
        
        self = .list(try Type(tokens: rest, context: &context))
    }
}

extension Type: Equatable {
    public static func == (lhs: Type, rhs: Type) -> Bool {
        switch (lhs, rhs) {
        case (.primitive(let l), .primitive(let r)): return l == r
        case (.list(let lt), .list(let rt)): return lt == rt
        case (.custom(let ls), .custom(let rs)): return ls == rs
        default: return false
        }
    }
}
