//
//  Log.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation
import Core

struct Log {
    
    private init() {}
    
    private static let wrappedLogger = SubsystemCategoryLogger(
        subsystem: "KozBon",
        category: "Log"
    )
    
    static func log(
        _ message: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        let contextString = self.stackCallerClassAndMethodString(file: file, line: line, function: function)
        self.wrappedLogger.debug("\(contextString) - \(message)")
    }
    
    static func extendedLog(
        _ message: String,
        emoji: String = "✅✅✅",
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        let contextString = self.stackCallerClassAndMethodString(file: file, line: line, function: function)
        self.wrappedLogger.debug("<<< \(emoji) \(contextString) : \(message) \(emoji) >>>")
    }
    
    static func logMethodExecution(
        emoji: String = "✅✅✅",
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        let contextString = self.stackCallerClassAndMethodString(file: file, line: line, function: function)
        self.wrappedLogger.debug("<<< \(emoji) \(contextString) \(emoji) >>>")
    }
    
    static func logFullStackData() {
        let sourceString = Thread.callStackSymbols[1]
        let separatorSet = CharacterSet.init(charactersIn: " -[]+?.,")
        let array = sourceString.components(separatedBy: separatorSet)
        print("****** Stack: \(array[0])")
        print("****** Framework: \(array[1])")
        print("****** Memory address: \(array[2])")
        print("****** Class caller: \(array[3])")
        print("****** Function caller: \(array[4])")
        print("****** Line caller: \(array[5])")
    }
    
    static func stackCallerClassAndMethodString(
        file: String,
        line: Int,
        function: String
    ) -> String {
        let lastPathComponent = (file as NSString).lastPathComponent
        return "\(lastPathComponent):\(line) : \(function)"
    }
}
