import Foundation

public final class Zolang {
    private static let version = "0.1.12"
    
    private static let help = """
    USAGE: zolang [ACTION]

        HELP: The Zolang CLI is the compiler and template manager for the Zolang programming language

        ACTIONS:
              init                Initializes a new Zolang project with a ./zolang.json and some example code.
              build               Compiles Zolang based on the settings specified in ./zolang.json
              watch               Runs compiler in hot-reload mode, observeing file changes for source files at paths specified in ./zolang.json
    """

    private static let dummyZolangDotJson = """
    {
      "buildSettings": [
        {
          "sourcePath": "./.zolang/src/",
          "stencilPath": "./.zolang/templates/swift",
          "buildPath": "./.zolang/build/swift",
          "fileExtension": "swift",
          "separators": {
            "CodeBlock": "\\n"
          }
        },
        {
          "sourcePath": "./.zolang/src/",
          "stencilPath": "./.zolang/templates/kotlin",
          "buildPath": "./.zolang/build/kotlin",
          "fileExtension": "kt",
          "separators": {
            "CodeBlock": "\\n"
          }
        },
        {
          "sourcePath": "./.zolang/src/",
          "stencilPath": "./.zolang/templates/python2.7",
          "buildPath": "./.zolang/build/python2.7",
          "fileExtension": "py",
          "separators": {
            "CodeBlock": "\\n"
          }
        }
      ]
    }
    """

    private let arguments: [String]

    private var codeGenerator: CodeGenerator!
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        guard arguments.count > 1 else {
            Log.ascii()
            Log.info("Thanks for using Zolang \(Zolang.version)")
            Log.plain(Zolang.help)
            exit(0)
        }
        
        let action = arguments[1]
        let validActions = [ "init", "build", "watch" ]
        guard validActions.contains(action) else {
            Log.error("Encountered an invalid action \(arguments[1]) - See \"zolang help\" for details on usage")
            exit(1)
        }

        guard action != "init" else {
            try initProject()
            return
        }

        do {
            self.codeGenerator = try CodeGenerator(configPath: "./zolang.json")
        } catch {
            Log.error("Could not find file: \"zolang.json\"")
            exit(1)
        }

        if action == "build" {
            try codeGenerator.build()
        } else if action == "watch" {
            watch()
        }
    }

    func watch() {
        let sourceWatcher = SynchronousSourceWatcher(config: codeGenerator.config)
        sourceWatcher.watchForChangesSync {
            do {
                try self.codeGenerator.build()
            } catch {
                if let error = error as? ZolangError {
                    error.dump()
                } else {
                    Log.error(error.localizedDescription)
                }
            }
            
            Log.plain("---------------------------\nWatching... (CTRL + C to Stop)")
        }
    }
    
    func initProject() throws {
        func shell(_ command: String) -> String {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", command]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.launch()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
            
            return output
        }
        
        let fileManager = FileManager.default
        
        let directories: [URL] = [
            URL(fileURLWithPath: ".zolang/src"),
            URL(fileURLWithPath: ".zolang/build"),
            URL(fileURLWithPath: ".zolang/templates/swift")
        ]
        
        Log.plain("Creating folder structure ...")

        try directories.forEach { url in
            try fileManager.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        
        try "let world as text be \"world\"\nprint(\"Hello ${world}\")"
            .write(to: URL(fileURLWithPath: ".zolang/src/example.zolang"),
                   atomically: true,
                   encoding: .utf8)
        
        Log.plain("Fetching templates ...")
        Log.plain(shell("git clone https://github.com/Zolang/ZolangTemplates"))

        [ "swift", "kotlin", "python2.7" ]
            .forEach { language in
                Log.plain(shell("mv ZolangTemplates/\(language) .zolang/templates"))
            }
        
        Log.plain(shell("rm -rf ZolangTemplates"))
        Log.info("Done")
        
        try Zolang.dummyZolangDotJson.write(to: URL(fileURLWithPath: "zolang.json"), atomically: true, encoding: .utf8)
    }
}
