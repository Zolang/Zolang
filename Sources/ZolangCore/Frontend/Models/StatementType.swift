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
    case comment
}

extension StatementType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .comment: return "comment"
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
}
