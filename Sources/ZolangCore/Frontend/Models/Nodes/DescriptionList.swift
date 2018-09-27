//
//  DescriptionList.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 10/09/2018.
//

import Foundation

public struct DescriptionList: Node {
    
    public let properties: [(isStatic: Bool, accessLimitation: String?, name: String, type: Type)]
    public let functions: [(isStatic: Bool, accessLimitation: String?, name: String, function: Function)]
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        guard tokens.first?.type == .identifier else {
            throw ZolangError(type: .missingIdentifier,
                              file: context.file,
                              line: context.line)
        }
        
        var properties: [(Bool, String?, String, Type)] = []
        var functions: [(Bool, String?, String, Function)] = []

        var i = 0
        
        let trailingLines = tokens.trimTrailingNewlines()
        
        while i < tokens.count {
            var isStatic = false
            let oldI = i
            var accessLimitation: String? = nil
            if tokens.hasPrefixTypes(types: [ .accessLimitation ],
                                     skipping: [ .newline ],
                                     startingAt: i) {
                let accessLimitationIndex = tokens.index(of: [ .accessLimitation ],
                                                         startingAt: i)!
                accessLimitation = tokens[accessLimitationIndex].payload!
                i = accessLimitationIndex + 1
            }
            
            if tokens.hasPrefixTypes(types: [ .static ],
                                     skipping: [ .newline ],
                                     startingAt: i) {
                isStatic = true
                i = tokens.index(of: [ .static ],
                                 startingAt: i)! + 1
            }
            
            // Validate...
            // Prevent further attributes (accessLimitations or static keyword)

            guard tokens.hasPrefixTypes(types: [ .accessLimitation ],
                                        skipping: [ .newline ],
                                        startingAt: i) == false else {
                let accessLimitationIndex = tokens.index(of: [ .accessLimitation ],
                                                         startingAt: i)!
                context.line += tokens.newLineCount(to: accessLimitationIndex, startingAt: oldI)
                throw ZolangError(type: .unexpectedToken(tokens[accessLimitationIndex], .identifier),
                                  file: context.file,
                                  line: context.line)
            }
            
            guard tokens.hasPrefixTypes(types: [ .static ],
                                        skipping: [ .newline ],
                                        startingAt: i) == false else {
                let staticIndex = tokens.index(of: [ .static ],
                                                         startingAt: i)!
                context.line += tokens.newLineCount(to: staticIndex, startingAt: oldI)
                throw ZolangError(type: .unexpectedToken(tokens[staticIndex], .identifier),
                                  file: context.file,
                                  line: context.line)
            }
            
            context.line += tokens.newLineCount(to: i, startingAt: oldI)
            
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
                
                properties.append((isStatic, accessLimitation, tokens[identifierIndex].payload!, type))
                
                i = nextI
            } else {
                let asOrReturnIndex = tokens.index(of: [ .return ], startingAt: i)!
                
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
                
                functions.append((isStatic, accessLimitation, tokens[identifierIndex].payload!, function))
                
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
        
        
        let staticProps = try properties
            .filter { $0.isStatic }
            .map { (arg) -> [String: Any] in
                let (_, accessLimitation, name, type) = arg
                var ctx: [String: Any] = [
                    "name": name,
                    "type": try type.compile(buildSetting: buildSetting, fileManager: fm)
                ]
                
                if let accessLimitation = accessLimitation {
                    ctx["accessLimitation"] = accessLimitation
                }
                
                return ctx
            }
        
        let props = try properties
            .map { (arg) -> [String: Any] in
                let (_, accessLimitation, name, type) = arg
                var ctx: [String: Any] = [
                    "name": name,
                    "type": try type.compile(buildSetting: buildSetting, fileManager: fm)
                ]
                
                if let accessLimitation = accessLimitation {
                    ctx["accessLimitation"] = accessLimitation
                }
                
                return ctx
        }
        
        let funcs = try functions
            .map { (_, accessLimitation, name, function) -> [String: Any] in
                var ctx: [String: Any] = [
                    "name": name,
                    "function": try function.compile(buildSetting: buildSetting, fileManager: fm)
                ]
                
                if let accessLimitation = accessLimitation {
                    ctx["accessLimitation"] = accessLimitation
                }
                
                return ctx
            }
        let staticFuncs = try functions
            .filter { $0.isStatic }
            .map { (_, accessLimitation, name, function) -> [String: Any] in
                var ctx: [String: Any] = [
                    "name": name,
                    "function": try function.compile(buildSetting: buildSetting, fileManager: fm)
                ]
                
                if let accessLimitation = accessLimitation {
                    ctx["accessLimitation"] = accessLimitation
                }
                
                return ctx
            }
        return [
            "staticProperties": staticProps,
            "properties": props,
            "staticFunctions": staticFuncs,
            "functions": funcs
        ]
    }
}
