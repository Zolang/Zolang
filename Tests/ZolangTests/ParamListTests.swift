//
//  ParamListTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 09/09/2018.
//

import Foundation
import XCTest
import ZolangCore

class ParamListTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        let invalidSamples: [(String, Int)] = [
            ("list \nof, num as number, t as text", 0),
            ("l\n as list \nof, \nnumber, text", 2),
            ("num as number, some as \nlist of number\n, game as \n.", 2)
        ]
        
        invalidSamples.forEach({ (code, line) in
            var context = ParserContext(file: "test.zolang")
            let tokens: [Token] = Lexer().tokenize(string: code)
            do {
                
                _ = try ParamList(tokens: tokens, context: &context)
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
            ("num as number, name as SomeType, l as list of SomeType", expected1, 0),
            ("\nl as list \nof\n text, t as text", expected2, 3),
            ("l as\n list of list of\n text", expected3, 2)
        ]
        
        validSamples.forEach { (code, expected, lineAtEnd) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = Lexer().tokenize(string: code)
            
            do {
                let paramList = try ParamList(tokens: tokens, context: &context)
                zip(paramList.params, expected).forEach({ first, second in
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
