//
//  Log.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation

struct Log : Loggable {
  private init() {}
}

protocol Loggable {}
extension Loggable {
  
  static func log(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
    print("\(self.stackCallerClassAndMethodString(file: file, line: line, function: function)) - \(message)")
  }
  
  static func extendedLog(_ message: String, emoji: String = "✅✅✅", file: String = #file, line: Int = #line, function: String = #function) {
    print("<<< \(emoji) \(self.stackCallerClassAndMethodString(file: file, line: line, function: function)) : \(message) \(emoji) >>>")
  }
  
  static func logMethodExecution(emoji: String = "✅✅✅", file: String = #file, line: Int = #line, function: String = #function) {
    print("<<< \(emoji) \(self.stackCallerClassAndMethodString(file: file, line: line, function: function)) \(emoji) >>>")
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
  
  static func stackCallerClassAndMethodString(file: String, line: Int, function: String) -> String {
    let lastPathComponent = (file as NSString).lastPathComponent
    return "\(lastPathComponent):\(line) : \(function)"
  }
}
