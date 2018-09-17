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
            .map(Parser(file: "test.zolang").tokenize(string:))
        
        for tokenList in tokens {
            do {
                _ = try VariableMutation(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {}
        }
    }
    
    func testVariableDeclaration() {
        
        let samples: [(String, Int)] = [
            ("let some be \n something", 1),
            ("let some be \n\nsomething", 2)
        ]
        
        samples
            .forEach { code, lineAtEnd in
                var context = ParserContext(file: "test.zolang")
                do {
                    _ = try VariableDeclaration(tokens: Parser(file: "test.zolang").tokenize(string: code),
                                                context: &context)
                    XCTAssert(context.line == lineAtEnd)
                    
                } catch {
                    XCTFail()
                }
            }
    }
}
