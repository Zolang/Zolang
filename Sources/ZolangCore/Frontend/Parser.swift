//
//  Parser.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public struct Parser {

    var context: ParserContext

    public init(file: String) {
        self.context = ParserContext(file: file)
    }

    public mutating func parse(tokens: [Token]) throws -> CodeBlock {
        do {
            let code = try String(contentsOfFile: self.context.file)
            
            let tokens = self.tokenize(string: code)
            
            // Return the AST
            return try CodeBlock(tokens: tokens, context: &self.context)
        } catch {
            throw error
        }
    }
    
    public func tokenize(string: String) -> [Token] {
        var tokens = [Token]()
        var content = string
        
        while (content.count > 0) {
            let matched = RegExRepo.tokenizers.first(where: { args -> Bool in
                let (regEx, _) = args
                return content.zo.getPrefix(regex: regEx) != nil
            })
            
            if let tokenBuilder = matched {
                if let tokenStr = content.zo.getPrefix(regex: tokenBuilder.key) {
                    content = content.zo.offsetted(by: tokenStr.count)
                    
                    if let token = tokenBuilder.value(tokenStr) {
                        tokens.append(token)
                    }
                }
            } else {
                let index = content.index(content.startIndex, offsetBy: 1)
                tokens.append(Token(type: .other, payload: "\(content[..<index])"))
                content = "\(content[index...])"
            }
        }
        return tokens
    }
}
