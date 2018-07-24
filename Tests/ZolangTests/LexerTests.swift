//
//  LexerTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import XCTest
import ZolangCore

class LexerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTokenize() {
        let code = """
        describe Person as {
            variable as text
            function return text from () {
                if (x < 123.456) {
                    print(x + y)
                }
            }
        }
        """
        
        var expected: [Token] = [
            .describe, .identifier("Person"), .`as`, .curlyOpen, .newline,
            .identifier("variable"), .`as`, .identifier("text"), .newline,
            .identifier("function"), .`return`, .identifier("text"), .from, .parensOpen, .parensClose, .curlyOpen, .newline,
            .`if`, .parensOpen, .identifier("x"), .operator("<"), .floatingPoint("123.456"), .parensClose, .curlyOpen, .newline,
            .identifier("print"), .parensOpen, .identifier("x"), .operator("+"), .identifier("y"), .parensClose, .newline,
            .curlyClose, .newline,
            .curlyClose, .newline,
        ]
        
        let tokens = Lexer().tokenize(string: code)
        
        XCTAssertFalse(tokens == expected)
        
        expected.append(.curlyClose)
        
        XCTAssert(tokens == expected)
        
    }
}
