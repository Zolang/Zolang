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
        
        tokens.removeFirst()
        context.line += tokens.trimLeadingNewlines()
        
        var i = 0
        
        do {
            self.identifiers = (try tokens.parseSeparatedTokens(of: [ .identifier ],
                                                                separator: .dot,
                                                                skipping: [ .newline ],
                                                                i: &i))
                .compactMap { $0.first?.payload }
        } catch {
            throw invalidStartOfExpression
        }
        
        context.line += tokens.newLineCount(to: i)
        
        guard tokens[i] == .be else {
            throw invalidStartOfExpression
        }

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
