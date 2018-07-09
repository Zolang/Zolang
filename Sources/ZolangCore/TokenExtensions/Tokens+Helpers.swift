//
//  Tokens+Helpers.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension Array where Element == Token {
    
    func index(ofAnyIn set: [TokenType], skippingOnly: [TokenType] = [], startingAt: Index = 0) -> Index? {
        var index = startingAt
        while index < endIndex {
            if set.contains(self[index].type) {
                return index
            } else if skippingOnly.contains(self[index].type) {
                index += 1
            } else {
                return nil
            }
        }
        return nil
    }
    
    func index(ofNextWithTypeIn set: [TokenType], startingAt: Index = 0) -> Index? {
        var index = startingAt
        while index < endIndex {
            if set.contains(self[index].type) {
                return index
            }
            index += 1
        }
        return nil
    }
    
    func index(ofStatementWithType type: StatementType) -> Index? {
        var index = 0
        
        while index < self.endIndex {
            if Array(self[index...]).prefixType() == type {
                return index
            }
            index += 1
        }
        return nil
    }
    
    func index(ofFirstThatIsNot type: TokenType, startingAt: Index = 0) -> Index? {
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
    
    func rangeOfScope(start: Int = 0, open: Token, close: Token) -> ClosedRange<Int>? {
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
    
    func rangeOfDescribe() -> ClosedRange<Int>? {
        
        guard let startOfDescribe = index(ofStatementWithType: .modelDescription) else { return nil }
        
        guard let range = rangeOfScope(start: startOfDescribe,
                                       open: Token(type: .curlyOpen),
                                       close: Token(type: .curlyClose)) else { return nil }
        return startOfDescribe...range.upperBound
    }
    
    func rangeOfFunctionCall() -> ClosedRange<Int>? {
        var index = 0
        while index < endIndex && !Array(self[index...]).isPrefixFunctionCall() {
            index += 1
        }
        
        guard let matchingParensRange = self.rangeOfScope(start: index,
                                                          open: .parensOpen,
                                                          close: .parensClose) else { return nil }
        return index...matchingParensRange.upperBound
    }
    
    func rangeOfExpression() -> ClosedRange<Int>? {
        guard let start = index(ofStatementWithType: .expression) else { return nil }
        guard count - start > 0 else { return nil }
        
        let token = self[start]
        
        switch token.type {
        case .identifier, .floatingPoint, .decimal, .stringLiteral:
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
                        
                        return start...start
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
    
    func hasPrefixTypes(types: [TokenType]) -> Bool {
        guard types.count <= count else { return false }
        return self.prefix(upTo: types.count)
            .map { $0.type } == types
    }
    
    func newLineCount(to index: Index) -> Int {
        assert(index < self.count)
        var count = 0
        var i = 0
        while i < index {
            if self[i].type == .newline {
                count += 1
            }
            i += 1
        }
        return count
    }
}
