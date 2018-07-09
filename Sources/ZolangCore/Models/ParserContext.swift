//
//  ParserContext.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

final class ParserContext {
    let file: String

    var line: Int
    private(set) var scope: Scope
    private(set) var errorStack: [ZolangError]
    
    init(file: String, line: Int = 0, scope: Scope = Scope(), errorStack: [ZolangError] = []) {
        self.file = file
        self.line = line
        self.scope = scope
        self.errorStack = errorStack
    }
    
    func push(error: ZolangError) {
        errorStack.insert(error, at: 0)
    }
    
    func dumpErrorStack() {
        errorStack.forEach { err in
            print()
        }
    }
}
