//
//  FunctionDeclarationTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 10/09/2018.
//

import Foundation
import XCTest
import ZolangCore

class FunctionDeclarationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        
        let invalidSamples: [(String, Int)] = [
            ("let some \n be something", 1),
            ("let \n some return something", 2),
            ("let some. return\n Some from (t as text) {}", 1),
            ("let some.some\n return Some from (t as text) {}", 1),
            ("\n make some return text from (n as number) {}", 2),
            ("\nlet \nsome return \ntext from (\nn\n as ) \n{}", 6)
        ]
        
        invalidSamples.forEach { (code, line) in
            var context = ParserContext(file: "test.zolang")
            let tokenList = code.zo.tokenize()
            do {
                _ = try FunctionDeclaration(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {
                XCTAssert((error as? ZolangError)?.line == line)
            }
        }
        
    }
    
    func testInit() {
        
        let samples: [(String, String, Type, Int)] = [
            ("let some return Some from () {}", "some", .custom("Some"), 1),
            ("\nlet some return \ntext from () {}", "some", .primitive(.text), 3),
            ("let some return list of number from \n\n() {}", "some", .list(.primitive(.number)), 3)
        ]
        
        for testTuple in samples {
            let (code, expectedIdentifier, expectedType, endOfLine) = testTuple
            
            var context = ParserContext(file: "test.zolang")
            let tokenList = code.zo.tokenize()
            
            do {
                let declaration = try FunctionDeclaration(tokens: tokenList, context: &context)
                XCTAssert(context.line == endOfLine)
                
                XCTAssert(declaration.identifier == expectedIdentifier)
                
                guard declaration.function.returnType == expectedType else {
                    XCTFail("VariableMutation resulted in wrong expression")
                    return
                }
                
            } catch {
                XCTFail("Should not fail to create FunctionDeclaration")
            }
        }
    }
}
