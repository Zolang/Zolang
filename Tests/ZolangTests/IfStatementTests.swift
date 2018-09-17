//
//  IfStatementTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 04/09/2018.
//

import Foundation
import XCTest
import ZolangCore

class IfStatementTests: XCTestCase {
    
    let validIfStatement1 = """
    if (some) {
        print("SOME")
    } else if (another) {
        print("ANOTHER")
    } else {
        print("OTHER")
    }
    """
    
    let validIfStatement2 = """
    if (expr) {
        print("👏🏻")
    } else if (true) {
        print("🤝")
    }
    """
    
    let validIfStatement3 = """
    if (expr) {
        print("👏🏻")
    }
    """
    
    let invalidIfStatement1 = """

    if (some)
    {
        
    } else {

    
    """
    
    let invalidIfStatement2 = """
    if (some) { } else if (other) {

    } else () {

    }
    """
    
    let invalidIfStatement3 = """
    if (some) {

    } else if (other) {

    } else if {

    }
    """
    
    
    var validIfStatementTestTuples: [(code: String, expectedIfListCount: Int, lineIndexAfterInit: Int, elseIsNil: Bool)]!
    var invalidIfStatementTestTuples: [Int: (code: String, expectedLine: Int)]!
    
    override func setUp() {
        super.setUp()
        
        self.validIfStatementTestTuples = [
            (validIfStatement1, 2, 6, false),
            (validIfStatement2, 2, 4, true),
            (validIfStatement3, 1, 2, true)
        ]
        
        self.invalidIfStatementTestTuples = [
            0: (invalidIfStatement1, 4),
            1: (invalidIfStatement2, 2),
            2: (invalidIfStatement3, 4)
        ]
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        self.invalidIfStatementTestTuples.forEach { (key, value) in
            let (code, expectedLine) = value
            
            var context = ParserContext(file: "test.zolang")
            
            let tokens = Parser(file: "test.zolang").tokenize(string: code)
            
            do {
                _ = try IfStatement(tokens: tokens, context: &context)
                XCTFail("\(key)")
            } catch {
                let line = (error as! ZolangError).line
                XCTAssert(line == expectedLine, "Line of failure for key, \(key); should be \(expectedLine) was \(line)")
            }
        }
    }

    func testInitialization() {
        self.validIfStatementTestTuples.forEach { (code, expectedIfListCount, lineIdxAfterInit, elseIsNil) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = Parser(file: "test.zolang").tokenize(string: code)
            
            do {
                let ifStmt = try IfStatement(tokens: tokens, context: &context)

                XCTAssert(context.line == lineIdxAfterInit)
                XCTAssert(ifStmt.ifList.count == expectedIfListCount)

                if elseIsNil {
                    XCTAssertNil(ifStmt.elseBlock)
                } else {
                    XCTAssertNotNil(ifStmt.elseBlock)
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
