//
//  WorkspaceStateProcessor.swift
//  DependencyGuard
//
//  Created by Yusuf Tayyip Özgül on 3.08.2026.
//

import Foundation

struct WorkspaceStateProcessor {
    func xcFrameworks(from spmRoot: String) async throws -> [SPMArtifact] {
        let fileUrl = URL(filePath: spmRoot)
            .appending(path: ".build")
            .appending(path: "workspace-state.json")
        return try xcFrameworks(from: fileUrl)
    }

    func xcFrameworks(from fileURL: URL) throws -> [SPMArtifact] {
        let fileData = try Data(contentsOf: fileURL)
        let workspaceState = try JSONDecoder().decode(WorkspaceState.self, from: fileData)
        return workspaceState.object.artifacts
    }
}
