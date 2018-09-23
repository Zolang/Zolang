//
//  Node.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 27/06/2018.
//

import Foundation
import Stencil
import PathKit

public protocol Node {
    static var stencilName: String { get }

    init(tokens: [Token], context: inout ParserContext) throws
    
    func getContext(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> [String: Any]
    func compile(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> String
}

extension Node {
    public static var stencilName: String {
        return String(describing: Self.self)
    }

    public func compile(buildSetting: Config.BuildSetting, fileManager fm: FileManager = .default) throws -> String {

        let url = URL(fileURLWithPath: buildSetting.stencilPath)
            .appendingPathComponent("\(Self.stencilName).stencil")

        let environment = Environment()
        do {
            let templateString = try String(contentsOf: url, encoding: .utf8)
            let rendered = try environment.renderTemplate(string: templateString,
                                                          context: try getContext(buildSetting: buildSetting, fileManager: fm))
            return rendered.zo.trimmed()
        } catch {
            print("Error in node: \(String(describing: Self.self))")
            throw error
        }

        
    }
}
