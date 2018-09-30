//
//  FunctionMutation.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 03/07/2018.
//

import Foundation

public struct FunctionMutation: Node {
    public let identifiers: [String]
    public let newFunction: Function

    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        let validPrefix: [TokenType] = [ .make, .identifier ]
        
        func invalidMutationError(_ context: ParserContext) -> ZolangError {
            return ZolangError(type: .unexpectedStartOfStatement(.functionMutation),
                               file: context.file,
                               line: context.line)
        }
        
        guard tokens.hasPrefixTypes(types: validPrefix, skipping: [ .newline, .comment ]) else {
            throw invalidMutationError(context)
        }

        tokens.removeFirst()
        context.line += tokens.trimLeadingNewlines()
        
        var i = 0

        do {
            self.identifiers = (try tokens.parseSeparatedTokens(of: [ .identifier ],
                                                                separator: .dot,
                                                                skipping: [ .newline, .comment ],
                                                                i: &i))
                .compactMap { $0.first?.payload }
        } catch {
            throw invalidMutationError(context)
        }
        
        context.line += tokens.newLineCount(to: i)
        
        var newTokens = Array(tokens.suffix(from: i))
        let leading = newTokens.trimLeadingNewlines()
        context.line += leading

        guard newTokens[0] == .return else {
            throw invalidMutationError(context)
        }
        
        let rest = Array(newTokens.suffix(from: 1))

        self.newFunction = try Function(tokens: rest, context: &context)
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        return [
            "identifiers": self.identifiers,
            "function": try self.newFunction.compile(buildSetting: buildSetting, fileManager: fm)
        ]
    }
}
