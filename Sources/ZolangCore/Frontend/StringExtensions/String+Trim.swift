//
//  String+Trim.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 19/09/2018.
//

import Foundation

extension ZolangExtensions where Base == String {
    func trimmed() -> String {
        return base.trimmingCharacters(in: .newlines)
    }
}
