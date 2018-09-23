//
//  VariableDeclaration.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 27/06/2018.
//

import Foundation

public struct VariableDeclaration: Node {

    public let identifier: String
    public let type: Type
    public let expression: Expression

    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()

        let validPrefix: [TokenType] = [ .let, .identifier, .as ]
        
        guard tokens.hasPrefixTypes(types: validPrefix) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.variableDeclaration),
                              file: context.file,
                              line: context.line)
        }
        
        self.identifier = tokens[1].payload!
        
        guard let typeEnd = DescriptionList.endOfTypePrefix(tokens: tokens, startingAt: validPrefix.count) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.variableDeclaration),
                              file: context.file,
                              line: context.line)
        }
        
        let typeTokens = Array(tokens[validPrefix.count..<typeEnd])

        self.type = try Type(tokens: typeTokens, context: &context)

        let rest = Array(tokens.suffix(from: typeEnd))
        
        context.line += tokens.newLineCount(to: typeEnd)
        
        guard rest.hasPrefixTypes(types: [.be]) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.variableDeclaration),
                              file: context.file,
                              line: context.line)
        }
        
        guard let range = rest.rangeOfExpression() else {
            throw ZolangError(type: .invalidExpression,
                              file: context.file,
                              line: context.line)
        }
        
        context.line += rest.newLineCount(to: range.lowerBound)
        
        let expressionTokens = Array(rest[range])
        self.expression = try Expression(tokens: expressionTokens, context: &context)
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        return [
            "identifier": self.identifier,
            "type": try self.type.compile(buildSetting: buildSetting, fileManager: fm),
            "expression": try self.expression.compile(buildSetting: buildSetting, fileManager: fm)
        ]
    }
}
