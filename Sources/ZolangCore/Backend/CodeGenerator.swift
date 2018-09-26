//
//  CodeGenerator.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 17/09/2018.
//

import Foundation

public struct CodeGenerator {

    let config: Config
    
    private let fileManager = FileManager.default

    public init(configPath: String) throws {
        self.config = try Config(filePath: configPath)
    }
    
    func build() throws {
        Log.info("Compiling Zolang...")

        var hasErrors = false

        let parsed = try self.config.buildSettings
            .map { setting -> (setting: Config.BuildSetting, syntaxTrees: [(String, CodeBlock)]) in
                let syntaxTrees = try fileManager
                    .listFiles(path: setting.sourcePath)
                    .map { url -> (String, CodeBlock) in
                        let parser = Parser(file: url)
                        return (url.lastPathComponent, try parser.parse())
                    }

                return (setting, syntaxTrees)
            }
            
        parsed.forEach { arg in
            let (setting, syntaxTrees) = arg

            syntaxTrees.forEach { fileName, ast in
                let url = URL(fileURLWithPath: setting.buildPath)

                let toURL = url.appendingPathComponent(fileName)
                    .deletingPathExtension()
                    .appendingPathExtension(setting.fileExtension)
                
                Log.plain("Compiling \(fileName) to \(toURL.path)")
                
                do {
                    let generated = try ast.compile(buildSetting: setting, fileManager: self.fileManager)
                    
                    do {
                        try fileManager.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
                    } catch {}
                    
                    try generated.write(to: toURL, atomically: true, encoding: .utf8)
                    
                    Log.plain("Finished compiling to \(toURL.path)")

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
