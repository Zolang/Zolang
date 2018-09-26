//
//  DescriptionList.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 10/09/2018.
//

import Foundation

public struct DescriptionList: Node {
    
    public let properties: [(isStatic: Bool, name: String, accessLimitation: String?, type: Type)]
    public let functions: [(isStatic: Bool, name: String, accessLimitation: String?, function: Function)]
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()

        var properties: [(Bool, String, String?, Type)] = []
        var functions: [(Bool, String, String?, Function)] = []

        var i = 0
        
        let trailingLines = tokens.trimTrailingNewlines()
        
        while i < tokens.count {
            var isStatic = false
            if tokens.hasPrefixTypes(types: [ .static ],
                                     skipping: [ .newline ],
                                     startingAt: i) {
                isStatic = true
                i = tokens.index(of: [ .static ], startingAt: i)! + 1
            }
            
            context.line += tokens.trimLeadingNewlines()
            
            let isPublicPropertyDeclaration = tokens
                .hasPrefixTypes(types: [ .identifier, .as ],
                                skipping: [ .newline ],
                                startingAt: i)

            let isLimitedPropertyDeclaration = tokens
                .hasPrefixTypes(types: [ .identifier, .accessLimitation, .as ],
                                skipping: [ .newline ],
                                startingAt: i)
            
            let isPropertyDeclaration = isPublicPropertyDeclaration || isLimitedPropertyDeclaration
            
            let isPublicFunctionDeclaration = tokens
                .hasPrefixTypes(types: [ .identifier, .return ],
                                skipping: [ .newline ],
                                startingAt: i)
            let isLimitedFunctionDeclaration = tokens
                .hasPrefixTypes(types: [ .identifier, .accessLimitation, .return ],
                                skipping: [ .newline ],
                                startingAt: i)
            
            let isFunctionDeclaration = isPublicFunctionDeclaration || isLimitedFunctionDeclaration
            
            guard isPropertyDeclaration
                || isFunctionDeclaration else {
                    throw ZolangError(type: .missingToken("as or return"),
                                      file: context.file,
                                      line: context.line)
            }
            
            let identifierIndex = tokens.index(of: [ .identifier], startingAt: i)!
            
            let accessLimitationIndex = tokens.index(ofAnyIn: [.accessLimitation],
                                                     skippingOnly: [ .newline, .identifier ],
                                                     startingAt: identifierIndex)
            
            let asOrReturnIndex = tokens.index(ofAnyIn: [.as, .return],
                                               skippingOnly: [ .newline, .identifier, .accessLimitation ],
                                               startingAt: identifierIndex)!

            // For validation purposes
            // - check for invalid number of identifiers and accessLimitations
            
            let accessLimitations = tokens[i...asOrReturnIndex].filter({
                $0.type == .accessLimitation
            })

            let nameTokens = tokens[i...asOrReturnIndex].filter({
                $0.type == .identifier
            })
            
            let lineCountToIdentifierIndex = tokens.newLineCount(to: identifierIndex, startingAt: i)
            
            guard nameTokens.count == 1 else {
                throw ZolangError(type: nameTokens.isEmpty ? .missingIdentifier : .unexpectedToken(nameTokens[1], nil),
                                  file: context.file,
                                  line: context.line + lineCountToIdentifierIndex)
            }
            
            let lineCountToAccessLimitation = tokens
                .newLineCount(to: accessLimitationIndex != nil ? accessLimitationIndex! : i,
                              startingAt: i)

            guard accessLimitations.count <= 1 else {
                throw ZolangError(type: nameTokens.isEmpty ? .missingIdentifier : .unexpectedToken(accessLimitations[1], nil),
                                  file: context.file,
                                  line: context.line + lineCountToAccessLimitation)
            }
            
            context.line += tokens.newLineCount(to: asOrReturnIndex, startingAt: i)
            
            if isPropertyDeclaration {

                guard asOrReturnIndex + 1 < tokens.count,
                    let endOfType = DescriptionList.endOfTypePrefix(tokens: tokens,
                                                                    startingAt: asOrReturnIndex + 1) else {
                    throw ZolangError(type: .invalidType,
                                      file: context.file,
                                      line: context.line)
                }

                let typeTokens = Array(tokens[(asOrReturnIndex + 1)..<endOfType])

                let type = try Type(tokens: typeTokens, context: &context)
                
                let nextI = endOfType + 1
                context.line += tokens.newLineCount(to: nextI, startingAt: endOfType)
                
                let tupleToAppend: (isStatic: Bool, name: String, accessLimitation: String?, type: Type) = (
                    isStatic,
                    tokens[identifierIndex].payload!,
                    accessLimitationIndex != nil ? tokens[accessLimitationIndex!].payload! : nil,
                    type
                )

                properties.append(tupleToAppend)
                
                i = nextI
            } else {
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
                
                let tupleToAppend: (isStatic: Bool, name: String, accessLimitation: String?, function: Function) = (
                    isStatic,
                    tokens[identifierIndex].payload!,
                    accessLimitationIndex != nil ? tokens[accessLimitationIndex!].payload! : nil,
                    function
                )

                functions.append(tupleToAppend)
                
                i = range.upperBound + 1
            }
        }
        
        self.functions = functions
        self.properties = properties
        
        context.line += trailingLines
    }
    
    static func endOfTypePrefix(tokens: [Token], startingAt: Int) -> Int? {

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
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        let props = try properties.map { (arg) -> [String: Any] in
            let (isStatic, name, accessLimitation, type) = arg

            var ctx: [String: Any] = [
                "name": name,
                "isStatic": isStatic,
                "type": try type.compile(buildSetting: buildSetting, fileManager: fm)
            ]
            
            if let accessLimitation = accessLimitation {
                ctx["accessLimitation"] = accessLimitation
            }

            return ctx
        }
        
        let funcs = try functions.map { (isStatic, name, accessLimitation, function) -> [String: Any] in
            var ctx: [String: Any] = [
                "name": name,
                "isStatic": isStatic,
                "function": try function.compile(buildSetting: buildSetting, fileManager: fm)
            ]
            
            if let accessLimitation = accessLimitation {
                ctx["accessLimitation"] = accessLimitation
            }

            return ctx
        }
        return [
            "properties": props,
            "functions": funcs
        ]
    }
}
