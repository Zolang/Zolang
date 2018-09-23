//
//  Parser.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public class Parser {

    var context: ParserContext

    public init(file: URL) {
        self.context = ParserContext(file: file.path)
    }

    public func parse() throws -> CodeBlock {
        do {
            let code = try String(contentsOfFile: self.context.file)
            
            let tokens = code.zo.tokenize()
            
            // Return the AST
            return try CodeBlock(tokens: tokens, context: &self.context)
        } catch {
            throw error
        }
    }
}
