//
//  Token+Prefix.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension Array where Element == Token {
    
    private func isPrefixModelDescription() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .describe
    }
    
    private func isPrefixVariableDeclaration() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .let
    }
    
    private func isPrefixVariableMutation() -> Bool {
        guard count > 2 else { return false }
        return self[0...2].map { $0.type } == [ .make, .identifier, .be ]
    }
    
    func isPrefixWhileLoop() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .while
    }
    
    func isPrefixIfStatement() -> Bool {
        guard let first = self.first else { return false }
        return first.type == .if
    }
    
    func isPrefixExpression() -> Bool {
        guard let first = self.first else { return false }
        switch first.type {
        case .as,
             .be,
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
             .newline,
             .return,
             .while,
             .let,
             .make,
             .parensClose,
             .other,
             .dot:
            return false
        case .operator:
            guard self.count > 1 else { return false }
            return (first.payload == "-" || first.payload == "!") && Array(self[1...]).isPrefixExpression()
        case .identifier,
             .floatingPoint,
             .decimal,
             .stringLiteral,
             .parensOpen:
            return true
        }
    }
    
    func prefixType() -> StatementType? {
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
        } else {
            return nil
        }
    }
    
    func isPrefixFunctionCall(skipping: [TokenType] = [], startingAt: Index = 0) -> Bool {
        guard count > 2 else { return false }
        let start = index(ofAnyIn: [.identifier], skippingOnly: skipping, startingAt: startingAt) ?? startingAt
        guard let end = index(ofFirstThatIsNot: .newline, startingAt: start + 1) else { return false }
        
        let array = self[start...end].map { $0.type }
        return array[start] == .identifier && array[end] == .parensOpen
    }
    
    func isPrefixLiteral() -> Bool {
        guard !isEmpty else { return false }
        let valid: [TokenType] = [
            .stringLiteral,
            .floatingPoint,
            .decimal
        ]
        return valid.contains(self[0].type)
    }
    
    func getPrefix(to: Token) -> [Token] {
        
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
