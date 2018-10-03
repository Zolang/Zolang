//
//  FunctionTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 09/09/2018.
//

import Foundation
import XCTest
import ZolangCore

class FunctionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        let invalidSamples: [(String, Int)] = [
            ("function return text from (name as some)", 1),
            ("text from () {", 1),
            ("list of \nnumber \nfrom (num as )\n", 3),
            ("number from\n {\n}", 2),
            ("number from () {", 1)
        ]
        
        invalidSamples.forEach({ (code, line) in
            var context = ParserContext(file: "test.zolang")
            let tokens: [Token] = code.zo.tokenize()
            do {
                _ = try Function(tokens: tokens, context: &context)
                XCTFail("Type init should fail")
            } catch {
                XCTAssert((error as! ZolangError).line == line)
            }
        })
    }
    
    func testInit() {
        let expected1: [(String, Type)] = [
            ("num", .primitive(.number)),
            ("name", .custom("SomeType")),
            ("l", .list(.custom("SomeType"))),
            ]
        
        let expected2: [(String, Type)] = [
            ("l", .list(.primitive(.text))),
            ("t", .primitive(.text))
        ]
        
        let expected3: [(String, Type)] = [
            ("l", .list(.list(.primitive(.text))))
        ]
        
        let validSamples: [(String, [(String, Type)], Int)] = [
            ("text from (num as number, name as SomeType, l as list of SomeType) {}", expected1, 1),
            ("list of number from (\nl as list \nof\n text, t as text) {}", expected2, 4),
            ("list of list of text from (l as\n list of list of\n text) {}", expected3, 3)
        ]
        
        validSamples.forEach { (code, expected, lineAtEnd) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = code.zo.tokenize()
            
            do {
                let function = try Function(tokens: tokens, context: &context)
                zip(function.params!.params, expected).forEach({ first, second in
                    XCTAssert(first.name == second.0)
                    XCTAssert(first.type == second.1)
                })

                XCTAssert(context.line == lineAtEnd)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
