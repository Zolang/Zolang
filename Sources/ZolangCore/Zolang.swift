import Foundation

public final class Zolang {

    private static let dummyZolanDotJson = """
    {
      "buildSettings": [
        {
          "sourcePath": "./zolang/src",
          "stencilPath": "./zolang/templates/mylang",
          "buildPath": "./zolang/build/mylang",
          "separators": {
            "CodeBlock": "\\n"
          }
        }
      ]
    }
    """
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        guard arguments.count > 1 else {
            print("Thanks for using Zolang, available actions are:\n\n- init\n- build")
            exit(0)
        }
        
        let action = arguments[1]
        let validActions = [ "init", "build" ]
        guard validActions.contains(action) else {
            print("Encountered an invalid action \(arguments[1]), available actions are:\n\n- init\n- build")
            exit(1)
        }

        if action == "init" {
            try initProject()
        } else if action == "build" {
            try CodeGenerator(configPath: "./zolang.json").build()
        }
    }
    
    func initProject() throws {
        let fileManager = FileManager.default
        
        let directories: [URL] = [
            URL(fileURLWithPath: "zolang/src/mylang"),
            URL(fileURLWithPath: "zolang/build"),
            URL(fileURLWithPath: "zolang/templates")
        ]
        
        try directories.forEach { url in
            try fileManager.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        try Zolang.dummyZolanDotJson.write(to: URL(fileURLWithPath: "zolang.json"), atomically: true, encoding: .utf8)
    }
}
