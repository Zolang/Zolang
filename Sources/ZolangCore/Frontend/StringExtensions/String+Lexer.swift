//
//  String+Lexer.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension String {
    
    public var zo: ZolangExtensions<String> {
        return ZolangExtensions(base: self)
    }
}

extension ZolangExtensions where Base == String {
    public func offsetted(by offset: Int) -> String {
        return "\(base[base.index(base.startIndex, offsetBy: offset)...])"
    }
    
    public func getPrefix(regex: String) -> String? {
        let expression = try! NSRegularExpression(pattern: "^\(regex)", options: [])
        
        let range = expression.rangeOfFirstMatch(in: base,
                                                 options: [],
                                                 range: NSRange(location: 0,
                                                                length: base.utf16.count))
        if range.location == 0 {
            return (base as NSString).substring(with: range)
        }
        return nil
    }
    
    public func tokenize() -> [Token] {
        var tokens = [Token]()
        var content = base
        
        while (content.count > 0) {
            let matched = RegExRepo.tokenizers.first(where: { args -> Bool in
                let (regEx, _) = args
                return content.zo.getPrefix(regex: regEx) != nil
            })
            
            if let tokenBuilder = matched {
                if let tokenStr = content.zo.getPrefix(regex: tokenBuilder.regEx) {
                    content = content.zo.offsetted(by: tokenStr.count)
                    
                    if let token = tokenBuilder.tokenizer(tokenStr) {
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
    
    public func getScope(open: String, close: String, start: Int) -> ClosedRange<Int>? {
        guard start < base.count else { return nil }
        
        var index = start
        var start = index
        var end = index
        
        var startCount = 0
        var closeCount = 0
        
        while index < base.count {
            let token = String(base[base.index(base.startIndex, offsetBy: index)])
            if token == open {
                if startCount == 0 {
                    start = index
                }
                startCount += 1
            } else if token == close {
                closeCount += 1
            }
            
            if startCount != 0 && startCount == closeCount {
                end = index
                break
            }
            
            index += 1
        }
        
        guard closeCount == startCount else { return nil }

        return start...end
    }
}
