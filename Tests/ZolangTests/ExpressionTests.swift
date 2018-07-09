//
//  ExpressionTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 30/06/2018.
//

import XCTest

class ExpressionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInvalidExpression() {
        var context = ParserContext(file: "test.zolang")

        let tokens: [Token] = [
            .let, .identifier("some"), .be, .newline, .stringLiteral("some")
        ]

        do {
            _ = try Expression(tokens: tokens, context: &context)
            XCTFail("Should fail")
        } catch {
            guard let error = error as? ZolangError else {
                XCTFail("Error should be a ZolangError")
                fatalError()
            }
            
            guard case .invalidExpression = error.type else {
                XCTFail("Error should be unexpectedToken")
                fatalError()
            }
        }
        
    }
    
    func testArrayAccess() {
        var context = ParserContext(file: "test.zolang")
        
        do {
            let tokens: [Token] = [
                .identifier("some"), .bracketOpen, .identifier("fake"), .bracketClose
            ]
            let expression = try Expression(tokens: tokens, context: &context)
            
            guard case let .arrayAccess(identifier, innerExpression) = expression else {
                XCTFail("expression should return operation")
                fatalError()
            }
            
            guard case let .identifier(payload) = innerExpression else {
                XCTFail("should return identifier")
                fatalError()
            }
            
            XCTAssert(payload == "fake", "payload should match token")
            XCTAssert(identifier == "some", "identifier should match token")

        } catch {
            XCTFail("Should not fail: \(error.localizedDescription)")
        }
    }
    
    func testParenthesesOperation() {
        var context = ParserContext(file: "test.zolang")
        do {
            let tokens: [Token] = [
                .decimal("55"), .operator("*"), .parensOpen, .identifier("x"), .operator("+"), .identifier("y"), .parensClose
            ]
        
            let expression = try Expression(tokens: tokens, context: &context)
        
            guard case let .operation(exprL, op, exprR) = expression else {
                XCTFail("expression should return operation")
                fatalError()
            }
        
            XCTAssert(op == "*", "operator should match token payload")
        
        
            guard case let .integerLiteral(integer) = exprL else {
                XCTFail("expression should return identifier")
                fatalError()
            }
        
            XCTAssert(integer == "55", "integer should match token payload")
        
            guard case let .parentheses(exprRC) = exprR else {
                XCTFail("expression should return parentheses")
                fatalError()
            }
        
            guard case let .operation(exprRL, op2, exprRR) = exprRC else {
                XCTFail("expression should return operation")
                fatalError()
            }
        
            XCTAssert(op2 == "+", "operator should match token payload")
        
            guard case let .identifier(idL) = exprRL else {
                XCTFail("expression should return identifier")
                fatalError()
            }
        
            guard case let .identifier(idR) = exprRR else {
                XCTFail("expression should return identifier")
                fatalError()
            }
        
            XCTAssert(idL == "x")
            XCTAssert(idR == "y")
        } catch {
            XCTFail("Should not fail: \(error.localizedDescription)")
        }
    }
}
