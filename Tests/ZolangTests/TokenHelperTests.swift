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
        
        var tokens = code2.zo.tokenize()
        
        XCTAssert(tokens.getPrefix(to: .newline) == expected)
        XCTAssert(tokens.getPrefix(to: .describe) == [.describe])
        
        expected = [
            .let, .identifier("person"), .as, .identifier("Person"),
        ]
        
        tokens = code1.zo
            .tokenize()
            .getPrefix(to: .equals)
        
        XCTAssertFalse(tokens == expected)
        expected.append(.equals)
        XCTAssert(tokens == expected)
    }
    
    func testIndicesOutsideOfScope() {
        let code = "someFunc(boob, \"boob\", b(0, 0, 8), (800 + b), 8.008)"
        
        let tokens = code.zo.tokenize()
        
        let expected = [ 3, 5, 14, 20 ]
        
        let indices = tokens.indices(of: [ .comma ],
                                     outsideOf: [ (.parensOpen, .parensClose) ],
                                     startingAt: 2)
        
        XCTAssert(indices == expected)
    }
    
    func testRangeOfScope() {
        let code = describeCode
        let code2 = String(code[..<code.index(before: code.endIndex)])
        var tokens = code2.zo.tokenize()
        var range = tokens.rangeOfScope(open: .curlyOpen, close: .curlyClose)
        XCTAssertNil(range)
        
        tokens = code.zo.tokenize()
        
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
            .identifier("print"), .parensOpen, .textLiteral("Woof: ${name}"), .parensClose, .newline,
            .curlyClose, .newline,
            .curlyClose
        ]
        
        let tokens = code.zo.tokenize()
        
        let range = tokens.rangeOfDescribe()!
        let describeSlice = tokens[range]
        XCTAssert(Array(describeSlice) == expected)
    }
    
    func testRangeOfExpression() {
        let validExpression = "somefunc(someLabel1: someParam, someLabel2: someParam) plus variable1 times (variable2 over variable3)"
        
        var tokens = validExpression.zo.tokenize()
        var range: ClosedRange<Int> = 0...(tokens.count - 1)
        XCTAssert(tokens.rangeOfExpression()! == range)
        
        let expressionWithMissingParens = "(something plus (12345 plus 5)"
        tokens = expressionWithMissingParens.zo.tokenize()
        XCTAssertNil(tokens.rangeOfExpression())
        
        let expressionWithMatchingParens = expressionWithMissingParens + ")"
        tokens = expressionWithMatchingParens.zo.tokenize()
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
            let tokens = validMutation.zo.tokenize()
            XCTAssert(tokens.rangeOfVariableDeclarationOrMutation()! == range)
        }
        
        let notAMutationOrDeclaration = "(something plus (12345 plus 5))"
        let tokens = notAMutationOrDeclaration.zo.tokenize()
        XCTAssertNil(tokens.rangeOfVariableDeclarationOrMutation())
    }
    
    func testRangeOfFunctionDeclarationOrMutation() {
        let validMutationOrDeclarations: [(String, ClosedRange<Int>)] = [
            ("make some return text from (some as number) {} \n let some be \"some\"", 0...11),
            ("make \nsome.other \nreturn list of number from () {}\nprint(\"text\")", 0...14),
        ]
        
        
        for tuple in validMutationOrDeclarations {
            let (validMutation, range) = tuple
            let tokens = validMutation.zo.tokenize()
            XCTAssert(tokens.rangeOfFunctionDeclarationOrMutation()! == range)
        }
        
        let notAMutationOrDeclaration = "(something plus (12345 plus 5))"
        let tokens = notAMutationOrDeclaration.zo.tokenize()
        XCTAssertNil(tokens.rangeOfFunctionDeclarationOrMutation())
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
            let tokens = code.zo.tokenize()
            XCTAssert(tokens.rangeOfIfStatement()! == expected, "\(tokens.rangeOfIfStatement()!)")
        }
        
        let invalid = """
        if (a) {
            print(":(")
        """

        XCTAssertNil(invalid.zo.tokenize().rangeOfIfStatement())
    }
}
