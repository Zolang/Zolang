//
//  CompilationEnvironment.swift
//  PathKit
//
//  Created by Thorvaldur Runarsson on 31/12/2018.
//

import Foundation

struct CompilationEnvironment {
    static var templates: [URL: String] = [:]

    static func template(buildSetting: Config.BuildSetting, nodeName: String) throws -> String {
        let url = URL(fileURLWithPath: buildSetting.stencilPath)
            .appendingPathComponent("\(nodeName).stencil")

        if templates[url] == nil {
           templates[url] = try String(contentsOf: url, encoding: .utf8)
        }

        return templates[url]!
    }
}
