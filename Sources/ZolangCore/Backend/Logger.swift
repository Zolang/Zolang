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
    static var asciiArt = """


                       @@@     @
                      @###+@  `##
                    @+++##+#+@+@@;
                 `@++'#'#+##+#@#@;
                 `#++++++####+##@;
     :::::::     #+#,...,######@@;    ;;          ;;     ;;     ;;     ';;;;
     ;;;;;;;    `'+'.::.,+;;;#+##;    ;;          :;     ;;     ;;     ;;;;;
     :::::;;    `;+':';,,+;#;####     ;;       .,,``,,`  ;;,,.  ;;   ,, ````
         .;;    `+;+....,####@##;     ;;       ,;;  ';`  ;;;;.  ;;   ;;
         .;;     +,'....@#######      ;;       ,;;  ';`  ;;;;.  ;;   ;;
       ';.       `.:...:.####@#;      ;;       ,;;;;;;`  ;;  `;;;;   ;;  ,;;
       ';.        +.,,.'@@#####       ;;       ,;;;;;;`  ;;  `;;;;   ;;  ,;;
     ..```        +..,..,######       ;;       ,;;  ';`  ;;     ;;   ;;  ,;;
     ;;           `.....,+####;       ;;       ,;;  ';`  ;;     ;;   :;  ,;;
     ;;            '....,#####        ;;.....  ,;;  ';`  ;;     ;;   .......
     ;;;;;;;       `.,.+:#@##;        ;;;;;;;  ,;;  ';`  ;;     ;;     ;;`
     :;;;;;;        +.,';#@##;        ';;;;;'  ,';  ';.  ;;     ';     ';`
                    +...,###+
                     @..,###'
                      `',+'


    """
    
    public static func ascii() {
        print(ANSIColors.plain + asciiArt)
    }
    public static func info(_ message: String, terminator: String = "\n") {
        print(ANSIColors.info + message, terminator: terminator)
    }
    
    public static func plain(_ message: String, terminator: String = "\n") {
        print(ANSIColors.plain + message, terminator: terminator)
    }
    
    public static func error(_ message: String, terminator: String = "\n") {
        print(ANSIColors.error + message, terminator: terminator)
    }
    
    public static func warning(_ message: String, terminator: String = "\n") {
        print(ANSIColors.warning + message, terminator: terminator)
    }
}
