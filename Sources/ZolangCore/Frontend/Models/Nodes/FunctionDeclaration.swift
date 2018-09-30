//
//  FunctionDeclaration.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 09/09/2018.
//

import Foundation

public struct FunctionDeclaration: Node {
    public let identifier: String
    public let function: Function
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()

        let validPrefix: [TokenType] = [ .let, .identifier, .return ]
        
        guard tokens.hasPrefixTypes(types: validPrefix, skipping: [ .newline, .comment ]) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.functionDeclaration),
                              file: context.file,
                              line: context.line)
        }
        
        self.identifier = tokens.first(where: { $0.type == .identifier })!.payload!
        
        let returnIndex = tokens.index(of: [ .return ])!
        context.line += tokens.newLineCount(to: returnIndex)

        guard returnIndex + 1 < tokens.count else {
            throw ZolangError(type: .unexpectedStartOfStatement(.functionDeclaration),
                              file: context.file,
                              line: context.line)
        }

        let rest = Array(tokens.suffix(from: returnIndex + 1))
        self.function = try Function(tokens: rest, context: &context)
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        return [
            "identifier": identifier,
            "function": try self.function.compile(buildSetting: buildSetting, fileManager: fm)
        ]
    }
}
