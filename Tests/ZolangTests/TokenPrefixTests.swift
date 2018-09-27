//
//  TokenPrefixTests.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import XCTest
import ZolangCore

class TokenPrefixTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetPrefix() {
        let describe: [Token] = [
            .describe, .identifier("Some"), .as, .curlyOpen, .curlyClose
        ]
        
        let ifStatement: [Token] = [
            .if, .parensOpen, .identifier("boolean"), .parensClose, .curlyOpen, .curlyClose
        ]
        
        let variableMutation: [Token] = [
            .make, .identifier("someVar"), .be, .identifier("newValue")
        ]
        
        let whileLoop: [Token] = [
            .while, .parensOpen, .identifier("truthy"), .parensClose, .curlyOpen, .curlyClose
        ]
        
        let variableDeclaration: [Token] = [
            .let, .identifier("someVar"), .be, .textLiteral("someVal")
        ]
        
        let notZolang: [Token] = [
            .curlyClose, .identifier("some"), .curlyOpen, .be
        ]
        
        XCTAssertFalse(ifStatement.isPrefixWhileLoop())
        XCTAssertFalse(describe.isPrefixIfStatement())
        XCTAssertFalse(describe.isPrefixExpression())
        XCTAssertFalse(ifStatement.isPrefixExpression())
        XCTAssertFalse(variableMutation.prefixType() == .variableDeclaration)
        XCTAssertFalse(whileLoop.prefixType() == .expression)
        XCTAssertFalse(notZolang.prefixType() == .expression)
        
        XCTAssert(variableMutation.prefixType() == .variableMutation)
        XCTAssert(describe.prefixType() == .modelDescription)
        XCTAssert(ifStatement.prefixType() == .ifStatement)
        XCTAssert(whileLoop.prefixType() == .whileLoop)
        XCTAssert(variableDeclaration.prefixType() == .variableDeclaration)
        
        XCTAssertNil(notZolang.prefixType())
    }
    
    func testHasPrefix() {
        var sample: [Token] = [
            .describe, .newline, .identifier("Some"), .newline, .as, .newline, .curlyOpen, .curlyClose
        ]
        
        var prefix: [TokenType] = [
            .describe, .identifier, .as, .curlyOpen
        ]
        
        let expectedToBeTrue = sample.hasPrefixTypes(types: prefix, skipping: [ .newline ])
        XCTAssert(expectedToBeTrue)
        
        prefix = [
            .let, .identifier, .be
        ]
        
        var expectedToBeFalse = sample.hasPrefixTypes(types: prefix, skipping: [ .newline ])
        XCTAssertFalse(expectedToBeFalse)
        
        sample = [ .identifier("sample") ]
        prefix = [ .identifier, .parensOpen ]
        expectedToBeFalse = sample.hasPrefixTypes(types: prefix, skipping: [ .newline ])
        XCTAssertFalse(expectedToBeFalse)
    }
    
    func testExpressionPrefix() {

        print("yey equals bla".zo.tokenize())
        
        var expectedToBeExpression: [Token] = [
            .identifier("someFunc"), .parensOpen, .parensClose
        ]
        
        XCTAssert(expectedToBeExpression.prefixType() == .expression)
        
        expectedToBeExpression = [
            .textLiteral("some"), .operator("equals"), .identifier("someStr")
        ]
        
        XCTAssert(expectedToBeExpression.prefixType() == .expression)
        
        expectedToBeExpression = [
            .parensOpen, .floatingPoint("1000.1"), .operator("equals"), .identifier("someFloat"), .parensClose
        ]
        
        XCTAssert(expectedToBeExpression.prefixType() == .expression)
        
        expectedToBeExpression = [
            .prefixOperator("-"), .identifier("someNegativeValue"), .operator("plus"), .operator("minus"), .identifier("anotherNegativeValue")
        ]
        
        XCTAssert(expectedToBeExpression.prefixType() == .expression)
    }
}
