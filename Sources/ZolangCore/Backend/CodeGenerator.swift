//
//  CodeGenerator.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 17/09/2018.
//

import Foundation

public typealias AST = [CodeBlock]

public struct CodeGenerator {

    let config: Config
    
    private let fileManager = FileManager.default

    public init(configPath: String) throws {
        self.config = try Config(filePath: configPath)
    }
    
    func build() throws {
        Log.info("Compiling Zolang...")

        var hasErrors = false
        
        var syntaxTrees: [URL: AST] = [:]
        
        let writingQueue = DispatchQueue(label: "com.Zolang.writeToFile")
        
        try self.config.buildSettings
            .forEach { setting in
                try fileManager
                    .listFiles(path: setting.sourcePath)
                    .forEach { url in
                        if syntaxTrees[url] == nil {
                            let parser = Parser(file: url)
                            syntaxTrees[url] = try parser.parse()
                        }

                        let folderURL = URL(fileURLWithPath: setting.buildPath)
                        let fileName = url.lastPathComponent
                        let toURL = folderURL.appendingPathComponent(fileName)
                            .deletingPathExtension()
                            .appendingPathExtension(setting.fileExtension)
                        do {
                            try fileManager.createDirectory(atPath: folderURL.path,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                        } catch {}

                        Log.plain("Compiling \(fileName) to \(toURL.path)")
                        
                        do {
                            // first clear file
                            try "".write(to: toURL, atomically: true, encoding: .utf8)
                            
                            let fileHandle = try FileHandle(forWritingTo: toURL)
                            
                            var isFirst = true
                            try syntaxTrees[url]?.forEach { block in
                                let compiledBlock = try block.compile(buildSetting: setting, fileManager: self.fileManager)
                                if isFirst == false {
                                    if let separator = setting.separators["CodeBlock"] {
                                        fileHandle.write(separator.data(using: .utf8)!)
                                    }
                                } else {
                                    isFirst = false
                                }
                                fileHandle.write(compiledBlock.data(using: .utf8)!)
                            }
                            fileHandle.closeFile()
                        } catch {
                            hasErrors = true
                            Log.error("Error: \(error.localizedDescription)")
                        }
                    }
            }
        
        guard !hasErrors else { exit(1) }
        Log.info("Success!")
        
    }
}
