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
        if (true) {
            print(👏🏻)
        }
    }
    """
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {

    }

    func testInitialization() {
        do {
            var context = ParserContext(file: "zolang.test")
            let ifStatement = try IfStatement(tokens: Lexer().tokenize(string: validIfStatement1),
                                              context: &context)
            XCTAssert(ifStatement.ifList.count == 2)
            XCTAssertNotNil(ifStatement.elseBlock)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
