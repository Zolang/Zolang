//
//  Logger.swift
//  ZolangCore
//
//  Created by Þorvaldur Rúnarsson on 24/09/2018.
//

import Foundation

enum ANSIColors: String {
    
    case error = "\u{001B}[0;31m"
    case warning = "\u{001B}[0;33m"
    case info = "\u{001B}[0;36m"
    case plain = "\u{001B}[0;39m"
    
    static func + (left: ANSIColors, right: String) -> String {
        return left.rawValue + right
    }
}

public struct Log {
    public static func info(_ message: String) {
        print(ANSIColors.info + message)
    }
    
    public static func plain(_ message: String) {
        print(ANSIColors.plain + message)
    }
    
    public static func error(_ message: String) {
        print(ANSIColors.error + message)
    }
    
    public static func warning(_ message: String) {
        print(ANSIColors.warning + message)
    }
}
