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
}

extension StatementType {
    var nodeType: Node.Type {
        switch self {
        case .modelDescription:
            return ModelDescription.self
        case .variableDeclaration:
            return VariableDeclaration.self
        case .functionDeclaration:
            return FunctionDeclaration.self
        case .functionMutation:
            return FunctionMutation.self
        case .variableMutation:
            return VariableMutation.self
        case .whileLoop,
             .returnStatement:
            return CodeBlock.self//return WhileLoop.self
        case .ifStatement:
            return IfStatement.self
        case .expression:
            return Expression.self
        }
    }
}

extension StatementType: CustomStringConvertible {
    public var description: String {
        switch self {
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
