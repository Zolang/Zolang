//
//  VariableDeclaration.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 27/06/2018.
//

import Foundation

public struct VariableDeclaration: Node {

    public let identifier: String
    public let expression: Expression

    public init(tokens: [Token], context: inout ParserContext) throws {
        let validPrefix: [TokenType] = [ .let, .identifier, .be ]
        
        guard tokens.hasPrefixTypes(types: validPrefix) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.variableMutation),
                              file: context.file,
                              line: context.line)
        }
        
        self.identifier = tokens[1].payload!
        self.expression = try Expression(tokens: Array(tokens.suffix(from: validPrefix.count)), context: &context)
    }
    
}
