//
//  Node.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

indirect enum SyntaxTree: Node {
    case modelDescription(ModelDescription)
    case codeBlock(CodeBlock)
    case combination(SyntaxTree, SyntaxTree)

    init(tokens: [Token], context: inout ParserContext) throws {
        throw ZolangError.ErrorType.unknown
    }
}
