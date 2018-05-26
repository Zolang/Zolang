//
//  String+Lexer.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension String {
    public func offsetted(by offset: Int) -> String {
        return "\(self[self.index(self.startIndex, offsetBy: offset)...])"
    }
    
    public func getPrefix(regex: String) -> String? {
        let expression = try! NSRegularExpression(pattern: "^\(regex)", options: [])
        
        let range = expression.rangeOfFirstMatch(in: self,
                                                 options: [],
                                                 range: NSRange(location: 0,
                                                                length: utf16.count))
        if range.location == 0 {
            return (self as NSString).substring(with: range)
        }
        return nil
    }
}
