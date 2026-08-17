//
//  DependencyListProcessor.swift
//  DependencyGuard
//
//  Created by Yusuf Tayyip Özgül on 3.08.2026.
//

import Subprocess
import Foundation

struct DependencyListProcessor {
    func dependencyTree(from spmRoot: String) async throws -> [SPMDependency] {
        var standartOutput: String = ""
        var standartError: String = ""
        
        let result = try await run(.name("swift"),
                                   arguments: ["package", "show-dependencies", "--format", "json"],
                                   workingDirectory: .init(spmRoot),
                                   input: .none,
                                   output: .sequence,
                                   error: .sequence) { execution in
            for try await line in execution.standardError.strings() {
                standartError += line + "\n"
            }
            for try await line in execution.standardOutput.strings() {
                standartOutput += line + "\n"
            }
        }
        
        guard result.terminationStatus == .exited(0) else {
            throw DependencyListProcessorError.failedToExportDependencyList(standartError)
        }
        
        let outputData = standartOutput.data(using: .utf8) ?? Data()
        let dependencyList = try JSONDecoder().decode(SPMDependencyList.self, from: outputData)
        return dependencyList.dependencies
    }
}

enum DependencyListProcessorError: LocalizedError, CustomDebugStringConvertible {
    case failedToExportDependencyList(String)
    
    var errorDescription: String? {
        switch self {
        case .failedToExportDependencyList:
            "Failed to export dependency list"
        }
    }
    
    var debugDescription: String {
        switch self {
        case .failedToExportDependencyList(let standartError):
            "Failed to export dependency list \n " + standartError
        }
    }
}
