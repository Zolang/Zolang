//
//  VariableMutationTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 23/08/2018.
//

import Foundation
import XCTest
import ZolangCore

class VariableMutationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        var context = ParserContext(file: "test.zolang")
        
        let invalidSamples: [String] = [
            "make some \n be something",
            "make \n some be something",
            "make some. be something",
            "make some..another be something",
            "make some some be something",
            "make some.some. be something"
        ]
        
        let tokens = invalidSamples
            .map(Parser(file: "test.zolang").tokenize(string:))
        
        for tokenList in tokens {
            do {
                _ = try VariableMutation(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {}
        }
    }
    
    func testVariableMutation() {
        
        let samples: [(String, [String], String, Int)] = [
            ("make some be something", ["some"], "something", 0),
            ("make some.someOther be \nsomething", ["some", "someOther"], "something", 1),
            ("make some\n.\nanother.another be \n\nyetAnother", ["some", "another", "another"], "yetAnother", 4)
        ]

        for testTuple in samples {
            let (code, expectedIdentifiers, expectedResult, endOfLine) = testTuple
            
            var context = ParserContext(file: "test.zolang")
            let tokenList = Parser(file: "test.zolang").tokenize(string: code)
            
            do {
                let mutation = try VariableMutation(tokens: tokenList, context: &context)
                XCTAssert(context.line == endOfLine)

                XCTAssert(mutation.identifiers == expectedIdentifiers)

                guard case let .identifier(actualResult) = mutation.expression else {
                    XCTFail("VariableMutation resulted in wrong expression")
                    return
                }
                
                XCTAssert(actualResult == expectedResult)
            } catch {
                XCTFail("Should not fail to create VariableMutation")
            }
        }
    }
}
