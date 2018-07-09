//
//  ZolangError.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

struct ZolangError: Error {
    let type: ErrorType
    let file: String
    let line: Int
    
    var localizedDescription: String {
        return "Error in file: \(file) - line: \(line) - message: \(type.localizedDescription)"
    }
}
