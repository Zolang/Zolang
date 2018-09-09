//
//  Scope.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public class Scope {
    let level: Int
    private var validIdentifiers: [String: Type]
    private var validTypes: [Type]
    
    public init(parent: Scope? = nil) {
        guard let parent = parent else {
            self.level = 0
            self.validIdentifiers = [:]
            self.validTypes = []
            return
        }
        
        self.level = parent.level + 1
        self.validIdentifiers = parent.validIdentifiers
        self.validTypes = parent.validTypes
    }
    
    public init(copying scope: Scope) {
        self.level = scope.level
        self.validIdentifiers = scope.validIdentifiers
        self.validTypes = scope.validTypes
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
