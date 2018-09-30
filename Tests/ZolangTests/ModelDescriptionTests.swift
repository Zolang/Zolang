//
//  ModelDescriptionTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 17/09/2018.
//

import Foundation
import XCTest
import ZolangCore

class ModelDescriptionTests: XCTestCase {
    
    let propertyFailure = "house_number number"
    let functionFailure = "some return text from {}"
    
    var failMock1: String {
        return """
        describe Person {
            name as text
            friends as list of Person
            street as text
            \(propertyFailure)
        }
        """
    }
    
    var failMock2: String {
        return """
        
        describe Some {
            some as number
        
            something_else as text
        
            \(functionFailure)
        }
        
        """
    }
    
    let mock1 = """
    describe Person {
        name as text
        friends as list of Person
        street as text
        house_number as number default 5.0
        
        address return text from () {
            return "${street} ${house_number}"
        }

        is_gamer as boolean
    }
    """
    
    let expected1: (name: String, properties: [(String, Type, Expression?)], functionReturnTypes: [(String, Type)]) = (
        "Person",
        [
            ("name", .primitive(.text), nil),
            ("friends", .list(.custom("Person")), nil),
            ("street", .primitive(.text), nil),
            ("house_number", .primitive(.number), .floatLiteral("5.0")),
            ("is_gamer", .primitive(.boolean), nil),
        ],
        [
            ("address", .primitive(.text))
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
            (failMock1, 5),
            (failMock2, 7)
        ]
        
        invalidSamples.forEach { (code, line) in
            var context = ParserContext(file: "test.zolang")
            let tokenList = code.zo.tokenize()
            do {
                _ = try ModelDescription(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {
                XCTAssert((error as? ZolangError)?.line == line)
            }
        }
        
    }
    
    func testInit() {
        
        let validSamples: [(String, (name: String, properties: [(String, Type, Expression?)], functionReturnTypes: [(String, Type)]), Int)] = [
            (mock1, expected1, 12)
        ]
        
        validSamples.forEach { (code, expected, lineAtEnd) in
            var context = ParserContext(file: "test.zolang")
            
            let tokens = code.zo.tokenize()
            
            do {
                let md = try ModelDescription(tokens: tokens, context: &context)

                XCTAssert(expected.name == md.name)

                zip(md.descriptionList!.properties, expected1.properties).forEach({ first, second in
                    XCTAssert(first.name == second.0)
                    XCTAssert(first.type == second.1)
                    
                    if let defaultValue = first.defaultValue {
                        XCTAssert(defaultValue ~= second.2!)
                    } else {
                        XCTAssertNil(second.2)
                    }
                })
                
                zip(md.descriptionList!.functions, expected1.functionReturnTypes).forEach({ first, second in
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
