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
            .map(Lexer().tokenize(string:))
        
        for tokenList in tokens {
            do {
                _ = try VariableMutation(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {}
        }
    }
    
    func testVariableDeclaration() {
        var context = ParserContext(file: "test.zolang")
        
        let samples: [String] = [
            "let some be \n something",
            "let some be \n\nsomething"
        ]
        
        samples
            .map(Lexer().tokenize(string:))
            .forEach { tokens in
                do {
                    _ = try VariableDeclaration(tokens: tokens,
                                                context: &context)
                    
                } catch {
                    XCTFail()
                }
            }
    }
}
