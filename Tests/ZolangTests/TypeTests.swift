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
            ("list of", 1),
            ("some of number", 1),
            ("list of \nsome of text", 2),
            ("\nlist\n\n of", 4),
            ("make some.another be something", 1)
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
        let validSamples: [(String, Type, Int)] = [
            ("\nnumber\n", .primitive(.number), 3),
            ("\nlist of number", .list(.primitive(.number)), 2),
            ("list of list of text\n", .list(.list(.primitive(.text))), 2),
            ("\n\ntext", .primitive(.text), 3)
        ]
        
        validSamples.forEach { (code, expected, lineAtEnd) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = code.zo.tokenize()

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
