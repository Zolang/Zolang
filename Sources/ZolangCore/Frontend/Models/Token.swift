//
//  Token.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

public enum TokenType: String {
    case parensOpen
    case parensClose
    case bracketOpen
    case bracketClose
    case curlyOpen
    case curlyClose
    case newline
    case equals
    
    case comma
    case dot
    case colon
    
    case identifier
    
    case describe
    case `as`
    case be
    case of
    case `while`
    case `let`
    case `return`
    case from
    case `if`
    case `else`
    case make
    case `static`
    
    case `operator`
    case prefixOperator
    
    case accessLimitation
    
    case stringLiteral
    case booleanLiteral
    case floatingPoint
    case decimal
    
    case other
}
public struct Token: Equatable {
    public let type: TokenType
    public let payload: String?
    
    init(type: TokenType, payload: String? = nil) {
        self.type = type
        self.payload = payload
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        switch (lhs.type, rhs.type) {
        case (.parensOpen, .parensOpen),
             (.parensClose, .parensClose),
             (.bracketOpen, .bracketOpen),
             (.bracketClose, .bracketClose),
             (.curlyOpen, .curlyOpen),
             (.curlyClose, .curlyClose),
             (.newline, .newline),
             (.comma, .comma),
             (.dot, .dot),
             (.colon, .colon),
             (.equals, .equals),
             (.identifier, .identifier),
             (.describe, .describe),
             (.make, .make),
             (.as, .as),
             (.of, .of),
             (.from, .from),
             (.if, .if),
             (.else, .else),
             (.while, .while),
             (.be, .be),
             (.return, .return),
             (.let, .let),
             (.`operator`, .`operator`),
             (.stringLiteral, .stringLiteral),
             (.booleanLiteral, .booleanLiteral),
             (.floatingPoint, .floatingPoint),
             (.decimal, .decimal),
             (.other, .other),
             (.prefixOperator, .prefixOperator),
             (.accessLimitation, .accessLimitation),
             (.static, .static):
            return lhs.payload == rhs.payload
        default:
            return false
        }
    }
}
