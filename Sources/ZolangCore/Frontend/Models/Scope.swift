//
//  Scope.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public class Scope {
    private var validIdentifiers: [String: Type]
    private var validTypes: [Type]
    
    public init() {
        self.validIdentifiers = [:]
        self.validTypes = []
    }
    
    public func add(type: Type) {
        if self.validTypes.contains(type) == false {
            self.validTypes.append(type)
        }
    }
    
    public func add(identifier: String, type: Type) throws {
        self.validIdentifiers[identifier] = type
    }
}
