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
    typealias Property = (Bool, String?, String, Type, Expression?)

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

    var failMock3: String {
        return """
        some as number
        
        static private name as text
        """
    }
    
    var failMock4: String {
        return """
        private static private some as number
        
        static name as text
        """
    }
    
    var failMock5: String {
        return """
        private static static some as number
        
        static name as text
        """
    }
    
    let mock1 = """
    name as text default "yey"
    friends as list of Person
    street as text
    private static house_number as number

    private address return text from () {
        return "${street} ${house_number}"
    }

    yell return text from () {
        return "YELLING!"
    }

    is_gamer as boolean
    """
    
    let expected1: (properties: [Property], functionReturnTypes: [Property]) = (
        [
            (false, nil, "name", .primitive(.text), .textLiteral("yey")),
            (false, nil, "friends", .list(.custom("Person")), nil),
            (false, nil, "street", .primitive(.text), nil),
            (true, "private", "house_number", .primitive(.number), nil),
            (false, nil, "is_gamer", .primitive(.boolean), nil),
        ],
        [
            (false, "private", "address", .primitive(.text), nil),
            (false, nil, "yell", .primitive(.text), nil)
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
            (failMock2, 7),
            (failMock3, 3),
            (failMock4, 1),
            (failMock5, 1)
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
        let validSamples: [(String, (properties: [Property], functionReturnTypes: [Property]), Int)] = [
            (mock1, expected1, 14)
        ]
        
        validSamples.forEach { (code, expected, lineAtEnd) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = code.zo.tokenize()
            
            do {
                let dlist = try DescriptionList(tokens: tokens, context: &context)
                zip(dlist.properties, expected1.properties).forEach({ first, second in
                    XCTAssert(first.isStatic == second.0)
                    XCTAssert(first.accessLimitation == second.1)
                    XCTAssert(first.name == second.2)
                    XCTAssert(first.type == second.3)
                })
                
                zip(dlist.functions, expected1.functionReturnTypes).forEach({ first, second in
                    XCTAssert(first.isStatic == second.0)
                    XCTAssert(first.accessLimitation == second.1)
                    XCTAssert(first.name == second.2)
                    XCTAssert(first.function.returnType == second.3)
                })
                
                XCTAssert(context.line == lineAtEnd)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
