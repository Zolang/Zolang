//
//  ZolangError+Type.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 03/07/2018.
//

import Foundation

extension ZolangError {
    public enum ErrorType: Error {
        case unexpectedToken(Token, TokenType?)
        case unexpectedStartOfStatement(StatementType)
        case unexpectedNewline(StatementType)
        case missingToken(String)
        case missingMatchingCurlyBracket
        case missingMatchingBracket
        case missingMatchingParens
        case missingIdentifier
        case invalidExpression
        case invalidType
        case invalidParamDescription
        case unknown
        
        var localizedDescription: String {
            switch self {
            case .missingIdentifier:
                return "Missing identifier"
            case .missingMatchingCurlyBracket:
                return "Missing matching }"
            case .missingMatchingBracket:
                return "Missing matching ]"
            case .missingMatchingParens:
                return "Missing matching )"
            case .invalidExpression:
                return "Invalid expression"
            case .invalidType:
                return "Invalid type"
            case .invalidParamDescription:
                return "Invalid parameter description - expected: <identifier> as <type>"
            case .unexpectedToken(let token, let expectedType):
                let unexpectedTypeStr = "Unexpected type: \(token.type)"
                let expectedStr = expectedType != nil ? "- Expected: \(expectedType!)" : ""
                return "\(unexpectedTypeStr) \(expectedStr)"
            case .unexpectedStartOfStatement(let statementType):
                return statementType.errorMessage
            case .unexpectedNewline(let statementType):
                return "Unexpected newline found in \(statementType.description)"
            case .missingToken(let string):
                return "Missing token \"\(string)\""
            case .unknown:
                return "Unknown error"
            }
        }
    }
}
