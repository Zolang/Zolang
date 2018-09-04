//
//  Tokens+Helpers.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension Array where Element == Token {
    
    public func index(ofAnyIn set: [TokenType], skippingOnly: [TokenType]? = nil, startingAt: Index = 0) -> Index? {
        var index = startingAt
        
        let skipAllOther = skippingOnly == nil
        let skippingOnly = skippingOnly ?? []

        while index < endIndex {
            if set.contains(self[index].type) {
                return index
            } else if skipAllOther || skippingOnly.contains(self[index].type) {
                index += 1
            } else {
                return nil
            }
        }
        return nil
    }
    
    public func index(ofNextWithTypeIn set: [TokenType], startingAt: Index = 0) -> Index? {
        var index = startingAt
        while index < endIndex {
            if set.contains(self[index].type) {
                return index
            }
            index += 1
        }
        return nil
    }
    
    public func index(of set: [TokenType], skipping: [TokenType] = [], startingAt: Index = 0) -> Index? {
        var index = startingAt
        while index < endIndex {
            if self.hasPrefixTypes(types: set,
                                   skipping: skipping,
                                   startingAt: index) {
                return index
            }
            index += 1
        }
        return nil
    }
    
    public func index(ofStatementWithType type: StatementType) -> Index? {
        var index = 0
        
        while index < self.endIndex {
            if Array(self[index...]).prefixType() == type {
                return index
            }
            index += 1
        }
        return nil
    }
    
    public func index(ofFirstThatIsNot type: TokenType, startingAt: Index = 0) -> Index? {
        var index = startingAt
        while index < endIndex {
            let token = self[index]
            
            if token.type != type {
                return index
            }
            
            index += 1
        }
        return nil
    }
    
    public func rangeOfScope(start: Int = 0, open: Token, close: Token) -> ClosedRange<Int>? {
        guard start < count else { return nil }

        var index = start
        var start = index
        var end = index
        
        var startCount = 0
        var closeCount = 0
        
        while index < self.count {
            if self[index] == open {
                if startCount == 0 {
                    start = index
                }
                startCount += 1
            } else if self[index] == close {
                closeCount += 1
            }
            
            if startCount != 0 && startCount == closeCount {
                end = index
                break
            }
            
            index += 1
        }
        
        guard closeCount == startCount else { return nil }
        
        return start...end
    }
    
    public func indices(of tokenTypes: [TokenType], outsideOf scopeDefs: [(open: Token, close: Token)], startingAt: Int = 0) -> [Index]? {
        var indices: [Index] = []
        var i = startingAt
        
        while i < count {
            let token = self[i]
            
            
            if let scopeDef = scopeDefs.first(where: { $0.open == token }) {
                guard let range = rangeOfScope(start: i, open: scopeDef.open, close: scopeDef.close) else { return nil }
                i = range.upperBound + 1
            } else {
                if tokenTypes.contains(token.type) {
                    indices.append(i)
                }

                i += 1
            }
        }

        return indices
    }
    
    public func rangeOfDescribe() -> ClosedRange<Int>? {
        
        guard let startOfDescribe = index(ofStatementWithType: .modelDescription) else { return nil }
        
        guard let range = rangeOfScope(start: startOfDescribe,
                                       open: Token(type: .curlyOpen),
                                       close: Token(type: .curlyClose)) else { return nil }
        return startOfDescribe...range.upperBound
    }
    
    public func rangeOfFunctionCall() -> ClosedRange<Int>? {
        var index = 0
        while index < endIndex && !Array(self[index...]).isPrefixFunctionCall() {
            index += 1
        }
        
        guard let matchingParensRange = self.rangeOfScope(start: index,
                                                          open: .parensOpen,
                                                          close: .parensClose) else { return nil }
        return index...matchingParensRange.upperBound
    }
    
    public func rangeOfExpression() -> ClosedRange<Int>? {
        guard let start = index(ofStatementWithType: .expression) else { return nil }
        guard start < count else { return nil }
        
        let token = self[start]
        
        switch token.type {
        case .identifier, .floatingPoint, .decimal, .stringLiteral, .booleanLiteral:
            var startOfPeakNext = start + 1
            if isPrefixFunctionCall(startingAt: start) {
                
                if let range = rangeOfFunctionCall() {
                    startOfPeakNext = range.upperBound + 1
                }
                
            }
            
            guard let next = index(ofAnyIn: [ .dot, .operator],
                                   skippingOnly: [ .newline ],
                                   startingAt: startOfPeakNext),
                let nextNext = index(ofFirstThatIsNot: .newline,
                                     startingAt: next + 1),
                let nextExpressionRange = Array(self[nextNext...])
                    .rangeOfExpression() else {
                        
                        return start...(startOfPeakNext - 1)
            }
            
            return start...(nextNext + nextExpressionRange.upperBound)
            
        case .parensOpen:
            guard let rangeOfScope = self.rangeOfScope(start: start,
                                                       open: .parensOpen,
                                                       close: .parensClose) else {
                                                        return nil
            }
            
            guard let next = index(ofAnyIn: [ .dot, .operator],
                                   skippingOnly: [ .newline ],
                                   startingAt: rangeOfScope.upperBound),
                let nextNext = index(ofFirstThatIsNot: .newline,
                                     startingAt: next + 1),
                let nextExpressionRange = Array(self[nextNext...])
                    .rangeOfExpression() else {
                        
                        return rangeOfScope
            }
            
            return start...(nextNext + nextExpressionRange.upperBound)
        default:
            return nil
        }
        
    }
    
    public func rangeOfVariableDeclarationOrMutation() -> ClosedRange<Int>? {
        
        guard let declarationStart = self.index(ofAnyIn: [.make, .let]),
            let declarationEndIndex = self.index(ofAnyIn: [.be]),
            (declarationEndIndex + 1) < self.count else { return nil }
        
        let expressionStart = Array(self.suffix(from: declarationEndIndex + 1))
        guard let expressionRange = expressionStart
            .rangeOfExpression() else {
            return nil
        }
        return declarationStart...(declarationEndIndex + expressionRange.lowerBound + expressionRange.count)
    }
    
    public func rangeOfIfStatement() -> ClosedRange<Int>? {
        guard let declarationStart = self.index(ofStatementWithType: .ifStatement) else {
            return nil
        }
        
        func _rangeOfBlockSequence(startingAt: Int) -> ClosedRange<Int>? {
            let working = Array(self.suffix(from: startingAt))
            guard let codeBlockRange = working.rangeOfScope(open: .curlyOpen,
                                                            close: .curlyClose) else {
                return nil
            }
            
            let endOfIfStatement = codeBlockRange.upperBound
            
            guard let startOfElse = working.index(ofNextWithTypeIn: [ .else ],
                                                  startingAt: endOfIfStatement) else {
                return declarationStart...(startingAt + endOfIfStatement)
            }

            if let rangeOfNext = _rangeOfBlockSequence(startingAt: startingAt + startOfElse) {
                return declarationStart...rangeOfNext.upperBound
            } else {
                return declarationStart...(startingAt + endOfIfStatement)
            }
        }
        
        guard let upper = _rangeOfBlockSequence(startingAt: declarationStart)?.upperBound else {
            return nil
        }
        
        return declarationStart...upper
    }
    
    public func hasPrefixTypes(types: [TokenType], skipping: [TokenType] = [], startingAt: Int = 0) -> Bool {
        assert(types.isEmpty == false)
        guard startingAt < count else { return false }

        var types = types
        var i = startingAt
        while i < count && types.isEmpty == false {
            defer { i += 1 }
            
            let tokenType = self[i].type
            guard skipping.contains(tokenType) == false else { continue }
            
            let type = types.removeFirst()
            guard tokenType == type else { return false }
        }

        guard types.isEmpty else { return false }
        return true
    }

    public func newLineCount(to index: Index, startingAt: Index = 0) -> Int {
        guard index < self.count && startingAt < self.count && startingAt < index else {
            return 0
        }

        var count = 0
        var i = startingAt
        while i < index {
            if self[i].type == .newline {
                count += 1
            }
            i += 1
        }
        return count
    }
    
    @discardableResult
    public mutating func trimNewlines(to index: Index) -> Int {
        assert(index < self.count)
        var count = 0
        var i = 0
        while i < index {
            if self[i].type == .newline {
                count += 1
                remove(at: i)
            } else {
                i += 1
            }
        }
        return count
    }

    @discardableResult
    public mutating func trimLeadingNewlines() -> Int {
        var i = 0
        while first?.type == .newline {
            remove(at: 0)
            i += 1
        }
        return i
    }
    
    @discardableResult
    public mutating func trimTrailingNewlines() -> Int {
        var i = 0
        while last?.type == .newline {
            removeLast(1)
            i += 1
        }
        return i
    }
}
