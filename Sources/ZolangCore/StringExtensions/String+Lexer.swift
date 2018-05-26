//
//  String+Lexer.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

public extension Base where T == String {
    public func offsetted(by offset: Int) -> String {
        let str = self.t
        return "\(str[str.index(str.startIndex, offsetBy: offset)...])"
    }
    
    public func getPrefix(regex: String) -> String? {
        let str = self.t
        let expression = try! NSRegularExpression(pattern: "^\(regex)", options: [])
        
        let range = expression.rangeOfFirstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))
        if range.location == 0 {
            return (str as NSString).substring(with: range)
        }
        return nil
    }
}
