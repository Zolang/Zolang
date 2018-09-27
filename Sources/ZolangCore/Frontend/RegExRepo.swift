//
//  RegExRepo.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

public typealias RegEx = String
public typealias Tokenizer = (String) -> Token?

public enum RegExRepo {
    public static let label = "[a-zA-Z_$][a-zA-Z0-9_$]*"
    
    public static let colon = ":"
    public static let comma = ","
    public static let dot = "\\."
    public static let equals = "\\="
    
    public static let parensOpen = "\\("
    public static let parensClose = "\\)"
    public static let bracketOpen = "\\["
    public static let bracketClose = "\\]"
    public static let curlyOpen = "\\{"
    public static let curlyClose = "\\}"
    
    public static let string = "\\\"(\\$\\{.*\\}|(\\\\.|[^\\\"\\\\]))*\\\""//"\\\"([^\\\\\\\"]|\\\\\\\"|\\\\\\\\)*\\\""
    public static let decimal = "\\d+"
    public static let floatingPoint = "\(decimal)\(dot)\(decimal)"
    
    public static let inlineWhitespaceCharacter = "[\\s\\t]"
    public static let newline = "\n"
    
    public static let prefixOperator = "not|-"
    public static let `operator` = "or|and|equals|(<=)|(>=)|<|>|plus|minus|times|over"
    
    public static let accessLimitation = "private"

    public static let boolean = "true|false"
    public static let keyword = "describe|make|return|while|from|let|as|be|of|if|else|static"
}

extension RegExRepo {
    public static let tokenizers: [RegEx: Tokenizer] = [
        RegExRepo.inlineWhitespaceCharacter: { _ in nil },
        RegExRepo.newline: { _ in Token(type: .newline) },
        
        RegExRepo.accessLimitation: { return Token(type: .accessLimitation, payload: $0) },
        
        RegExRepo.prefixOperator: { return Token(type: .prefixOperator, payload: $0) },
        RegExRepo.`operator`: { return Token(type: .`operator`, payload: $0) },
        
        RegExRepo.label: {
            if let boolean = $0.zo.getPrefix(regex: RegExRepo.boolean) {
                return Token(type: .booleanLiteral, payload: boolean)
            } else if let keyword = $0.zo.getPrefix(regex: RegExRepo.keyword),
                let token = Token.keyword(keyword) {
                return token
            } else {
                return Token(type: .identifier, payload: $0)
            }
        },
        RegExRepo.string: { payload in
            let start = payload.index(after: payload.startIndex)
            let end = payload.index(before: payload.endIndex)

            return Token(type: .textLiteral, payload: String(payload[start..<end]))
        },
        RegExRepo.floatingPoint: { Token(type: .floatingPoint, payload: $0) },
        RegExRepo.decimal: { Token(type: .decimal, payload: $0) },
        
        RegExRepo.comma: { _ in Token(type: .comma) },
        RegExRepo.colon: { _ in Token(type: .colon) },
        RegExRepo.dot: { _ in Token(type: .dot) },
        RegExRepo.equals: { _ in Token(type: .equals) },
        
        RegExRepo.parensOpen: { _ in Token(type: .parensOpen) },
        RegExRepo.parensClose: { _ in Token(type: .parensClose) },
        RegExRepo.curlyOpen: { _ in Token(type: .curlyOpen) },
        RegExRepo.curlyClose: { _ in Token(type: .curlyClose) },
        RegExRepo.bracketOpen: { _ in Token(type: .bracketOpen) },
        RegExRepo.bracketClose: { _ in Token(type: .bracketClose) }
    ]
}
