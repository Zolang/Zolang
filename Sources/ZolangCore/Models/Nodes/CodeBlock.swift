//
//  CodeBlock.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 30/06/2018.
//

import Foundation

indirect enum CodeBlock: Node {
    case expression(Expression)
    case variableDeclaration(VariableDeclaration)
    case variableMutation(VariableMutation)
    case ifStatement(IfStatement)
    case whileLoop(WhileLoop)
    case combination(CodeBlock, CodeBlock)
    
    init(tokens: [Token], context: inout ParserContext) throws {
        throw ZolangError.ErrorType.unknown
    }
}
