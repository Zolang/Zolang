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
    var context: [String: Any] { get }
    init(tokens: [Token], context: inout ParserContext) throws
    
    func compile(buildSetting: Config.BuildSetting, fileManager fm: FileManager) throws -> String
}

extension Node {
    public static var stencilName: String {
        return String(describing: Self.self)
    }

    public var context: [String: Any] {
        let firstChar = String(Self.stencilName.first!)
        let suffixIndex = Self.stencilName.index(after: Self.stencilName.startIndex)
        let key = firstChar + String(Self.stencilName.suffix(from: suffixIndex))
        return [
            key: self
        ]
    }

    public func compile(buildSetting: Config.BuildSetting, fileManager fm: FileManager = .default) throws -> String {

        let loader = FileSystemLoader(paths: [ Path(buildSetting.stencilPath) ])
        let environment = Environment(loader: loader)

        let rendered = try environment.renderTemplate(name: "\(Self.stencilName).stencil", context: context)

        return rendered
    }
}
