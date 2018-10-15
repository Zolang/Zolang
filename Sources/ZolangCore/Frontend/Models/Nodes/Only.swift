//
//  Only.swift
//  ZolangCore
//
//  Created by Thorvaldur Runarsson on 14/10/2018.
//

import Foundation

public struct Only: Node {
    
    public let flags: [String]
    public let codeBlock: CodeBlock
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        defer {
            context.line += tokens.trimTrailingNewlines()
        }
        
        guard tokens.hasPrefixTypes(types: [.only], skipping: [.newline]),
            let blockRange = tokens.rangeOfScope(start: 1, open: .curlyOpen, close: .curlyClose),
            tokens.count > 3 else {
            throw ZolangError(type: .unexpectedStartOfStatement(.only),
                              file: context.file,
                              line: context.line)
        }
        
        let flagRange = 1...(blockRange.lowerBound - 1)
        
        let flags = Array(tokens[flagRange])
            .filter { $0.type != .comma }
        
        guard flags.filter({ $0.type != .textLiteral}).isEmpty else {
            throw ZolangError(type: .unexpectedStartOfStatement(.only),
                              file: context.file,
                              line: context.line)
        }
        
        self.flags = flags.compactMap { $0.payload }
        
        guard blockRange.count > 2 else {
            self.codeBlock = .empty
            return
        }
        
        let codeRange = (blockRange.lowerBound + 1)...(blockRange.upperBound - 1)
        
        self.codeBlock = try CodeBlock(tokens: Array(tokens[codeRange]), context: &context)
    }
    
    public func compile(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> String {
        // if buildSetting flags don't contain any of the flags then return as if no code was here
        guard Set(buildSetting.flags).intersection(flags).isEmpty == false else {
            return ""
        }

        return try codeBlock.compile(buildSetting: buildSetting, fileManager: fm)
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        fatalError("Invalid code path reached")
    }
}
