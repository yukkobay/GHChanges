//
//  Command.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/03.
//

import Foundation

enum Command: String {
    case git = "/usr/bin/git"
    case pwd = "/bin/pwd"
}

@discardableResult
func execute(_ command: Command, _ arguments: String..., at path: String? = nil, print: Bool = false) throws -> String? {

    let process = Process()
    let pipe = Pipe()
    process.standardOutput = pipe

    process.launchPath = command.rawValue
    process.arguments = arguments

    if let path = path {
        if path.hasPrefix("/") {
            process.currentDirectoryPath = path
        } else {
            process.currentDirectoryPath += "./\(path)"
        }
    }

    try process.run()
    process.waitUntilExit()

    let output = String(
        data: pipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    )

    if let output = output, print {
        Swift.print(output)
    }

    if process.terminationStatus != 0 {
        throw GHChangesError.processError(process.terminationStatus)
    }

    return output
}
