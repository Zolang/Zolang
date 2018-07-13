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
}
