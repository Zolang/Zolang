//
//  TypeTests.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 09/09/2018.
//

import Foundation
import XCTest
import ZolangCore

class TypeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        let invalidSamples: [(String, Int)] = [
            ("list of", 0),
            ("some of number", 0),
            ("list of \nsome of text", 1),
            ("\nlist\n\n of", 3),
            ("make some.another be something", 0)
        ]
        
        invalidSamples.forEach({ (code, line) in
            var context = ParserContext(file: "test.zolang")
            do {
                _ = try Type(tokens: Lexer().tokenize(string: code), context: &context)
                XCTFail("Type init should fail")
            } catch {
                XCTAssert((error as! ZolangError).line == line)
            }
        })
    }
    
    func testInit() {
        let validSamples: [(String, Type, Int)] = [
            ("\nnumber", .primitive(.number), 1),
            ("\nlist of number", .list(.primitive(.number)), 1),
            ("list of list of text", .list(.list(.primitive(.text))), 0),
            ("\n\ntext", .primitive(.text), 2)
        ]
        
        validSamples.forEach { (code, expected, lineAtEnd) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = Lexer().tokenize(string: code)

            do {
                let type = try Type(tokens: tokens, context: &context)
                XCTAssert(type == expected)
                XCTAssert(context.line == lineAtEnd)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
