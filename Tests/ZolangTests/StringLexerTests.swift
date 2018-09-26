import Foundation
import XCTest
import ZolangCore

class StringLexerTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testOffsetted() {
        let string = "abcd"
        
        let expected = [
            1: "bcd",
            2: "cd",
            3: "d"
        ]
        
        for exp in expected {
            XCTAssertFalse(string.zo.offsetted(by: exp.key - 1) == exp.value)
            XCTAssert(string.zo.offsetted(by: exp.key) == exp.value)
        }
    }
    
    func testGetPrefix() {
        let regex = "[^\\\\]+"
        let countToEight = "12345678"
        
        let expectedToBeNil = "\\5&82kdæadjak"
        let expectedToBeNotNil = "\(countToEight)\\ask"
        
        XCTAssertNil(expectedToBeNil.zo.getPrefix(regex: regex))
        
        XCTAssertNotNil(expectedToBeNotNil.zo.getPrefix(regex: regex))
        XCTAssert(expectedToBeNotNil.zo.getPrefix(regex: regex) == countToEight)
    }
    
    func testLabelRegex() {
        let regex = RegExRepo.label
        
        let validName = "ab91kz"
        let expectedToMatch = "\(validName) not included"
        XCTAssert(expectedToMatch.zo.getPrefix(regex: regex) == validName)
        
        let invalidName = "9abcd"
        XCTAssertNil(invalidName.zo.getPrefix(regex: regex))
    }
    
    func testSeparators() {
        let commaRegex = RegExRepo.comma
        let colonRegex = RegExRepo.colon
        let dotRegex = RegExRepo.dot
        let equalsRegex = RegExRepo.equals
        
        var valid = ","
        let invalid = "bla"
        var string = "\(valid) yey"
        XCTAssertNil(invalid.zo.getPrefix(regex: commaRegex))
        XCTAssert(string.zo.getPrefix(regex: commaRegex) == valid)
        
        valid = ":"
        string = "\(valid) yey"
        XCTAssertNil(invalid.zo.getPrefix(regex: colonRegex))
        XCTAssert(string.zo.getPrefix(regex: colonRegex) == valid)
        
        valid = "."
        string = "\(valid) yey"
        XCTAssertNil(invalid.zo.getPrefix(regex: dotRegex))
        XCTAssert(string.zo.getPrefix(regex: dotRegex) == valid)
        
        valid = "="
        string = "\(valid) yey"
        XCTAssertNil(invalid.zo.getPrefix(regex: equalsRegex))
        XCTAssert(string.zo.getPrefix(regex: equalsRegex) == valid)
        
    }
    
    func testWhitespace() {
        let newlineRegex = RegExRepo.newline
        
        let invalid = "bla"
        XCTAssertNil(invalid.zo.getPrefix(regex: newlineRegex))
        
        var valid = "\n"
        var string = "\(valid) yey"
        XCTAssert(string.zo.getPrefix(regex: newlineRegex) == valid)
        
        let inlineWhitespaceRegex = RegExRepo.inlineWhitespaceCharacter
        XCTAssertNil(invalid.zo.getPrefix(regex: inlineWhitespaceRegex))
        
        valid = "\t"
        string = "\(valid)yey"
        XCTAssert(string.zo.getPrefix(regex: inlineWhitespaceRegex) == valid)
        
        valid = " "
        string = "\(valid)yey"
        XCTAssert(string.zo.getPrefix(regex: inlineWhitespaceRegex) == valid)
    }
    
    func testBrackets() {
        let expected = [
            (regex: RegExRepo.curlyOpen, valid: "{"),
            (regex: RegExRepo.curlyClose, valid: "}"),
            (regex: RegExRepo.bracketOpen, valid: "["),
            (regex: RegExRepo.bracketClose, valid: "]"),
            (regex: RegExRepo.parensOpen, valid: "("),
            (regex: RegExRepo.parensClose, valid: ")"),
        ]
        
        let invalid = "bla"
        
        for exp in expected {
            let string = "\(exp.valid) yey"
            XCTAssertNil(invalid.zo.getPrefix(regex: exp.regex))
            XCTAssert(string.zo.getPrefix(regex: exp.regex) == exp.valid)
        }
    }
    
    func testLiterals() {
        let expected = [
            (regex: RegExRepo.decimal, valid: "12394", invalid: "bla"),
            (regex: RegExRepo.floatingPoint, valid: "555.555", invalid: "123"),
            (regex: RegExRepo.string, valid: "\"12\\\\394\"", invalid: "\"12\\394\""),
            (regex: RegExRepo.boolean, valid: "true", invalid: "blatrue"),
            (regex: RegExRepo.boolean, valid: "false", invalid: "bla")
        ]
        
        for exp in expected {
            let string = "\(exp.valid) yey"
            XCTAssertNil(exp.invalid.zo.getPrefix(regex: exp.regex))
            XCTAssert(string.zo.getPrefix(regex: exp.regex) == exp.valid, exp.valid)
        }
    }
    
    func testOperator() {
        let regex = RegExRepo.operator
        
        let invalid = "a"
        XCTAssertNil(invalid.zo.getPrefix(regex: regex))
        
        let validStrings = [
            "plus",
            "minus",
            "times",
            "over",
            "and",
            "or",
            "equals",
            "<=",
            ">=",
            "<",
            ">",
        ]
        
        for op in validStrings {
            XCTAssert("\(op) yey".zo.getPrefix(regex: regex) == op, op)
        }
    }
    
    func testKeyword() {
        let regex = RegExRepo.keyword
        
        let invalid = "a"
        XCTAssertNil(invalid.zo.getPrefix(regex: regex))
        
        let validStrings = [
            "describe",
            "make",
            "return",
            "while",
            "from",
            "let",
            "as",
            "be",
            "of",
            "if",
            "else",
            "static"
        ]
        
        XCTAssert(validStrings.joined(separator: "|").sorted() == regex.sorted())
        
        for keyword in validStrings {
            XCTAssert("\(keyword) yey".zo.getPrefix(regex: regex) == keyword, keyword)
        }
    }
}
