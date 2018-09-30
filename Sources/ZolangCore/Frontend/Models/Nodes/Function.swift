//
//  Function.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 30/06/2018.
//

import Foundation

public struct Function: Node {

    public let returnType: Type?
    public let params: ParamList?
    public let codeBlock: CodeBlock

    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        // {type} from {ParamList} { {code} }
        
        guard let fromIndex = tokens.index(of: [.from]) else {
            throw ZolangError(type: .missingToken("from"),
                              file: context.file,
                              line: context.line)
        }
        
        let typeTokens = Array(tokens.prefix(upTo: fromIndex))
        if typeTokens.filter({ $0.type != .newline }).isEmpty == false {
            self.returnType = try Type(tokens: typeTokens, context: &context)
        } else {
            self.returnType = nil
        }

        guard tokens.count > fromIndex + 1 else {
            throw ZolangError(type: .missingToken("("),
                              file: context.file,
                              line: context.line)
        }

        tokens = Array(tokens.suffix(from: fromIndex + 1))
        
        context.line += tokens.trimLeadingNewlines()
        
        guard tokens.hasPrefixTypes(types: [ .parensOpen ]) else {
            throw ZolangError(type: .missingToken("("),
                              file: context.file,
                              line: context.line)
        }
        
        guard let paramRange = tokens.rangeOfScope(open: .parensOpen, close: .parensClose) else {
            throw ZolangError(type: .missingMatchingParens,
                              file: context.file,
                              line: context.line)
        }
        
        context.line += tokens.newLineCount(to: paramRange.lowerBound)

        var paramTokens = Array(tokens[paramRange])
        
        if paramTokens.filter({ $0.type != .newline }).count <= 2 {
            self.params = nil
        } else {
            paramTokens = Array(paramTokens[1..<(paramTokens.count - 1)])
            self.params = try ParamList(tokens: paramTokens, context: &context)
        }
        
        guard tokens.count > paramRange.upperBound + 1,
            tokens.hasPrefixTypes(types: [ .curlyOpen ],
                                  skipping: [ .newline, .comment ],
                                  startingAt: paramRange.upperBound + 1) else {
            throw ZolangError(type: .missingToken("{"),
                              file: context.file,
                              line: context.line)
        }
        
        guard let codeRange = tokens.rangeOfScope(open: .curlyOpen, close: .curlyClose) else {
            throw ZolangError(type: .missingMatchingCurlyBracket,
                              file: context.file,
                              line: context.line)
        }
        
        var codeRangeTokens = Array(tokens[codeRange])
        
        context.line += tokens.newLineCount(to: codeRange.lowerBound, startingAt: paramRange.upperBound)

        if codeRangeTokens.filter({ $0.type != .newline }).count <= 2 {
            self.codeBlock = .empty
            context.line += codeRangeTokens.trimLeadingNewlines() + codeRangeTokens.trimTrailingNewlines()
        } else {
            self.codeBlock = try CodeBlock(tokens: Array(codeRangeTokens[1..<(codeRangeTokens.count - 1)]), context: &context)
        }
        
        context.line += tokens.trimTrailingNewlines()
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        var ctx = [
            "codeBlock": try codeBlock.compile(buildSetting: buildSetting, fileManager: fm)
        ]
        if let rType = returnType {
            ctx["returnType"] = try rType.compile(buildSetting: buildSetting, fileManager: fm)
        }
        if let paramList = params {
            ctx["params"] = try paramList.compile(buildSetting: buildSetting, fileManager: fm)
        }
        return ctx
    }
}
