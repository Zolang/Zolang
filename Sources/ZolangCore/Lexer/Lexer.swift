//
//  Lexer.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

public struct Lexer {
    public let string: String
    
    public func tokenize() -> [Token] {
        var tokens = [Token]()
        var content = self.string
        
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
    
    public init(string: String) {
        self.string = string
    }
}
