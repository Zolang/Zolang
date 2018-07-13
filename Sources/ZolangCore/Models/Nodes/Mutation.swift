//
//  VariableMutation.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 28/06/2018.
//

import Foundation

public enum Mutation: Node {
    case variableMutation(VariableMutation)
    case functionMutation(FunctionMutation)

    public init(tokens: [Token], context: inout ParserContext) throws {
        guard tokens.isEmpty == false else {
            throw ZolangError
                .ErrorType
                .missingToken(Token.make.type.rawValue)
        }
        
        let nonFunctionPrefix: [TokenType] = [ .make, .identifier, .be ]
        let functionPrefix: [TokenType] = [ .make, .identifier, .return ]
        
        assert(nonFunctionPrefix.count == functionPrefix.count)
        guard tokens.prefix(nonFunctionPrefix.count)
            .contains(where: { $0.type == .newline }) == false else {
                throw ZolangError.ErrorType.unexpectedNewline(.variableMutation)
        }
        
        if tokens.hasPrefixTypes(types: functionPrefix) {
            self = .functionMutation(try FunctionMutation(tokens: tokens, context: &context))
        } else if tokens.hasPrefixTypes(types: nonFunctionPrefix) {
            self = .variableMutation(try VariableMutation(tokens: tokens, context: &context))
            
        } else {
            throw ZolangError
                .ErrorType
                .unexpectedStartOfStatement(.variableMutation)
        }
    }
}
