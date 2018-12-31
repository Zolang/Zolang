//
//  CodeBlock.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 30/06/2018.
//

import Foundation
import Stencil
import PathKit

public indirect enum CodeBlock: Node {
    case empty
    case expression(Expression)
    case variableDeclaration(VariableDeclaration)
    case variableMutation(VariableMutation)
    case modelDescription(ModelDescription)
    case functionDeclaration(FunctionDeclaration)
    case functionMutation(FunctionMutation)
    case ifStatement(IfStatement)
    case returnStatement(Expression)
    case whileLoop(Expression, CodeBlock)
    case only(Only)
    case raw(String)
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
        case .raw:
            let raw: String = workingTokens.first!.payload!
            let range = raw.range(of: "{'")!
            
            let suffix = String(raw.suffix(from: range.upperBound))
            let innerRaw = String(suffix.prefix(upTo: suffix.range(of: "'}")!.lowerBound))
            
            context.line += raw.filter { $0 == "\n" }.count
            
            left = .raw(innerRaw)
            leftEndIndex = 1
        case .only:
            guard let range = workingTokens.rangeOfOnly() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.only),
                                  file: context.file,
                                  line: context.line)
            }
            leftEndIndex = range.upperBound + 1
            context.line += workingTokens.newLineCount(to: range.lowerBound)
            
            left = .only(try Only(tokens: Array(workingTokens[range]), context: &context))
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
            guard workingTokens.hasPrefixTypes(types: [.describe, .identifier, .curlyOpen], skipping: [.newline]) else {
                throw ZolangError(type: .unexpectedStartOfStatement(.modelDescription),
                                  file: context.file,
                                  line: context.line)
            }
            
            let curlyIndex = workingTokens.index(ofAnyIn: [ .curlyOpen ])!
            context.line += workingTokens.newLineCount(to: curlyIndex)
            guard let blockRange = workingTokens.rangeOfScope(open: .curlyOpen, close: .curlyClose) else {
                throw ZolangError(type: .missingMatchingCurlyBracket,
                                  file: context.file,
                                  line: context.line)
            }
            
            leftEndIndex = blockRange.upperBound + 1
            
            let descr = try ModelDescription(tokens: Array(workingTokens[0...blockRange.upperBound]), context: &context)
            left = .modelDescription(descr)
            
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
                expressionContainer.upperBound < curlyRange.lowerBound,
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

    public static func parse(tokens: inout [Token], context: inout ParserContext) throws -> CodeBlock {
        context.line += tokens.trimLeadingNewlines()
        
        guard tokens.isEmpty == false else {
            return .empty
        }
        
        guard let prefixType = tokens.prefixType() else {
            throw ZolangError(type: .unknown,
                              file: context.file,
                              line: context.line)
        }
        
        var codeBlock: CodeBlock
        var blockEndIndex: Int
        
        switch prefixType {
        case .raw:
            let raw: String = tokens.first!.payload!
            let range = raw.range(of: "{'")!
            
            let suffix = String(raw.suffix(from: range.upperBound))
            let innerRaw = String(suffix.prefix(upTo: suffix.range(of: "'}")!.lowerBound))
            
            context.line += raw.filter { $0 == "\n" }.count
            
            codeBlock = .raw(innerRaw)
            blockEndIndex = 1
        case .only:
            guard let range = tokens.rangeOfOnly() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.only),
                                  file: context.file,
                                  line: context.line)
            }
            blockEndIndex = range.upperBound + 1
            context.line += tokens.newLineCount(to: range.lowerBound)
            
            codeBlock = .only(try Only(tokens: Array(tokens[range]), context: &context))
        case .expression:
            guard let range = tokens.rangeOfExpression() else {
                throw ZolangError(type: .invalidExpression,
                                  file: context.file,
                                  line: context.line)
            }
            blockEndIndex = range.upperBound + 1
            context.line += tokens.newLineCount(to: range.lowerBound)
            
            codeBlock = .expression(try Expression(tokens: Array(tokens[range]), context: &context))
        case .ifStatement:
            guard let range = tokens.rangeOfIfStatement() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.ifStatement),
                                  file: context.file,
                                  line: context.line)
            }
            
            blockEndIndex = range.upperBound + 1
            context.line += tokens.newLineCount(to: range.lowerBound)
            
            codeBlock = .ifStatement(try IfStatement(tokens: Array(tokens[range]), context: &context))
        case .modelDescription:
            guard tokens.hasPrefixTypes(types: [.describe, .identifier, .curlyOpen], skipping: [.newline]) else {
                throw ZolangError(type: .unexpectedStartOfStatement(.modelDescription),
                                  file: context.file,
                                  line: context.line)
            }
            
            let curlyIndex = tokens.index(ofAnyIn: [ .curlyOpen ])!
            context.line += tokens.newLineCount(to: curlyIndex)
            guard let blockRange = tokens.rangeOfScope(open: .curlyOpen, close: .curlyClose) else {
                throw ZolangError(type: .missingMatchingCurlyBracket,
                                  file: context.file,
                                  line: context.line)
            }
            
            blockEndIndex = blockRange.upperBound + 1
            
            let descr = try ModelDescription(tokens: Array(tokens[0...blockRange.upperBound]), context: &context)
            codeBlock = .modelDescription(descr)
            
        case .variableDeclaration:
            guard let range = tokens.rangeOfVariableDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.variableDeclaration),
                                  file: context.file,
                                  line: context.line)
            }
            blockEndIndex = range.upperBound + 1
            context.line += tokens.newLineCount(to: range.lowerBound)
            codeBlock = .variableDeclaration(try VariableDeclaration(tokens: Array(tokens[range]), context: &context))
        case .variableMutation:
            guard let range = tokens.rangeOfVariableDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.variableMutation),
                                  file: context.file,
                                  line: context.line)
            }
            blockEndIndex = range.upperBound + 1
            codeBlock = .variableMutation(try VariableMutation(tokens: Array(tokens[range]), context: &context))
        case .functionDeclaration:
            guard let range = tokens.rangeOfFunctionDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.functionDeclaration),
                                  file: context.file,
                                  line: context.line)
            }
            blockEndIndex = range.upperBound + 1
            context.line += tokens.newLineCount(to: range.lowerBound)
            codeBlock = .functionDeclaration(try FunctionDeclaration(tokens: Array(tokens[range]), context: &context))
        case .functionMutation:
            guard let range = tokens.rangeOfFunctionDeclarationOrMutation() else {
                throw ZolangError(type: .unexpectedStartOfStatement(.functionMutation),
                                  file: context.file,
                                  line: context.line)
            }
            blockEndIndex = range.upperBound + 1
            codeBlock = .functionMutation(try FunctionMutation(tokens: Array(tokens[range]), context: &context))
        case .whileLoop:
            
            guard let expressionContainer = tokens.rangeOfScope(open: .parensOpen,
                                                                       close: .parensClose),
                let curlyRange = tokens.rangeOfScope(open: .curlyOpen,
                                                            close: .curlyClose),
                expressionContainer.upperBound < curlyRange.lowerBound,
                expressionContainer.count > 2 else {
                    
                    throw ZolangError(type: .unexpectedStartOfStatement(.whileLoop),
                                      file: context.file,
                                      line: context.line)
            }
            
            let expressionRange: ClosedRange<Int> = (expressionContainer.lowerBound + 1)...(expressionContainer.upperBound - 1)
            let expressionTokens = Array(tokens[expressionRange])
            
            context.line += tokens.newLineCount(to: expressionRange.lowerBound)
            
            let expression = try Expression(tokens: expressionTokens,
                                            context: &context)
            
            if curlyRange.count >= 2 {
                let codeRange: ClosedRange<Int> = (curlyRange.lowerBound + 1)...(curlyRange.upperBound - 1)
                let codeTokens = Array(tokens[codeRange])
                
                let code = try CodeBlock(tokens: codeTokens, context: &context)
                
                codeBlock = .whileLoop(expression, code)
            } else {
                codeBlock = .whileLoop(expression, .empty)
            }
            
            blockEndIndex = curlyRange.upperBound + 1
        case .returnStatement:
            let returnIndex = tokens.index(of: [ .return ])!
            
            guard returnIndex + 1 < tokens.count,
                let range = tokens.rangeOfExpression(),
                let expectedStartOfExpression = tokens.index(ofFirstThatIsNot: .newline,
                                                                    startingAt: returnIndex + 1),
                expectedStartOfExpression == range.lowerBound else {
                    throw ZolangError(type: .unexpectedStartOfStatement(.returnStatement),
                                      file: context.file,
                                      line: context.line)
            }
            
            blockEndIndex = range.upperBound + 1
            context.line += tokens.newLineCount(to: range.lowerBound)
            
            codeBlock = .returnStatement(try Expression(tokens: Array(tokens[range]), context: &context))
        }
        
        guard blockEndIndex < tokens.count else {
            tokens = []
            return codeBlock
        }
        
        tokens = Array(tokens.suffix(from: blockEndIndex))
        return codeBlock
    }
    
    public func compile(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> String {
        switch self {
        case .empty:
            return ""
        case .combination(let code1, let code2):
            let compiled1 = try code1.compile(buildSetting: buildSetting, fileManager: fm)
            let compiled2 = try code2.compile(buildSetting: buildSetting, fileManager: fm)
            
            guard let separator = buildSetting.separators[CodeBlock.stencilName] else {
                throw ConfigError.missingSeparator(CodeBlock.stencilName)
            }

            return [ compiled1, compiled2 ]
                .joined(separator: separator)
        case .modelDescription(let modelDescription):
            return try modelDescription.compile(buildSetting: buildSetting, fileManager: fm)
        case .expression(let expression):
            return try expression.compile(buildSetting: buildSetting, fileManager: fm)
        case .functionDeclaration(let decl):
            return try decl.compile(buildSetting: buildSetting, fileManager: fm)
        case .ifStatement(let statement):
            return try statement.compile(buildSetting: buildSetting, fileManager: fm)
        case .returnStatement(let expr):
            let nodeName = "ReturnStatement"
            
            
            let environment = Environment()
            let templateString = try CompilationEnvironment
                .template(buildSetting: buildSetting,
                          nodeName: nodeName)
            
            let context = [
                "expression": try expr.compile(buildSetting: buildSetting, fileManager: fm)
            ]
            return try environment.renderTemplate(string: templateString,
                                                  context: context)
                .zo.trimmed()
        case .variableDeclaration(let decl):
            return try decl.compile(buildSetting: buildSetting, fileManager: fm)
        case .functionMutation(let mut):
            return try mut.compile(buildSetting: buildSetting, fileManager: fm)
        case .variableMutation(let mut):
            return try mut.compile(buildSetting: buildSetting, fileManager: fm)
        case .only(let only):
            return try only.compile(buildSetting:buildSetting, fileManager: fm)
        case .whileLoop(let expr, let codeBlock):
            let context = [
                "expression": try expr.compile(buildSetting: buildSetting, fileManager: fm),
                "codeBlock": try codeBlock.compile(buildSetting: buildSetting, fileManager: fm)
            ]
            
            let environment = Environment()
            let templateString = try CompilationEnvironment
                .template(buildSetting: buildSetting,
                          nodeName: "WhileLoop")

            return try environment.renderTemplate(string: templateString,
                                                  context: context)
                .zo
                .trimmed()
        case .raw(let str):
            return str
        }
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        assertionFailure("CodeBlock has its own version of compile and should not need a getContext implementation")
        return [:]
    }
}
