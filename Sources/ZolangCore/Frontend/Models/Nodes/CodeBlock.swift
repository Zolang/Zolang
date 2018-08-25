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
        var workingTokens = tokens
        context.line += workingTokens.trimLeadingNewlines()
        
        guard let prefixType = workingTokens.prefixType() else {
            throw ZolangError(type: .unknown,
                              file: context.file,
                              line: context.line)
        }

        var left: CodeBlock
        
        var leftEndIndex: Int

        switch prefixType {
        case .expression:
            guard let range = workingTokens.rangeOfExpression() else {
                throw ZolangError(type: .invalidExpression,
                                  file: context.file,
                                  line: context.line)
            }
            leftEndIndex = range.upperBound + 1
            left = .expression(try Expression(tokens: workingTokens, context: &context))
        case .ifStatement:
            throw ZolangError.ErrorType.unknown
        case .modelDescription:
            throw ZolangError(type: .unexpectedToken(.describe, nil),
                              file: context.file,
                              line: context.line)
        case .variableDeclaration:
            guard let range = workingTokens.rangeOfVariableDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.variableDeclaration),
                                  file: context.file,
                                  line: context.line)
            }
            leftEndIndex = range.upperBound + 1
            left = .variableDeclaration(try VariableDeclaration(tokens: Array(workingTokens[range]), context: &context))
        case .variableMutation:
            guard let range = workingTokens.rangeOfVariableDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.variableDeclaration),
                                  file: context.file,
                                  line: context.line)
            }
            leftEndIndex = range.upperBound + 1
            left = .variableMutation(try VariableMutation(tokens: Array(workingTokens[range]), context: &context))
        case .whileLoop:
            throw ZolangError.ErrorType.unknown
        }
        
        guard leftEndIndex < workingTokens.count else {
            self = left
            return
        }
        
        context.line += workingTokens.newLineCount(to: leftEndIndex)
        
        do {
            let rest = Array(workingTokens.suffix(from: leftEndIndex))
            let right = try CodeBlock(tokens: rest, context: &context)
            self = .combination(left, right)
        } catch {
            throw ZolangError(type: .unknown,
                              file: context.file,
                              line: context.line)
        }
    }
}
