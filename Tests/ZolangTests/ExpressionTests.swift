//
//  ExpressionTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 30/06/2018.
//

import ZolangCore
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
        
        let samples: [String] = [
            "let some be\nsome",
            "make person.name be \"valdi\"",
            "describe Person as {\nname as text }"
        ]

        samples
            .map(Parser(file: "test.zolang").tokenize)
            .forEach { tokens in
                do {
                    _ = try Expression(tokens: tokens, context: &context)
                    XCTFail("Should fail")
                } catch {
                    guard let error = error as? ZolangError else {
                        XCTFail("Error should be a ZolangError")
                        fatalError()
                    }
                    
                    guard case .invalidExpression = error.type else {
                        XCTFail("Error should be invalidExpression")
                        fatalError()
                    }
                }
            }
    }
    
    func testMissingMatchingBracket() {
        let samples: [(code: String, expectedLine: Int)] = [
            ("55 * array[1", 0),
            ("55 * \narray[", 1),
            ("array\n[\na[]", 1)
        ]
        
        samples
            .map { args -> ([Token], Int) in
                let (code, line) = args
                return (Parser(file: "test.zolang").tokenize(string: code), line)
            }
            .forEach { (tokens, line) in
                var context = ParserContext(file: "test.zolang")
                do {
                    _ = try Expression(tokens: tokens, context: &context)
                    XCTFail("Should fail")
                } catch {
                    guard let error = error as? ZolangError else {
                        XCTFail("Error should be a ZolangError")
                        fatalError()
                    }

                    guard case .missingMatchingBracket = error.type else {
                        XCTFail("Error should be unexpectedToken")
                        fatalError()
                    }
                    
                    XCTAssert(line == error.line)
                }
            }
    }
    
    func testMissingMatchingParens() {
        
        let samples: [(code: String, expectedLine: Int)] = [
            ("55 * (x + y", 0),
            ("55\n*\n\n(x + y", 3),
            ("(\n(5 + 4) + 3) * (2 + 1", 1),
            ("(\n(5 + 4) + 3) * \n(2 + 1", 2)
        ]

        samples
            .map { args -> ([Token], Int) in
                let (code, line) = args
                return (Parser(file: "test.zolang").tokenize(string: code), line)
            }
            .forEach { (tokens, line) in
                var context = ParserContext(file: "test.zolang")
                do {
                    _ = try Expression(tokens: tokens, context: &context)
                    XCTFail("Should fail")
                } catch {
                    guard let error = error as? ZolangError else {
                        XCTFail("Error should be a ZolangError")
                        fatalError()
                    }

                    guard case .missingMatchingParens = error.type else {
                        XCTFail("Error should be unexpectedToken")
                        fatalError()
                    }
                    
                    XCTAssert(line == error.line)
                }
            }
    }
    
    func testArrayAccess() {
        var context = ParserContext(file: "test.zolang")
        
        do {
            let tokens = Parser(file: "test.zolang")
                .tokenize(string: "some[\nfake\n]")

            let expression = try Expression(tokens: tokens, context: &context)
            
            XCTAssert(context.line == 2)
            
            guard case let .listAccess(identifier, innerExpression) = expression else {
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
                .decimal("55"), .newline, .operator("*"), .parensOpen, .identifier("x"), .operator("+"), .identifier("y"), .parensClose
            ]
        
            let expression = try Expression(tokens: tokens, context: &context)

            XCTAssert(context.line == 1)

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
    
    func testFunctionCall() {
        var context = ParserContext(file: "test.zolang")
        
        do {
            let paramIdentifier = "some"
            let funcIdentifier = "someFunc"
            let paramString = "string"
            let paramInt = "55"
            let paramFloat = "46.1"

            let tokens = Parser(file: "test.zolang")
                .tokenize(string: "\(funcIdentifier)\n(\(paramIdentifier), \"\(paramString)\", \(paramInt), \(paramFloat))")
            
            let expression = try Expression(tokens: tokens, context: &context)
            
            XCTAssert(context.line == 1)
            
            guard case let .functionCall(identifier, innerExpressions) = expression else {
                XCTFail("expression should return functionCall")
                fatalError()
            }
            
            XCTAssert(identifier == funcIdentifier)
            XCTAssert(innerExpressions.count == 4)
            
            guard case let .identifier(paramStr) = innerExpressions[0] else {
                XCTFail("expression should return identifier")
                fatalError()
            }
            
            XCTAssert(paramStr == paramIdentifier)
            
            guard case let .stringLiteral(strLit) = innerExpressions[1] else {
                XCTFail("expression should return stringLiteral")
                fatalError()
            }
            
            XCTAssert(strLit == paramString)
            
            guard case let .integerLiteral(intLit) = innerExpressions[2] else {
                XCTFail("expression should return integer")
                fatalError()
            }
            
            XCTAssert(intLit == paramInt)
            
            guard case let .floatLiteral(floatLit) = innerExpressions[3] else {
                XCTFail("expression should return integer")
                fatalError()
            }
            
            XCTAssert(floatLit == paramFloat)
            
        } catch {
            XCTFail("Should not fail: \(error.localizedDescription)")
        }
    }
    
    func testArrayLiteral() {

        var context = ParserContext(file: "test.zolang")
        
        do {
            let paramIdentifier = "some"
            let funcIdentifier = "someFunc"
            let paramString = "string"
            let paramInt = "55"

            let tokens = Parser(file: "test.zolang")
                .tokenize(string: "[\n\(paramIdentifier), \"\(paramString)\", \n\t\(paramInt), [ \(funcIdentifier)([\(paramInt)]) ]]")
            
            let expression = try Expression(tokens: tokens, context: &context)
            
            XCTAssert(context.line == 2)
            
            guard case let .listLiteral(innerExpressions) = expression else {
                XCTFail("expression should return arrayLiteral")
                fatalError()
            }
            
            XCTAssert(innerExpressions.count == 4)
            
            guard case let .identifier(paramStr) = innerExpressions[0] else {
                XCTFail("expression should return identifier")
                fatalError()
            }
            
            XCTAssert(paramStr == paramIdentifier)
            
            guard case let .stringLiteral(strLit) = innerExpressions[1] else {
                XCTFail("expression should return stringLiteral")
                fatalError()
            }
            
            XCTAssert(strLit == paramString)
            
            guard case let .integerLiteral(intLit) = innerExpressions[2] else {
                XCTFail("expression should return integer")
                fatalError()
            }
            
            XCTAssert(intLit == paramInt)
            
            guard case let .listLiteral(innerInnerExpressions) = innerExpressions[3] else {
                XCTFail("expression should return integer")
                fatalError()
            }
            
            XCTAssert(innerInnerExpressions.count == 1)
            
            guard case let .functionCall(innerFuncIdentifier, expressionList) = innerInnerExpressions[0] else {
                XCTFail("expression should be functionCall")
                fatalError()
            }
            
            XCTAssert(innerFuncIdentifier == funcIdentifier)
            XCTAssert(expressionList.count == 1)
            
            guard case let .listLiteral(functionInnerExpressions) = expressionList[0] else {
                XCTFail("expression should be listLiteral")
                fatalError()
            }

            XCTAssert(functionInnerExpressions.count == 1)
            
            guard case let .integerLiteral(integer) = functionInnerExpressions[0] else {
                XCTFail("expression should be listLiteral")
                fatalError()
            }

            XCTAssert(intLit == integer)

        } catch {
            XCTFail("Should not fail: \(error.localizedDescription)")
        }
    }
}
