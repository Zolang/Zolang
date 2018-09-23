//
//  TypeDescription.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public struct ModelDescription: Node {
    public let name: String
    public let descriptionList: DescriptionList?
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        guard tokens.hasPrefixTypes(types: [ .describe, .identifier, .curlyOpen ],
                                    skipping: [ .newline ],
                                    startingAt: 0),
            let identifierIndex = tokens.index(of: [ .identifier ], skipping: [ .newline ]),
            let startOfScope = tokens.index(of: [ .curlyOpen ], skipping: [ .newline ]) else {
            throw ZolangError(type: .unexpectedStartOfStatement(.modelDescription),
                              file: context.file,
                              line: context.line)
        }
        
        self.name = tokens[identifierIndex].payload!
        
        context.line += tokens.newLineCount(to: startOfScope)
        
        guard let descriptionScopeRange = tokens.rangeOfScope(open: .curlyOpen,
                                                              close: .curlyClose) else {
            throw ZolangError(type: .missingMatchingCurlyBracket,
                              file: context.file,
                              line: context.line)
        }
        
        if descriptionScopeRange.count <= 2 {
            self.descriptionList = nil
        } else {
            let dlistRange = (descriptionScopeRange.lowerBound + 1)..<(descriptionScopeRange.upperBound - 1)
            let descListTokens = Array(tokens[dlistRange])
            context.line += tokens.newLineCount(to: dlistRange.lowerBound,
                                                startingAt: descriptionScopeRange.lowerBound)
            self.descriptionList = try DescriptionList(tokens: descListTokens, context: &context)
            context.line += tokens.newLineCount(to: descriptionScopeRange.upperBound,
                                                startingAt: dlistRange.upperBound)
        }
        
        context.line += tokens.trimTrailingNewlines()
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        var ctx = [
            "name": self.name,
        ]
        
        if let descriptionList = self.descriptionList {
            ctx["descriptionList"] = try descriptionList.compile(buildSetting: buildSetting, fileManager: fm)
        }
        
        return ctx
    }
}
