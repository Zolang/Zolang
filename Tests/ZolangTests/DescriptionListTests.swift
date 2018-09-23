//
//  DescriptionListTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 13/09/2018.
//

import Foundation
import XCTest
import ZolangCore

class DescriptionListTests: XCTestCase {
    
    let propertyFailure = "house_number number"
    let functionFailure = "some return text from {}"
    
    var failMock1: String {
        return """
        name as text
        friends as list of Person
        street as text
        \(propertyFailure)
        """
    }
    
    var failMock2: String {
        return """
        
        
        some as number
        
        something_else as text
        
        \(functionFailure)
        """
    }
    
    let mock1 = """
    name as text
    friends as list of Person
    street as text
    house_number as number
    
    address return text from () {
        return "${street} ${house_number}"
    }

    yell return text from () {
        return "YELLING!"
    }

    is_gamer as boolean
    """
    
    let expected1: (properties: [(String, Type)], functionReturnTypes: [(String, Type)]) = (
        [
            ("name", .primitive(.text)),
            ("friends", .list(.custom("Person"))),
            ("street", .primitive(.text)),
            ("house_number", .primitive(.number)),
            ("is_gamer", .primitive(.boolean)),
        ],
        [
            ("address", .primitive(.text)),
            ("yell", .primitive(.text))
        ]
    )

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        
        let invalidSamples: [(String, Int)] = [
            (failMock1, 4),
            (failMock2, 7)
        ]
        
        invalidSamples.forEach { (code, line) in
            var context = ParserContext(file: "test.zolang")
            let tokenList = code.zo.tokenize()
            do {
                _ = try DescriptionList(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {
                XCTAssert((error as? ZolangError)?.line == line)
            }
        }
        
    }
    
    func testInit() {
        
        let validSamples: [(String, (properties: [(String, Type)], functionReturnTypes: [(String, Type)]), Int)] = [
            (mock1, expected1, 14)
        ]
        
        validSamples.forEach { (code, expected, lineAtEnd) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = code.zo.tokenize()
            
            do {
                let dlist = try DescriptionList(tokens: tokens, context: &context)
                zip(dlist.properties, expected1.properties).forEach({ first, second in
                    XCTAssert(first.name == second.0)
                    XCTAssert(first.type == second.1)
                })
                
                zip(dlist.functions, expected1.functionReturnTypes).forEach({ first, second in
                    XCTAssert(first.name == second.0)
                    XCTAssert(first.function.returnType == second.1)
                })
                
                XCTAssert(context.line == lineAtEnd)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
