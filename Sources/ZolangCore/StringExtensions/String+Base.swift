//
//  String+Base.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/05/2018.
//

import Foundation

extension String {
    public var zo: Base<String> {
        return Base<String>(self)
    }
}
