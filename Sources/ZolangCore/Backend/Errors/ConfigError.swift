//
//  ConfigError.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 17/09/2018.
//

import Foundation

enum ConfigError: Error {
    case invalidBuildPath(String)
    case invalidSourcePath(String)
    case invalidStencilPath(String)
    case missingSeparator(String)
    case invalidJSON
}
