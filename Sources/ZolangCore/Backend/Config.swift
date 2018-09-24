//
//  Config.swift
//  PathKit
//
//  Created by Þorvaldur Rúnarsson on 17/09/2018.
//

import Foundation

public struct Config: Codable {
    public struct BuildSetting: Codable {
        let sourcePath: String
        let stencilPath: String
        let buildPath: String
        let fileExtension: String
        let separators: [String: String]
    }

    let buildSettings: [BuildSetting]
    
    public init(filePath: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        self = try JSONDecoder()
            .decode(Config.self, from: data)
    }
    
    public init(buildSettings: [BuildSetting]) {
        self.buildSettings = buildSettings
    }
}
