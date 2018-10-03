//
//  FileManager+Helpers.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 17/09/2018.
//

import Foundation

extension FileManager {
    func listFiles(path: String) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls = [URL]()
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }
            var relativeURL: URL
            if #available(OSX 10.11, *) {
                relativeURL = URL(fileURLWithPath: s, relativeTo: baseurl)
            } else {
                // Fallback on earlier versions
                relativeURL = URL(fileURLWithPath: s)
            }
            let url = relativeURL.absoluteURL
            urls.append(url)
        })
        return urls
    }
    
    func listSourceFiles(_ config: Config) -> [URL] {
        return config.buildSettings
            .map { FileManager.default.listFiles(path: $0.sourcePath) }
            .reduce([], +)
    }
}
