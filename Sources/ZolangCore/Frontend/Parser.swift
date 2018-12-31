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

    public func parse() throws -> AST {
        do {
            let code = try String(contentsOfFile: self.context.file)
            
            var tokens = code.zo.tokenize()
            
            // Return the AST
            var codeBlocks: AST = []

            while tokens.isEmpty == false {
                let block = try CodeBlock.parse(tokens: &tokens, context: &context)
                codeBlocks.append(block)
            }

            return codeBlocks

        } catch {
            throw error
        }
    }
}
