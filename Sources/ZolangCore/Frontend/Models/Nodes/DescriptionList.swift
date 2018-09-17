//
//  DescriptionList.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 10/09/2018.
//

import Foundation

public struct DescriptionList: Node {
    
    public let properties: [(name: String, type: Type)]
    public let functions: [(name: String, function: Function)]
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        guard tokens.first?.type == .identifier else {
            throw ZolangError(type: .missingIdentifier,
                              file: context.file,
                              line: context.line)
        }
        
        var properties: [(String, Type)] = []
        var functions: [(String, Function)] = []

        var i = 0
        
        let trailingLines = tokens.trimTrailingNewlines()
        
        while i < tokens.count {
            let isPropertyDeclaration = tokens.hasPrefixTypes(types: [ .identifier, .as ],
                                                              skipping: [ .newline ],
                                                              startingAt: i)
            
            let isFunctionDeclaration = tokens.hasPrefixTypes(types: [ .identifier, .return ], skipping: [ .newline ], startingAt: i)
            
            guard isPropertyDeclaration
                || isFunctionDeclaration else {
                    throw ZolangError(type: .missingToken("as or return"),
                                      file: context.file,
                                      line: context.line)
            }
            
            let identifierIndex = tokens.index(of: [ .identifier], startingAt: i)!
            
            
            // For validation purposes
            let asOrReturnIndex = tokens.index(ofAnyIn: [.as, .return],
                                               skippingOnly: [ .newline, .identifier ],
                                               startingAt: identifierIndex)!
            let nameTokens = tokens[i...asOrReturnIndex].filter({
                $0.type != .newline && $0.type == .identifier
            })
            
            context.line += tokens.newLineCount(to: identifierIndex, startingAt: i)
            
            guard nameTokens.count == 1 else {
                throw ZolangError(type: nameTokens.isEmpty ? .missingIdentifier : .unexpectedToken(nameTokens[1], nil),
                                  file: context.file,
                                  line: context.line)
            }
            
            if isPropertyDeclaration {

                guard asOrReturnIndex + 1 < tokens.count,
                    let endOfType = DescriptionList.endOfTypePrefix(tokens: tokens,
                                                                    startingAt: asOrReturnIndex + 1) else {
                    throw ZolangError(type: .invalidType,
                                      file: context.file,
                                      line: context.line)
                }


                let typeTokens = Array(tokens[(asOrReturnIndex + 1)..<endOfType])
                
                context.line += tokens.newLineCount(to: asOrReturnIndex + 1,
                                                    startingAt: identifierIndex)

                let type = try Type(tokens: typeTokens, context: &context)
                
                let nextI = endOfType + 1
                context.line += tokens.newLineCount(to: nextI, startingAt: endOfType)
                
                properties.append((tokens[identifierIndex].payload!, type))
                
                i = nextI
            } else {
                let asOrReturnIndex = tokens.index(of: [ .return ])!
                
                let indexOfCurly = tokens.index(of: [ .curlyOpen ],
                                                skipping: [ .newline ],
                                                startingAt: asOrReturnIndex)
                
                guard asOrReturnIndex + 1 < tokens.count,
                    let range = tokens.rangeOfScope(start: asOrReturnIndex,
                                                    open: .curlyOpen,
                                                    close: .curlyClose) else {
                        throw ZolangError(type: indexOfCurly == nil ? .missingToken("{") : .missingMatchingCurlyBracket,
                                      file: context.file,
                                      line: context.line + tokens.newLineCount(to: indexOfCurly ?? asOrReturnIndex,
                                                                               startingAt: asOrReturnIndex))
                }

                context.line += tokens.newLineCount(to: asOrReturnIndex + 1,
                                                    startingAt: identifierIndex)
                let function = try Function(tokens: Array(tokens[(asOrReturnIndex + 1)...range.upperBound]),
                                            context: &context)
                
                functions.append((tokens[identifierIndex].payload!, function))
                
                i = range.upperBound + 1
            }
        }
        
        self.functions = functions
        self.properties = properties
        
        context.line += trailingLines
    }
    
    private static func endOfTypePrefix(tokens: [Token], startingAt: Int) -> Int? {

        guard let firstIndex = tokens.index(ofFirstThatIsNot: .newline, startingAt: startingAt),
            tokens[firstIndex].type == .identifier else {
                return nil
        }
        
        guard tokens[firstIndex].payload != "list" else {
            guard let i = tokens.index(of: [.of], skipping: [.newline], startingAt: firstIndex + 1),
                let firstNotNewline = tokens.index(ofFirstThatIsNot: .newline, startingAt: i + 1) else {
                    return nil
            }

            return endOfTypePrefix(tokens: tokens, startingAt: firstNotNewline)
        }
        
        return firstIndex + 1
    }
}
