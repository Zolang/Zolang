//
//  IfStatement.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 28/06/2018.
//

import Foundation

public struct IfStatement: Node {
    
    public let ifList: [(Expression, CodeBlock)]
    public let elseBlock: CodeBlock?
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var workingTokens = tokens
        context.line += workingTokens.trimLeadingNewlines()

        guard workingTokens.hasPrefixTypes(types: [.if, .parensOpen], skipping: [ .newline, .comment ]) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.ifStatement),
                              file: context.file,
                              line: context.line)
        }
        
        let (expression, exprRange) = try IfStatement.parseExpression(tokens: workingTokens, context: &context)
        let startOfCode = exprRange.upperBound + 1
        
        context.line += workingTokens.newLineCount(to: startOfCode)
        
        guard startOfCode < workingTokens.count else {
            throw ZolangError(type: .missingToken("{"),
                              file: context.file,
                              line: context.line)
        }

        let (ifCodeBlock, ifCodeEnd) = try IfStatement.parseCodeBlock(tokens: workingTokens,
                                                                      context: &context,
                                                                      startingAt: startOfCode)
        
        var ifTuples: [(Expression, CodeBlock)] = [ (expression, ifCodeBlock) ]

        if workingTokens.hasPrefixTypes(types: [ .else ],
                                        skipping: [.newline, .curlyClose, .comment ],
                                        startingAt: ifCodeEnd + 1) {

            let indexOfElse = workingTokens.index(ofNextWithTypeIn: [.else],
                                                  startingAt: ifCodeEnd + 1)!

            let elseIfExpressions = try IfStatement.parseElseIfs(tokens: Array(workingTokens.suffix(from: indexOfElse)),
                                                                 context: &context)
            ifTuples.append(contentsOf: elseIfExpressions)
            
            var startOfElseBlockStatement: Int

            if elseIfExpressions.isEmpty {
                startOfElseBlockStatement = indexOfElse
            } else {
                startOfElseBlockStatement = workingTokens.rangeOfScope(start: indexOfElse,
                                                                       open: .curlyOpen,
                                                                       close: .curlyClose)!.upperBound + 1
            }
            
            if let indexOfElseBlock = workingTokens.index(of: [ .else, .curlyOpen ],
                                                          skipping: [.newline, .comment ],
                                                          startingAt: startOfElseBlockStatement) {

                let (elseBlock, codeBlockEndIndex) = try IfStatement.parseCodeBlock(tokens: workingTokens,
                                                                                    context: &context,
                                                                                    startingAt: indexOfElseBlock)
                self.elseBlock = elseBlock
                
                context.line += workingTokens.newLineCount(to: indexOfElseBlock,
                                                           startingAt: startOfElseBlockStatement)

                if let validationIndex = workingTokens.index(of: [ .curlyOpen ],
                                                             skipping: [ .newline, .comment ],
                                                             startingAt: codeBlockEndIndex) {
                    var rest = Array(workingTokens.suffix(from: validationIndex))
                    
                    context.line += rest.trimLeadingNewlines()
                    guard rest.isEmpty else {
                        throw ZolangError(type: .unexpectedToken(rest[0], nil),
                                          file: context.file,
                                          line: context.line)
                    }
                }

            } else {
                guard workingTokens.hasPrefixTypes(types: [.else ],
                                                   skipping: [ .newline ],
                                                   startingAt: startOfElseBlockStatement) == false else {
                    let indexOfElse = workingTokens.index(of: [ .else ],
                                                          skipping: [ .newline ],
                                                          startingAt: startOfElseBlockStatement)!
                                                    
                    
                    throw ZolangError(type: .unexpectedToken(workingTokens[indexOfElse + 1], nil),
                                      file: context.file,
                                      line: context.line)
                }

                self.elseBlock = nil
            }
        } else {
            self.elseBlock = nil
        }
        
        self.ifList = ifTuples
        
    }
    
    private static func parseExpression(tokens: [Token], context: inout ParserContext) throws -> (Expression, ClosedRange<Int>) {
        guard tokens.index(ofAnyIn: [.parensOpen]) != nil else {
            throw ZolangError(type: .missingToken("("),
                              file: context.file,
                              line: context.line)
        }
        
        guard let rangeOfExpression = tokens.rangeOfScope(open: .parensOpen, close: .parensClose) else {
            throw ZolangError(type: .missingMatchingParens,
                              file: context.file,
                              line: context.line)
        }

        context.line += tokens.newLineCount(to: rangeOfExpression.lowerBound)

        return (try Expression(tokens: Array(tokens[rangeOfExpression]), context: &context), rangeOfExpression)
    }
    
    private static func parseCodeBlock(tokens: [Token],
                                context: inout ParserContext,
                                startingAt: Int) throws -> (CodeBlock, Int) {
        guard let rangeOfCodeBlock = tokens.rangeOfScope(start: startingAt,
                                                         open: .curlyOpen,
                                                         close: .curlyClose) else {
            throw ZolangError(type: .missingMatchingCurlyBracket,
                              file: context.file,
                              line: context.line)
        }
        
        guard rangeOfCodeBlock.count > 2 else {
            return (.empty, rangeOfCodeBlock.upperBound - 1)
        }
        
        let returnRange: ClosedRange<Int> = (rangeOfCodeBlock.lowerBound + 1)...(rangeOfCodeBlock.upperBound - 1)
        
        context.line += tokens.newLineCount(to: returnRange.lowerBound, startingAt: startingAt)
        return (try CodeBlock(tokens: Array(tokens[returnRange]),
                              context: &context), returnRange.upperBound)
    }
    
    private static func parseElseIfs(tokens: [Token], context: inout ParserContext) throws -> [(Expression, CodeBlock)] {

        guard tokens.hasPrefixTypes(types: [.else, .if, .parensOpen ], skipping: [ .newline ]) else {
            return []
        }

        let (expression, rangeOfExpression) = try parseExpression(tokens: tokens, context: &context)
        
        let startOfNext = rangeOfExpression.upperBound + 1

        guard startOfNext < tokens.count,
            tokens.hasPrefixTypes(types: [ .curlyOpen ],
                                  skipping: [ .newline ],
                                  startingAt: startOfNext) else {
            throw ZolangError(type: .missingToken("{"),
                              file: context.file,
                              line: context.line)
        }
        
        let (codeBlock, codeBlockEndIndex) = try parseCodeBlock(tokens: tokens,
                                                               context: &context,
                                                               startingAt: startOfNext)
        
        let tuplesToAdd = [ (expression, codeBlock) ]

        guard codeBlockEndIndex + 1 < tokens.count else {
            return tuplesToAdd
        }
        return tuplesToAdd + (try parseElseIfs(tokens: Array(tokens.suffix(from: codeBlockEndIndex + 1)),
                                               context: &context))
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String: Any] {
        let ifList = try self.ifList.map { arg -> [String: Any] in
            let (expression, block) = arg

            return [
                "expression": try expression.compile(buildSetting: buildSetting, fileManager: fm),
                "codeBlock": try block.compile(buildSetting: buildSetting, fileManager: fm)
            ]
        }
        
        var ctx: [String: Any] = [
            "ifList": ifList,
        ]
        
        if let elseBlock = self.elseBlock {
            ctx["elseBlock"] = elseBlock
        }
        return ctx
    }
}
