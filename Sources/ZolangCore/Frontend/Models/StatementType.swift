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
    case variableMutation
    case expression
    case whileLoop
    case ifStatement
}

extension StatementType {
    var nodeType: Node.Type {
        switch self {
        case .modelDescription:
            return ModelDescription.self
        case .variableDeclaration:
            return VariableDeclaration.self
        case .variableMutation:
            return VariableMutation.self
        case .whileLoop:
            return WhileLoop.self
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
        case .variableDeclaration: return "variable declaration"
        case .variableMutation: return "variable mutation"
        case .whileLoop: return "while loop"
        case .expression: return "expression"
        }
    }
}
