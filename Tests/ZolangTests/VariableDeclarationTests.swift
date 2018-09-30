//
//  VariableDeclarationTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 23/08/2018.
//

import Foundation
import XCTest
import ZolangCore

class VariableDeclarationTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testFailure() {
        var context = ParserContext(file: "test.zolang")
        
        let invalidSamples: [String] = [
            "let some \n be something",
            "let \n some be something",
            "let some. be something",
            "let some..another be something",
            "let some some be something",
            "let some.some. be something",
            "make some.some. be something"
        ]
        
        let tokens = invalidSamples
            .map { $0.zo.tokenize() }
        
        for tokenList in tokens {
            do {
                _ = try VariableMutation(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {}
        }
    }
    
    func testVariableDeclaration() {
        
        let samples: [(String, Int)] = [
            ("let some as text be \n something", 2),
            ("let some as number be \n\nsomething", 3),
            ("let some as Person be Person(\"John\", 5)", 1)
        ]
        
        samples
            .forEach { code, lineAtEnd in
                var context = ParserContext(file: "test.zolang")
                do {
                    try VariableDeclaration(tokens: code.zo.tokenize(),
                                            context: &context)
                    XCTAssert(context.line == lineAtEnd)
                    
                } catch {
                    XCTFail()
                }
            }
    }
}
