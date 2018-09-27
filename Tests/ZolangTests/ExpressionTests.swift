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
            .map { $0.zo.tokenize() }
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
            ("55 times array[1", 1),
            ("55 times \narray[", 2),
            ("array\n[\na[]", 2)
        ]
        
        samples
            .map { args -> ([Token], Int) in
                let (code, line) = args
                return (code.zo.tokenize(), line)
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
            ("55 times (x plus y", 1),
            ("55\ntimes\n\n(x plus y", 4),
            ("(\n(5 plus 4) plus 3) times (2 plus 1", 2),
            ("(\n(5 plus 4) plus 3) times \n(2 plus 1", 3)
        ]

        samples
            .map { args -> ([Token], Int) in
                let (code, line) = args
                return (code.zo.tokenize(), line)
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
            let tokens = "some[\nfake\n]".zo.tokenize()

            let expression = try Expression(tokens: tokens, context: &context)
            
            XCTAssert(context.line == 3)
            
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

            XCTAssert(context.line == 2)

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

            let tokens = "\(funcIdentifier)\n(\(paramIdentifier), \"\(paramString)\", \(paramInt), \(paramFloat))"
                .zo
                .tokenize()
            
            let expression = try Expression(tokens: tokens, context: &context)
            
            XCTAssert(context.line == 2)
            
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
            
            guard case let .textLiteral(strLit) = innerExpressions[1] else {
                XCTFail("expression should return textLiteral")
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

            let tokens = "[\n\(paramIdentifier), \"\(paramString)\", \n\t\(paramInt), [ \(funcIdentifier)([\(paramInt)]) ]]"
                .zo
                .tokenize()
            
            let expression = try Expression(tokens: tokens, context: &context)
            
            XCTAssert(context.line == 3)
            
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
            
            guard case let .textLiteral(strLit) = innerExpressions[1] else {
                XCTFail("expression should return textLiteral")
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
    
    func testTemplatedText() {
        
        let valid: [(String, ([Expression]) -> Int)] = [
            ("\"Hello ${\"world\"}\"", { expr in
                guard expr.count == 2 else { return -1 }
                guard case let .textLiteral(str1) = expr[0] else { return -2 }
                let check1 = str1 == "Hello "
                
                guard case let .textLiteral(str2) = expr[1] else { return -2 }
                let check2 = str2 == "world"
                return check1 && check2 ? 0 : 1
            }),
            ("\"Hello ${getString()}\"", { expr in
                guard expr.count == 2 else { return -3 }
                guard case let .textLiteral(str1) = expr[0] else { return -4 }
                let check1 = str1 == "Hello "
                
                guard case let .functionCall(identifier, _) = expr[1] else { return -4 }
                let check2 = identifier == "getString"
                return check1 && check2 ? 0 : 2
            }),
            ("\"What's up ${homie} hundred $ bill y'all. Hello ${a[2]}\"", { expr in
                guard expr.count == 4 else { return -5 }
                guard case let .textLiteral(str1) = expr[0] else { return -6 }
                let check1 = str1 == "What's up "

                guard case let .identifier(str2) = expr[1] else { return -7 }
                let check2 = str2 == "homie"
                
                guard case let .textLiteral(str3) = expr[2] else { return -8 }
                let check3 = str3 == " hundred $ bill y'all. Hello "

                guard case let .listAccess(identifier, inner) = expr[3] else { return -9 }
                guard case let .integerLiteral(num) = inner else { return -10 }
                let check4 = num == "2" && identifier == "a"
                return check1 && check2 && check3 && check4 ? 0 : 3
            })
        ]
        
        valid.forEach { (code, validate) in
            var context = ParserContext(file: "test.zolang")
            XCTAssert(code.zo.getPrefix(regex: RegExRepo.string) == code)
            do {
                let expression = try Expression(tokens: code.zo.tokenize(), context: &context)
                guard case let .templatedText(expressions) = expression else {
                    return XCTFail()
                }
                let validation = validate(expressions)
                XCTAssert(validation == 0, "\(validation)")
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
