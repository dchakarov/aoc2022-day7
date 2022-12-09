//
//  main.swift
//  No rights reserved.
//

import Foundation
import RegexHelper

func main() {
    let fileUrl = URL(fileURLWithPath: "./aoc-input")
    guard let inputString = try? String(contentsOf: fileUrl, encoding: .utf8) else { fatalError("Invalid input") }
    
    let lines = inputString.components(separatedBy: "\n")
        .filter { !$0.isEmpty }
    
    let root = File(name: "/", size: 0, isDirectory: true)
    var currentDirectory = root
    
    for line in lines {
        if line.hasPrefix("$") { // command
            if let newDirectory = parseCommand(line: line, currentDirectory: currentDirectory, rootDirectory: root) {
                currentDirectory = newDirectory
            }
        } else if line.hasPrefix("dir") { // directory
            currentDirectory.files.append(parseDirectory(line: line, currentDirectory: currentDirectory))
        } else { // file
            currentDirectory.files.append(parseFile(line: line))
        }
    }
    
    calculateSize(root)
//    customPrint(root)
    
//    maxTotalSize(root, limit: 100000)
//    print(counter)
    
    let totalSpace = 70000000
    let updateSpace = 30000000
    let usedSpace = root.size
    let neededSpace = updateSpace - (totalSpace - usedSpace)
    
    print(neededSpace)
    
    currentCandidate = root.size
    findDirectoryToDelete(root, targetSpace: neededSpace)
    
    print(currentCandidate)
}

@discardableResult
func calculateSize(_ file: File) -> Int {
    if file.files.isEmpty {
        return file.size
    }
    let size = file.files.reduce(0) { partialResult, currentFile in
        partialResult + calculateSize(currentFile)
    }
    file.size = size
    return size
}

func customPrint(_ directory: File, currentIndent: Int = 0) {
    let indent = String(Array(repeating: " ", count: currentIndent))
    let size = directory.isDirectory ? "[\(directory.size)]": "\(directory.size)"
    print("\(indent)\(directory.name) \(size)")
    if directory.files.isEmpty {
        return
    }
    for file in directory.files {
        customPrint(file, currentIndent: currentIndent + 2)
    }
}

var counter = 0 // part 1
var currentCandidate = 0 // part 2

func maxTotalSize(_ directory: File, limit: Int) { // part 1
    if directory.isDirectory && directory.size < limit { counter += directory.size }
    if directory.files.isEmpty {
        return
    }
    for file in directory.files {
        maxTotalSize(file, limit: limit)
    }
}

func findDirectoryToDelete(_ directory: File, targetSpace: Int) { // part 2
    if directory.isDirectory && directory.size > targetSpace && directory.size < currentCandidate { currentCandidate = directory.size }
    if directory.files.isEmpty {
        return
    }
    for file in directory.files {
        findDirectoryToDelete(file, targetSpace: targetSpace)
    }
}

func parseCommand(line: String, currentDirectory: File, rootDirectory: File) -> File? {
    if line == "$ ls" { return nil }
    let helper = RegexHelper(pattern: #"\$\s(\w+)\s(.*)"#)
    let result = helper.parse(line)
    let command = result[0]
    guard command == "cd" else { return nil }
    let newDirectory = result[1]
    switch newDirectory {
    case "..":
        return currentDirectory.parent
    case "/":
        return rootDirectory
    default:
        let targetDirectory = currentDirectory.files.filter { $0.name == newDirectory }.first
        if let targetDirectory { return targetDirectory }
        fatalError("No such directory: \(newDirectory)")
    }
}

func parseFile(line: String) -> File {
    let helper = RegexHelper(pattern: #"(\d+)\s(.*)"#)
    let result = helper.parse(line)
    let size = Int(result[0])!
    let name = result[1]
    return File(name: name, size: size)
}

func parseDirectory(line: String, currentDirectory: File) -> File {
    let helper = RegexHelper(pattern: #"dir\s(.*)"#)
    let result = helper.parse(line)
    let name = result[0]
    return File(name: name, size: 0, isDirectory: true, parent: currentDirectory)
}

main()

class File {
    var name: String
    var size: Int
    var isDirectory: Bool
    var parent: File?
    var files: [File]
    
    init(name: String, size: Int, isDirectory: Bool = false, parent: File? = nil, files: [File] = []) {
        self.name = name
        self.size = size
        self.isDirectory = isDirectory
        self.parent = parent
        self.files = files
    }
}
