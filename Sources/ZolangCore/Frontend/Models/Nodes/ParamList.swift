//
//  ParamList.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 07/09/2018.
//

import Foundation

public struct ParamList: Node {
    
    public let params: [(name: String, type: Type)]
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        self.params = try tokens.split(separator: .comma)
            .map(Array.init)
            .map { innerTokens -> (String, Type) in
                var innerTokens = innerTokens
                context.line += innerTokens.trimLeadingNewlines()

                guard let asIndex = innerTokens.index(of: [ .as ]) else {
                    throw ZolangError(type: .missingToken("as"),
                                      file: context.file,
                                      line: context.line)
                }
                
                let nameTokens = Array(innerTokens.prefix(upTo: asIndex))
                guard let nameIndex = nameTokens.index(of: [ .identifier ]) else {
                    throw ZolangError(type: .missingIdentifier,
                                      file: context.file,
                                      line: context.line)
                }
                
                context.line += innerTokens.newLineCount(to: nameIndex)

                guard nameTokens.filter({ $0.type != .newline }).count == 1 else {
                    throw ZolangError(type: .invalidParamDescription,
                                      file: context.file,
                                      line: context.line)
                }
                
                let name = nameTokens[nameIndex].payload!
                
                context.line += innerTokens.newLineCount(to: asIndex, startingAt: nameIndex)
                
                guard asIndex + 1 < innerTokens.count else {
                    throw ZolangError(type: .invalidType,
                                      file: context.file,
                                      line: context.line)
                }

                let typeTokens = Array(innerTokens.suffix(from: asIndex + 1))
                let type = try Type(tokens: typeTokens, context: &context)
                
                return (name, type)
            }
    }
}
