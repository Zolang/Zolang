//
//  Token+Convenience.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension Token {
    public static func keyword(_ keyword: String) -> Token? {
        switch keyword {
        case Token.describe.type.rawValue:
            return Token(type: .describe)
        case Token.if.type.rawValue:
            return Token(type: .if)
        case Token.else.type.rawValue:
            return Token(type: .else)
        case Token.as.type.rawValue:
            return Token(type: .as)
        case Token.of.type.rawValue:
            return Token(type: .of)
        case Token.be.type.rawValue:
            return Token(type: .be)
        case Token.let.type.rawValue:
            return Token(type: .let)
        case Token.from.type.rawValue:
            return Token(type: .from)
        case Token.while.type.rawValue:
            return Token(type: .while)
        case Token.return.type.rawValue:
            return Token(type: .return)
        case Token.make.type.rawValue:
            return Token(type: .make)
        case Token.static.type.rawValue:
            return Token(type: .static)
        default:
            return nil
        }
    }
    
    public static func identifier(_ label: String) -> Token {
        return Token(type: .identifier, payload: label)
    }
    
    public static func stringLiteral(_ text: String) -> Token {
        return Token(type: .stringLiteral, payload: text)
    }
    
    public static func booleanLiteral(_ value: String) -> Token {
        return Token(type: .booleanLiteral, payload: value)
    }
    
    public static func prefixOperator(_ raw: String) -> Token {
        return Token(type: .prefixOperator, payload: raw)
    }
    
    public static func `operator`(_ raw: String) -> Token {
        return Token(type: .operator, payload: raw)
    }
    
    public static func decimal(_ raw: String) -> Token {
        return Token(type: .decimal, payload: raw)
    }
    
    public static func floatingPoint(_ raw: String) -> Token {
        return Token(type: .floatingPoint, payload: raw)
    }
    
    public static func other(_ raw: String) -> Token {
        return Token(type: .other, payload: raw)
    }
    
    public static var curlyOpen: Token {
        return Token(type: .curlyOpen)
    }
    
    public static var curlyClose: Token {
        return Token(type: .curlyClose)
    }
    
    public static var parensOpen: Token {
        return Token(type: .parensOpen)
    }
    
    public static var parensClose: Token {
        return Token(type: .parensClose)
    }
    
    public static var bracketOpen: Token {
        return Token(type: .bracketOpen)
    }
    
    public static var bracketClose: Token {
        return Token(type: .bracketClose)
    }
    
    public static var comma: Token {
        return Token(type: .comma)
    }
    
    public static var dot: Token {
        return Token(type: .dot)
    }
    
    public static var colon: Token {
        return Token(type: .colon)
    }
    
    public static var equals: Token {
        return Token(type: .equals)
    }
    
    public static var newline: Token {
        return Token(type: .newline)
    }
    
    public static var describe: Token {
        return Token(type: .describe)
    }
    
    public static var `as`: Token {
        return Token(type: .as)
    }
    
    public static var of: Token {
        return Token(type: .of)
    }
    
    public static var be: Token {
        return Token(type: .be)
    }
    
    public static var make: Token {
        return Token(type: .make)
    }
    
    public static var `static`: Token {
        return Token(type: .`static`)
    }
    
    public static var from: Token {
        return Token(type: .from)
    }
    
    public static var `if`: Token {
        return Token(type: .`if`)
    }
    
    public static var `else`: Token {
        return Token(type: .else)
    }
    
    public static var `while`: Token {
        return Token(type: .`while`)
    }
    
    public static var `return`: Token {
        return Token(type: .`return`)
    }
    
    public static var `let`: Token {
        return Token(type: .`let`)
    }
}
