//
//  Type.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public enum PrimitiveType: String {
    case text
    case number
    case boolean
}

public indirect enum Type: Node {
    case primitive(PrimitiveType)
    case list(Type)
    case custom(String)
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        guard tokens.isEmpty == false else {
            throw ZolangError(type: .invalidType,
                              file: context.file,
                              line: context.line)
        }
        
        guard tokens.hasPrefixTypes(types: [ .identifier ]) else {
            throw ZolangError(type: .unexpectedToken(tokens[0], TokenType.identifier),
                              file: context.file,
                              line: context.line)
        }
        
        guard tokens.filter({ $0.type != .newline }).count != 1 else {
            defer { context.line += tokens.trimTrailingNewlines() }

            guard let prim = PrimitiveType(rawValue: tokens[0].payload!) else {
                self = .custom(tokens[0].payload!)
                return
            }
            self = .primitive(prim)
            return
        }

        guard let ofIndex = tokens.index(of: [ .of ]),
            tokens.first(where: { $0.type == .identifier})?.payload == "list" else {
            throw ZolangError(type: .invalidType,
                              file: context.file,
                              line: context.line)
        }
        
        guard ofIndex + 1 < tokens.count else {
            throw ZolangError(type: .invalidType,
                              file: context.file,
                              line: context.line + tokens.newLineCount(to: ofIndex))
        }
        
        context.line += tokens.newLineCount(to: ofIndex)
        
        let rest = Array(tokens.suffix(from: ofIndex + 1))

        self = .list(try Type(tokens: rest, context: &context))
    }
    
    public func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String : Any] {
        switch self {
        case .custom(let str):
            return [
                "type": "custom",
                "stringValue": str
            ]
        case .primitive(let prim):
            return [
                "type": "primitive",
                "primitiveType": prim.rawValue
            ]
        case .list(let inner):
            return [
                "type": "list",
                "innerType": try inner.compile(buildSetting: buildSetting, fileManager: fm)
            ]
        }
    }
}

extension Type: Equatable {
    public static func == (lhs: Type, rhs: Type) -> Bool {
        switch (lhs, rhs) {
        case (.primitive(let l), .primitive(let r)): return l == r
        case (.list(let lt), .list(let rt)): return lt == rt
        case (.custom(let ls), .custom(let rs)): return ls == rs
        default: return false
        }
    }
}
