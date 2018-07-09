//
//  Parser.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

struct Parser {
    enum Result {
        case success([Node])
        case warning(ParserContext)
        case error([ZolangError])
    }

    let context: ParserContext

    init(file: String) {
        self.context = ParserContext(file: file)
    }

    func parse(tokens: [Token]) -> Result {
        
        return .warning(context)
    }
}
