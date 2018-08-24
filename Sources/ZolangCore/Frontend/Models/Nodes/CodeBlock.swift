//
//  CodeBlock.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 30/06/2018.
//

import Foundation

public indirect enum CodeBlock: Node {
    case expression(Expression)
    case variableDeclaration(VariableDeclaration)
    case variableMutation(VariableMutation)
    case ifStatement(IfStatement)
    case whileLoop(WhileLoop)
    case combination(CodeBlock, CodeBlock)
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        let previousLine = context.line
        
        guard let prefixType = tokens.prefixType() else {
            throw ZolangError(type: .unknown,
                              file: context.file,
                              line: context.line)
        }

        var left: CodeBlock
        switch prefixType {
        case .expression:
            left = .expression(try Expression(tokens: tokens, context: &context))
        case .ifStatement:
            throw ZolangError.ErrorType.unknown
        case .modelDescription:
            throw ZolangError(type: .unexpectedToken(.describe, nil),
                              file: context.file,
                              line: context.line)
        case .variableDeclaration:
            left = .variableDeclaration(try VariableDeclaration(tokens: tokens, context: &context))
        case .variableMutation:
            left = .variableMutation(try VariableMutation(tokens: tokens, context: &context))
        case .whileLoop:
            throw ZolangError.ErrorType.unknown
        }
        
        let index = context.line - previousLine
        
        let line = context.line

        do {
            let right = try CodeBlock(tokens: Array(tokens.suffix(from: index)), context: &context)
            self = .combination(left, right)
        } catch {
            context.line = line
            self = left
        }
    }
}
