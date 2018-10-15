//
//  OnlyTests.swift
//  ZolangTests
//
//  Created by Thorvaldur Runarsson on 14/10/2018.
//

import Foundation
import XCTest
import ZolangCore

class OnlyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        let invalidSamples: [(String, Int)] = [
            ("list of", 1),
            ("some of number", 1),
            ("list of \nsome of text", 2),
            ("\nlist\n\n of", 4),
            ("only \n{}", 1)
        ]
        
        invalidSamples.forEach({ (code, line) in
            var context = ParserContext(file: "test.zolang")
            do {
                _ = try Type(tokens: code.zo.tokenize(), context: &context)
                XCTFail("Type init should fail")
            } catch {
                XCTAssert((error as! ZolangError).line == line)
            }
        })
    }
    
    func testInit() {
        let code = "only \"some\" {\nlet i as number be 5\n}"
        let lineAtEnd = 3

        var context = ParserContext(file: "test.zolang")
        
        let tokens = code.zo.tokenize()
        
        do {
            let only = try Only(tokens: tokens, context: &context)
            XCTAssert(context.line == lineAtEnd)
            guard case let .combination(block1, block2) = only.codeBlock else {
                XCTFail()
                return
            }
            
            guard case .empty = block2,
                case let .variableDeclaration(decl) = block1 else {
                XCTFail()
                return
            }
            
            XCTAssert(decl.expression ~= .integerLiteral("5"))
            XCTAssert(decl.type == .primitive(.number))
            XCTAssert(decl.identifier == "i")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
