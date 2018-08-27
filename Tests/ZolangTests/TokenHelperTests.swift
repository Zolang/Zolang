//
//  TokenHelperTests.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import XCTest
import ZolangCore

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
        
        var tokens = Lexer().tokenize(string: code2)
        
        XCTAssert(tokens.getPrefix(to: .newline) == expected)
        XCTAssert(tokens.getPrefix(to: .describe) == [.describe])
        
        expected = [
            .let, .identifier("person"), .as, .identifier("Person"),
        ]
        
        tokens = Lexer()
            .tokenize(string: code1)
            .getPrefix(to: .equals)
        
        XCTAssertFalse(tokens == expected)
        expected.append(.equals)
        XCTAssert(tokens == expected)
    }
    
    func testIndicesOutsideOfScope() {
        let code = "someFunc(boob, \"boob\", b(0, 0, 8), (800 + b), 8.008)"
        
        let tokens = Lexer().tokenize(string: code)
        
        let expected = [ 3, 5, 14, 20 ]
        
        let indices = tokens.indices(of: [ .comma ],
                                     outsideOf: [ (.parensOpen, .parensClose) ],
                                     startingAt: 2)
        
        XCTAssert(indices == expected)
    }
    
    func testRangeOfScope() {
        let code = describeCode
        let code2 = String(code[..<code.index(before: code.endIndex)])
        var tokens = Lexer().tokenize(string: code2)
        var range = tokens.rangeOfScope(open: .curlyOpen, close: .curlyClose)
        XCTAssertNil(range)
        
        tokens = Lexer().tokenize(string: code)
        
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
            .identifier("print"), .parensOpen, .stringLiteral("Woof: ${name}"), .parensClose, .newline,
            .curlyClose, .newline,
            .curlyClose
        ]
        
        let tokens = Lexer().tokenize(string: code)
        
        let range = tokens.rangeOfDescribe()!
        let describeSlice = tokens[range]
        XCTAssert(Array(describeSlice) == expected)
    }
    
    func testRangeOfExpression() {
        let validExpression = "somefunc(someLabel1: someParam, someLabel2: someParam) + variable1 * (variable2 / variable3)"
        
        var tokens = Lexer().tokenize(string: validExpression)
        var range: ClosedRange<Int> = 0...(tokens.count - 1)
        XCTAssert(tokens.rangeOfExpression()! == range)
        
        let expressionWithMissingParens = "(something + (12345 + 5)"
        tokens = Lexer().tokenize(string: expressionWithMissingParens)
        XCTAssertNil(tokens.rangeOfExpression())
        
        let expressionWithMatchingParens = expressionWithMissingParens + ")"
        tokens = Lexer().tokenize(string: expressionWithMatchingParens)
        range = 0...(tokens.count - 1)
        XCTAssert(tokens.rangeOfExpression()! == range)
    }
    
    func testRangeOfVariableDeclarationOrMutation() {
        let validMutationOrDeclarations: [(String, ClosedRange<Int>)] = [
            ("make some be \"text\"", 0...3),
            ("make some be \n\"text\"", 0...4),
            ("let some be \"text\"", 0...3),
            ("let some be \n\"text\"", 0...4),
            ("\n\n\nmake some be \n\"text\"", 3...7),
            ("\nsomeIdentifier\nmake some be \n\"text\"", 3...7),
            ("\n\n\nlet some be \n\"text\"", 3...7),
            ("\nsomeIdentifier\nlet some be \n\"text\"", 3...7)
        ]
        
        
        for tuple in validMutationOrDeclarations {
            let (validMutation, range) = tuple
            let tokens = Lexer().tokenize(string: validMutation)
            XCTAssert(tokens.rangeOfVariableDeclarationOrMutation()! == range)
        }
        
        let notAMutationOrDeclaration = "(something + (12345 + 5))"
        let tokens = Lexer().tokenize(string: notAMutationOrDeclaration)
        XCTAssertNil(tokens.rangeOfVariableDeclarationOrMutation())
    }
    
    func testRangeOfIfStatement() {
        let valid1 = """
        if (a) {
            print(a)
        } else if (b) {
            print(b)
        } else {
            print(":(")
        }
        """

        let valid2 = """

        print(a)

        if (a) {
            yey()
        }

        print(b)
        """
        
        let valid = [
            (valid1, ClosedRange<Int>(0...33)),
            (valid2, ClosedRange<Int>(7...17))
        ]
        
        valid.forEach { (code, expected) in
            let tokens = Lexer().tokenize(string: code)
            XCTAssert(tokens.rangeOfIfStatement()! == expected, "\(tokens.rangeOfIfStatement()!)")
        }
        
        let invalid = """
        if (a) {
            print(":(")
        """

        XCTAssertNil(Lexer().tokenize(string: invalid).rangeOfIfStatement())
    }
}
