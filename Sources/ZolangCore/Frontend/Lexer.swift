//
//  Lexer.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

public struct Lexer {
    
    public func tokenize(string: String) -> [Token] {
        var tokens = [Token]()
        var content = string
        
        while (content.count > 0) {
            let matched = RegExRepo.tokenizers.first(where: { args -> Bool in
                let (regEx, _) = args
                return content.getPrefix(regex: regEx) != nil
            })
            
            if let tokenBuilder = matched {
                if let tokenStr = content.getPrefix(regex: tokenBuilder.key) {
                    content = content.offsetted(by: tokenStr.count)
                    
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
