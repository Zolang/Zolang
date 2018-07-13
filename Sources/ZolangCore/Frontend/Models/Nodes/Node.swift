//
//  Node.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 27/06/2018.
//

import Foundation

public protocol Node {
    init(tokens: [Token], context: inout ParserContext) throws
}
