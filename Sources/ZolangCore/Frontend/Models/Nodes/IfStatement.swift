//
//  IfStatement.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 28/06/2018.
//

import Foundation

public struct IfStatement: Node {
    
    let ifList: [(Expression, CodeBlock)]
    let elseBlock: CodeBlock?
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var workingTokens = tokens
        context.line += workingTokens.trimLeadingNewlines()

        guard workingTokens.hasPrefixTypes(types: [.if, .parensOpen], skipping: [.newline]) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.ifStatement),
                              file: context.file,
                              line: context.line)
        }
        
        let (expression, exprRange) = try IfStatement.parseExpression(tokens: workingTokens, context: &context)
        let startOfCode = exprRange.upperBound + 1
        
        guard startOfCode < workingTokens.count else {
            throw ZolangError(type: .missingToken("{"),
                              file: context.file,
                              line: context.line)
        }
        
        let (ifCodeBlock, ifCodeRange) = try IfStatement.parseCodeBlock(tokens: workingTokens,
                                                                        context: &context,
                                                                        startingAt: startOfCode)
        
        var ifTuples: [(Expression, CodeBlock)] = [ (expression, ifCodeBlock) ]

        if workingTokens.hasPrefixTypes(types: [ .else ],
                                        skipping: [.newline, .curlyClose],
                                        startingAt: ifCodeRange.upperBound + 1) {
            let indexOfElse = workingTokens.index(ofNextWithTypeIn: [.else],
                                                  startingAt: ifCodeRange.upperBound + 1)!
            let elseIfExpressions = try IfStatement.parseElseIfs(tokens: Array(workingTokens.suffix(from: indexOfElse)),
                                                                 context: &context)
            ifTuples.append(contentsOf: elseIfExpressions)
            
            var startOfElseBlockStatement: Int
            if elseIfExpressions.isEmpty {
                startOfElseBlockStatement = indexOfElse
            } else {
                startOfElseBlockStatement = workingTokens.rangeOfScope(start: indexOfElse,
                                                                       open: .curlyOpen,
                                                                       close: .curlyClose)!.upperBound
            }
            
            if let indexOfElseBlock = workingTokens.index(of: [ .else, .curlyOpen ],
                                                     skipping: [.newline ],
                                                     startingAt: startOfElseBlockStatement) {
                let (elseBlock, rangeOfElseCode) = try IfStatement.parseCodeBlock(tokens: workingTokens,
                                                                                   context: &context,
                                                                                   startingAt: indexOfElseBlock)
                self.elseBlock = elseBlock
                
                if let validationIndex = workingTokens.index(of: [.curlyOpen],
                                                             skipping: [.newline],
                                                             startingAt: rangeOfElseCode.upperBound) {
                    var rest = Array(workingTokens.suffix(from: validationIndex))
                    
                    context.line += rest.trimLeadingNewlines()
                    guard rest.isEmpty else {
                        throw ZolangError(type: .unexpectedToken(rest[0], nil),
                                          file: context.file,
                                          line: context.line)
                    }
                }

            } else {
                self.elseBlock = nil
            }
        } else {
            self.elseBlock = nil
        }
        
        self.ifList = ifTuples
        
    }
    
    private static func parseExpression(tokens: [Token], context: inout ParserContext) throws -> (Expression, ClosedRange<Int>) {
        guard let indexOfParensOpen = tokens.index(ofAnyIn: [.parensOpen]) else {
            throw ZolangError(type: .missingToken("("),
                              file: context.file,
                              line: context.line)
        }
        
        context.line += tokens.newLineCount(to: indexOfParensOpen)
        
        guard let rangeOfExpression = tokens.rangeOfScope(open: .parensOpen, close: .parensClose) else {
            throw ZolangError(type: .missingMatchingParens,
                              file: context.file,
                              line: context.line)
        }
        
        context.line += tokens.newLineCount(to: rangeOfExpression.lowerBound,
                                            startingAt: indexOfParensOpen)
        
        return (try Expression(tokens: Array(tokens[rangeOfExpression]), context: &context), rangeOfExpression)
    }
    
    private static func parseCodeBlock(tokens: [Token],
                                context: inout ParserContext,
                                startingAt: Int) throws -> (CodeBlock, ClosedRange<Int>) {
        guard let rangeOfCodeBlock = tokens.rangeOfScope(start: startingAt,
                                                         open: .curlyOpen,
                                                         close: .curlyClose) else {
            throw ZolangError(type: .missingMatchingCurlyBracket,
                              file: context.file,
                              line: context.line)
        }
        
        guard rangeOfCodeBlock.count > 2 else {
            return (.empty, (rangeOfCodeBlock.lowerBound + 1)...(rangeOfCodeBlock.upperBound - 1))
        }
        
        let returnRange: ClosedRange<Int> = (rangeOfCodeBlock.lowerBound + 1)...(rangeOfCodeBlock.upperBound - 1)
        
        context.line += tokens.newLineCount(to: rangeOfCodeBlock.lowerBound, startingAt: startingAt)
        return (try CodeBlock(tokens: Array(tokens[returnRange]),
                              context: &context), returnRange)
    }
    
    private static func parseElseIfs(tokens: [Token], context: inout ParserContext) throws -> [(Expression, CodeBlock)] {
        var workingTokens = tokens
        context.line = workingTokens.trimLeadingNewlines()

        guard workingTokens.hasPrefixTypes(types: [.else, .if, .parensOpen ], skipping: [ .newline ]) else {
            return []
        }

        let (expression, rangeOfExpression) = try parseExpression(tokens: workingTokens, context: &context)
        
        let startOfNext = rangeOfExpression.upperBound + 1

        guard startOfNext < workingTokens.count,
            workingTokens.hasPrefixTypes(types: [ .curlyOpen ],
                                         skipping: [ .newline ],
                                         startingAt: startOfNext) else {
            throw ZolangError(type: .missingToken("{"),
                              file: context.file,
                              line: context.line)
        }
        
        let (codeBlock, rangeOfCodeBlock) = try parseCodeBlock(tokens: workingTokens,
                                                               context: &context,
                                                               startingAt: startOfNext)
        
        let tuplesToAdd = [ (expression, codeBlock) ]

        guard rangeOfCodeBlock.upperBound + 1 < workingTokens.count else {
            return tuplesToAdd
        }
        return tuplesToAdd + (try parseElseIfs(tokens: Array(workingTokens.suffix(from: rangeOfCodeBlock.upperBound + 1)),
                                               context: &context))
    }
}
