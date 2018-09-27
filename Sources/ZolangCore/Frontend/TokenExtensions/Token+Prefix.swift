//
//  Token+Prefix.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension Array where Element == Token {
    
    public func isPrefixModelDescription() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .describe
    }
    
    public func isPrefixVariableDeclaration() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .let
    }
    
    public func isPrefixVariableMutation() -> Bool {
        guard count > 3 else { return false }
        return self[0...1].map { $0.type } == [ .make, .identifier ]
    }
    
    public func isPrefixWhileLoop() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .while
    }
    
    public func isPrefixIfStatement() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .if
    }
    
    public func isPrefixReturnStatement() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .return
    }
    
    public func isPrefixExpression() -> Bool {
        guard let first = self.first else { return false }
        switch first.type {
        case .as,
             .be,
             .of,
             .bracketClose,
             .bracketOpen,
             .colon,
             .comma,
             .curlyClose,
             .curlyOpen,
             .describe,
             .equals,
             .from,
             .if,
             .else,
             .newline,
             .while,
             .let,
             .make,
             .parensClose,
             .other,
             .dot,
             .return,
             .operator,
             .accessLimitation,
             .static,
             .comment:
            return false
        case .prefixOperator:
            guard self.count > 1 else { return false }
            return Array(self[1...]).isPrefixExpression()
        case .identifier,
             .floatingPoint,
             .decimal,
             .textLiteral,
             .booleanLiteral,
             .parensOpen:
            return true
        }
    }
    
    public func prefixType() -> StatementType? {
        if isPrefixModelDescription() {
            return .modelDescription
        } else if isPrefixVariableDeclaration() {
            return .variableDeclaration
        } else if isPrefixWhileLoop() {
            return .whileLoop
        } else if isPrefixIfStatement() {
            return .ifStatement
        } else if isPrefixVariableMutation() {
            return .variableMutation
        } else if isPrefixExpression() {
            return .expression
        } else if isPrefixReturnStatement() {
            return .returnStatement
        } else {
            return nil
        }
    }
    
    public func isPrefixFunctionCall(skipping: [TokenType] = [], startingAt: Index = 0) -> Bool {
        guard count > 2 else { return false }
        let start = index(ofAnyIn: [.identifier], skippingOnly: skipping, startingAt: startingAt) ?? startingAt
        guard let end = index(ofFirstThatIsNot: .newline, startingAt: start + 1) else { return false }
        
        let array = self[start...end].map { $0.type }
            .filter { $0 != .newline }
        return array[0] == .identifier && array[1] == .parensOpen
    }
    
    public func isPrefixLiteral() -> Bool {
        guard !isEmpty else { return false }
        let valid: [TokenType] = [
            .textLiteral,
            .floatingPoint,
            .decimal
        ]
        return valid.contains(self[0].type)
    }
    
    public func getPrefix(to: Token) -> [Token] {
        
        var index = 0
        
        while index < self.count {
            if self[index] == to {
                return Array(self[0...index])
            }
            index += 1
        }
        
        return []
    }
}
