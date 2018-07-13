//
//  VariableMutation.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 03/07/2018.
//

import Foundation
public struct VariableMutation: Node {
    
    public let identifier: String
    public let expression: Expression
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        let validPrefix: [TokenType] = [ .make, .identifier, .be ]

        guard tokens.hasPrefixTypes(types: validPrefix) else {
            throw ZolangError.ErrorType.unexpectedStartOfStatement(.variableMutation)
        }
        
        self.identifier = tokens[1].payload!
        self.expression = try Expression(tokens: Array(tokens.suffix(from: validPrefix.count)), context: &context)
    }
}
