//
//  TokenHelperTests.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import XCTest

class TokenHelperTests: XCTestCase {
    
    let describeCode = """
    describe Dog as {
        name as text

        speak return from () {
            print("Woof: ${name}")
        }
    }
    """
    
    lazy var whileDescribeIf = """
    while (something) {
        print("YEY")
    }
    
    \(describeCode)
    
    if (something == false) {
        print("YES")
    }
    """
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTokenArrayPrefix() {
        let code1 = "let person as Person = Person(yey: \"yey\", some: 3)"
        let code2 = """
        describe Person as {
            yey as text
            some as integer
        }
        \(code1)
        """
        var expected: [Token] = [
            .describe, .identifier("Person"), .`as`, .curlyOpen, .newline,
        ]
        
        var tokens = Lexer(string: code2).tokenize()
        
        XCTAssert(tokens.getPrefix(to: .newline) == expected)
        XCTAssert(tokens.getPrefix(to: .describe) == [.describe])
        
        expected = [
            .let, .identifier("person"), .as, .identifier("Person"),
        ]
        
        tokens = Lexer(string: code1)
            .tokenize()
            .getPrefix(to: .equals)
        
        XCTAssertFalse(tokens == expected)
        expected.append(.equals)
        XCTAssert(tokens == expected)
    }
    
    func testRangeOfScope() {
        let code = describeCode
        let code2 = String(code[..<code.index(before: code.endIndex)])
        var tokens = Lexer(string: code2).tokenize()
        var range = tokens.rangeOfScope(open: .curlyOpen, close: .curlyClose)
        XCTAssertNil(range)
        
        tokens = Lexer(string: code).tokenize()
        
        range = tokens.rangeOfScope(open: .curlyOpen, close: .curlyClose)
        
        XCTAssert(range!.lowerBound == 3)
        XCTAssert(range!.upperBound == 24)
        XCTAssert(tokens[range!.lowerBound] == .curlyOpen)
        XCTAssert(tokens[range!.upperBound] == .curlyClose)
    }
    
    func testRangeOfDescribe() {
        let code = whileDescribeIf
        
        let expected: [Token] = [
            
            .describe, .identifier("Dog"), .as, .curlyOpen, .newline,
            .identifier("name"), .as, .identifier("text"), .newline,
            .newline,
            .identifier("speak"), .return, .from, .parensOpen, .parensClose, .curlyOpen, .newline,
            .identifier("print"), .parensOpen, .stringLiteral("\"Woof: ${name}\""), .parensClose, .newline,
            .curlyClose, .newline,
            .curlyClose
        ]
        
        let tokens = Lexer(string: code).tokenize()
        
        let range = tokens.rangeOfDescribe()!
        let describeSlice = tokens[range]
        XCTAssert(Array(describeSlice) == expected)
    }
    
    func testRangeOfExpression() {
        let validExpression = "somefunc(someLabel1: someParam, someLabel2: someParam) + variable1 * (variable2 / variable3)"
        
        var tokens = Lexer(string: validExpression).tokenize()
        var range: ClosedRange<Int> = 0...(tokens.count - 1)
        XCTAssert(tokens.rangeOfExpression()! == range)
        
        let expressionWithMissingParens = "(something + (12345 + 5)"
        tokens = Lexer(string: expressionWithMissingParens).tokenize()
        XCTAssertNil(tokens.rangeOfExpression())
        
        let expressionWithMatchingParens = expressionWithMissingParens + ")"
        tokens = Lexer(string: expressionWithMatchingParens).tokenize()
        range = 0...(tokens.count - 1)
        XCTAssert(tokens.rangeOfExpression()! == range)
    }
}
