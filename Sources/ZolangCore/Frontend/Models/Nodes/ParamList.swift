//
//  ParamList.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 07/09/2018.
//

import Foundation

public struct ParamList: Node {
    
    let params: [(name: String, type: Type)]
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        context.line += tokens.trimLeadingNewlines()
        
        var i = 0
        
        
        
        throw ZolangError.ErrorType.unknown
    }
}
