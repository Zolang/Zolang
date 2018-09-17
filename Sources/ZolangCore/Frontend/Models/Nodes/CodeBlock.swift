//
//  CodeBlock.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 30/06/2018.
//

import Foundation

public indirect enum CodeBlock: Node {
    case empty
    case expression(Expression)
    case variableDeclaration(VariableDeclaration)
    case variableMutation(VariableMutation)
    case functionDeclaration(FunctionDeclaration)
    case functionMutation(FunctionMutation)
    case ifStatement(IfStatement)
    case returnStatement(Expression)
    case whileLoop(Expression, CodeBlock)
    case combination(CodeBlock, CodeBlock)

    public init(tokens: [Token], context: inout ParserContext) throws {
        var workingTokens = tokens
        context.line += workingTokens.trimLeadingNewlines()
        
        guard workingTokens.isEmpty == false else {
            self = .empty
            return
        }
        
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
            context.line += workingTokens.newLineCount(to: range.lowerBound)

            left = .expression(try Expression(tokens: Array(workingTokens[range]), context: &context))
        case .ifStatement:
            guard let range = workingTokens.rangeOfIfStatement() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.ifStatement),
                                  file: context.file,
                                  line: context.line)
            }
            
            leftEndIndex = range.upperBound + 1
            context.line += workingTokens.newLineCount(to: range.lowerBound)
            
            left = .ifStatement(try IfStatement(tokens: Array(workingTokens[range]), context: &context))
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
            context.line += workingTokens.newLineCount(to: range.lowerBound)
            left = .variableDeclaration(try VariableDeclaration(tokens: Array(workingTokens[range]), context: &context))
        case .variableMutation:
            guard let range = workingTokens.rangeOfVariableDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.variableMutation),
                                  file: context.file,
                                  line: context.line)
            }
            leftEndIndex = range.upperBound + 1
            left = .variableMutation(try VariableMutation(tokens: Array(workingTokens[range]), context: &context))
        case .functionDeclaration:
            guard let range = workingTokens.rangeOfFunctionDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.functionDeclaration),
                                  file: context.file,
                                  line: context.line)
            }
            leftEndIndex = range.upperBound + 1
            context.line += workingTokens.newLineCount(to: range.lowerBound)
            left = .functionDeclaration(try FunctionDeclaration(tokens: Array(workingTokens[range]), context: &context))
        case .functionMutation:
            guard let range = workingTokens.rangeOfFunctionDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.functionMutation),
                                  file: context.file,
                                  line: context.line)
            }
            leftEndIndex = range.upperBound + 1
            left = .functionMutation(try FunctionMutation(tokens: Array(workingTokens[range]), context: &context))
        case .whileLoop:
            
            guard let expressionContainer = workingTokens.rangeOfScope(open: .parensOpen,
                                                                       close: .parensClose),
                let curlyRange = workingTokens.rangeOfScope(open: .curlyOpen,
                                                            close: .curlyClose),
                expressionContainer.count > 2 else {

                throw ZolangError(type: .unexpectedStartOfStatement(.whileLoop),
                                  file: context.file,
                                  line: context.line)
            }

            let expressionRange: ClosedRange<Int> = (expressionContainer.lowerBound + 1)...(expressionContainer.upperBound - 1)
            let expressionTokens = Array(workingTokens[expressionRange])

            context.line += workingTokens.newLineCount(to: expressionRange.lowerBound)

            let expression = try Expression(tokens: expressionTokens,
                                            context: &context)

            if curlyRange.count >= 2 {
                let codeRange: ClosedRange<Int> = (curlyRange.lowerBound + 1)...(curlyRange.upperBound - 1)
                let codeTokens = Array(workingTokens[codeRange])
                
                let code = try CodeBlock(tokens: codeTokens, context: &context)
                
                left = .whileLoop(expression, code)
            } else {
                left = .whileLoop(expression, .empty)
            }
            
            leftEndIndex = curlyRange.upperBound + 1
        case .returnStatement:
            let returnIndex = workingTokens.index(of: [ .return ])!
            
            guard returnIndex + 1 < workingTokens.count,
                let range = workingTokens.rangeOfExpression(),
                let expectedStartOfExpression = workingTokens.index(ofFirstThatIsNot: .newline,
                                                                    startingAt: returnIndex + 1),
                    expectedStartOfExpression == range.lowerBound else {
                throw ZolangError(type: .unexpectedStartOfStatement(.returnStatement),
                                  file: context.file,
                                  line: context.line)
            }
            
            leftEndIndex = range.upperBound + 1
            context.line += workingTokens.newLineCount(to: range.lowerBound)
            
            left = .returnStatement(try Expression(tokens: Array(workingTokens[range]), context: &context))
        }
        
        guard leftEndIndex < workingTokens.count else {
            self = left
            return
        }

        do {
            let rest = Array(workingTokens.suffix(from: leftEndIndex))
            let right = try CodeBlock(tokens: rest, context: &context)
            self = .combination(left, right)
        } catch {
            throw error
        }
    }
}