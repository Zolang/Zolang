//
//  StatementType.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

public enum StatementType {
    case modelDescription
    case variableDeclaration
    case functionDeclaration
    case variableMutation
    case functionMutation
    case expression
    case whileLoop
    case ifStatement
    case returnStatement
    case only
    case raw
}

extension StatementType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .raw: return "raw block"
        case .only: return "only block"
        case .ifStatement: return "if statement"
        case .modelDescription: return "model description"
        case .functionDeclaration: return "function declaration"
        case .functionMutation: return "function mutation"
        case .variableDeclaration: return "variable declaration"
        case .variableMutation: return "variable mutation"
        case .whileLoop: return "while loop"
        case .expression: return "expression"
        case .returnStatement: return "return statement"
        }
    }
    
    public var errorMessage: String {
        switch self {
        case .raw:
            return "Unexpected start of \(description) - expected raw {' <anything> '}"
        case .only:
            return "Unexpected start of \(description) - expected: only \"<flag1>\", \"<flag2>\",... { <code> }"
        case .expression:
            return "Unexpected start of \(description)"
        case .ifStatement:
            return "Unexpected start of \(description) - expected: if (<expression>) { <code> }\""
        case .modelDescription:
            return "Unexpected start of \(description) - expected: describe <model> { <descriptions> }"
        case .functionDeclaration:
            return "Unexpected start of \(description) - expected: let <identifier> return <type> from (<params>) { <code> }"
        case .functionMutation:
            return "Unexpected start of \(description) - expected: make <identifier> return <type> from (<params>) { <code> }"
        case .variableDeclaration:
            return "Unexpected start of \(description) - expected: let <variable> as <type> be <expression>"
        case .variableMutation:
            return "Unexpected start of \(description) - expected: make <name> be <expression>"
        case .whileLoop:
            return "Unexpected start of \(description) - expected: while (<expression>) { <code> }"
        case .returnStatement:
            return "Unexpected start of \(description) - expected: return <expression>"
        }
    }
}
