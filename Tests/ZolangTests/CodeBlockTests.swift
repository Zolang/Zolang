//
//  CodeBlockTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 25/08/2018.
//

import XCTest
import ZolangCore

extension URL {
    static var dummy: URL {
        return URL(string: "file://some")!
    }
}

class CodeBlockTests: XCTestCase {
    
    let declarationExpressionMutation = """
    let some as text be "text"
    println(some)
    make some.property be "something else"
    print(some)
    """
    
    let whileLoop = """
    let i as number be 0
    
    while (i < 10) {
        make i be i plus 1
    }

    """
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        
        let invalidCodeBlock = """


        describe Some {
            some as text
        }

        let i as number be 0

        while (i < 10) {
            make i be i plus 1
        }

        something(

        let somethingNew be "abcd"
        """
        
        let invalidCode = "make some as bla"
        let invalidSamples: [(String, Int)] = [
            ("let some be \n\n\"test\"", 1),
            ("let some as text be \n\n\"test\" \n\n\(invalidCode)", 5),
            ("make some be \n\"test\" \n\n\(invalidCode)", 4),
            (invalidCodeBlock, 13)
        ]
        
        for codeLineTuple in invalidSamples {
            var context = ParserContext(file: "test.zolang")

            let (code, line) = codeLineTuple
            let tokenList = code.zo.tokenize()

            do {
                _ = try CodeBlock(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {
                XCTAssert((error as? ZolangError)?.line == line, "\((error as? ZolangError)!.line)")
            }
        }
    }
    
    func testDeclarationExpressionMutation() {
        var context = ParserContext(file: "dummy")
    
        let tokens = declarationExpressionMutation.zo.tokenize()
        do {
            let codeBlock = try CodeBlock(tokens: tokens,
                                          context: &context)
            XCTAssert(context.line == 4)

            
            guard case let .combination(firstL, firstR) = codeBlock else {
                XCTFail()
                return
            }

            guard case let .variableDeclaration(decl) = firstL else {
                XCTFail()
                return
            }
            
            XCTAssert(decl.identifier == "some")
            
            guard case let .textLiteral(lit) = decl.expression else {
                XCTFail()
                return
            }
            
            XCTAssert(lit == "text")
            
            guard case let .combination(secondL, secondR) = firstR else {
                XCTFail()
                return
            }
            
            guard case let .expression(expr) = secondL else {
                XCTFail()
                return
            }
            
            guard case let .functionCall(call) = expr else {
                XCTFail()
                return
            }
            
            let (identifier, params) = call
            
            XCTAssert(identifier == "println")
            XCTAssert(params.count == 1)
            guard case let .identifier(funcIdentifier) = params[0] else {
                XCTFail()
                return
            }
            XCTAssert(funcIdentifier == "some")
            
            guard case let .combination(thirdL, thirdR) = secondR else {
                XCTFail()
                return
            }
            
            guard case let .variableMutation(mut) = thirdL else {
                XCTFail()
                return
            }
            
            XCTAssert(mut.identifiers == ["some", "property"])
            
            guard case let .textLiteral(literal) = mut.expression else {
                XCTFail()
                return
            }
            
            XCTAssert(literal == "something else")
            
            guard case let .expression(lastExpr) = thirdR else {
                XCTFail()
                return
            }
            
            guard case let .functionCall(call2) = lastExpr else {
                XCTFail()
                return
            }
            
            let (identifier2, params2) = call2
            
            XCTAssert(identifier2 == "print")
            XCTAssert(params2.count == 1)
            
            guard case let .identifier(funcIdentifier2) = params2[0] else {
                XCTFail()
                return
            }
            XCTAssert(funcIdentifier2 == "some")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testWhileLoop() {
        var context = ParserContext(file: "test.zolang")
        
        let tokens = whileLoop.zo.tokenize()
        
        do {
            let codeBlock = try CodeBlock(tokens: tokens, context: &context)
            
            guard case let .combination(leftBlock, rightBlock) = codeBlock else {
                XCTFail()
                return
            }
            
            guard case let .variableDeclaration(decl) = leftBlock else {
                XCTFail()
                return
            }
            
            XCTAssert(decl.identifier == "i")

            guard case let .integerLiteral(i) = decl.expression else {
                XCTFail()
                return
            }
            
            XCTAssert(i == "0")
            
            guard case let .combination(leftBlock2, rightBlock2) = rightBlock else {
                XCTFail()
                return
            }
            
            guard case .empty = rightBlock2 else {
                XCTFail()
                return
            }
            
            guard case let .whileLoop(expression, whileBlock) = leftBlock2 else {
                XCTFail()
                return
            }
            
            guard case let .operation(lExpr, op, rExpr) = expression else {
                XCTFail()
                return
            }
            
            XCTAssert(op == "<")
            
            guard case let .identifier(leftID) = lExpr else {
                XCTFail()
                return
            }
            
            XCTAssert(leftID == "i")
            
            guard case let .integerLiteral(integer) = rExpr else {
                XCTFail()
                return
            }
            
            XCTAssert(integer == "10")
            
            guard case let .combination(leftBlock3, rightBlock3) = whileBlock else {
                XCTFail()
                return
            }
            
            guard case .empty = rightBlock3 else {
                XCTFail()
                return
            }
            
            guard case let .variableMutation(mut) = leftBlock3 else {
                XCTFail()
                return
            }
            
            XCTAssert(mut.identifiers == ["i"])
            
            guard case let .operation(lExpr2, op2, rExpr2) = mut.expression else {
                XCTFail()
                return
            }
            
            XCTAssert(op2 == "plus")
            
            guard case let .identifier(identifier2) = lExpr2 else {
                XCTFail()
                return
            }
            
            XCTAssert(identifier2 == "i")
            
            guard case let .integerLiteral(integer2) = rExpr2 else {
                XCTFail()
                return
            }
            
            XCTAssert(integer2 == "1")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
