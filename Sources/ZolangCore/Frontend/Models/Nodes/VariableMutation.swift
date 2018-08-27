//
//  VariableMutation.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 03/07/2018.
//

import Foundation

public struct VariableMutation: Node {
    
    public let identifiers: [String]
    public let expression: Expression
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()

        let validPrefix: [TokenType] = [ .make, .identifier ]
        let invalidStartOfExpression = ZolangError(type: .unexpectedStartOfStatement(.variableMutation),
                                                   file: context.file,
                                                   line: context.line)

        guard tokens.hasPrefixTypes(types: validPrefix) else {
            throw invalidStartOfExpression
        }
        
        guard tokens.count > 3 else {
            throw invalidStartOfExpression
        }
        
        var identifiers: [String] = [tokens[1].payload!]
        var i = 2
        var stateIsDot = false

        while tokens[i].type == .identifier || tokens[i].type == .dot {
            if tokens[i].type == .dot {
                guard stateIsDot == false else {
                    throw invalidStartOfExpression
                }
                stateIsDot = true
            } else {
                guard stateIsDot == true else {
                    throw invalidStartOfExpression
                }
                stateIsDot = false
                identifiers.append(tokens[i].payload!)
            }
            i += 1
        }
        
        guard tokens[i - 1].type != .dot && tokens[i].type == .be else {
            throw invalidStartOfExpression
        }
        
        self.identifiers = identifiers
        let rest = Array(tokens.suffix(from: i + 1))
        guard let range = rest.rangeOfExpression() else {
            throw ZolangError(type: .invalidExpression,
                              file: context.file,
                              line: context.line)
        }
        
        context.line += rest.newLineCount(to: range.lowerBound)
        
        let expressionTokens = Array(rest[range])
        self.expression = try Expression(tokens: expressionTokens, context: &context)
    }
}
