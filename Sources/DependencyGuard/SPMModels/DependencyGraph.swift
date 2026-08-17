//
//  DependencyGraph.swift
//  DependencyGuard
//
//  Created by Yusuf Tayyip Özgül on 3.08.2026.
//

import Foundation

struct DependencyGraph: Codable, Sendable, Equatable, Hashable {
    let identity: String
    let name: String
    let type: DependencyGraphDependencyType
    let dependencies: [DependencyGraph]
}

extension [DependencyGraph] {
    func filtered(using selection: XcodeProjectDependencySelection) -> [DependencyGraph] {
        filter { $0.isSelected(using: selection) }.map { $0.filterDependencies(using: selection) }
    }
}

private extension DependencyGraph {
    func isSelected(using selection: XcodeProjectDependencySelection) -> Bool {
        switch type {
        case .remotePackage:
            return selection.packageIdentities.contains(identity.lowercased())
                || selection.packageProductNames.contains(name.lowercased())
                || containsLinkedArtifact(using: selection)
                || dependencies.contains { $0.isSelected(using: selection) }
        case .localBinary, .remoteBinary:
            return selection.linkedArtifactNames.contains(name)
        }
    }

    func containsLinkedArtifact(using selection: XcodeProjectDependencySelection) -> Bool {
        selection.linkedArtifactNames.contains(name) || dependencies.contains { $0.containsLinkedArtifact(using: selection) }
    }

    func filterDependencies(using selection: XcodeProjectDependencySelection) -> DependencyGraph {
        guard case .remotePackage = type, !selection.linkedArtifactNames.contains(name) else { return self }

        let filteredDependencies = dependencies.compactMap { dependency -> DependencyGraph? in
            switch dependency.type {
            case .remotePackage:
                dependency.filterDependencies(using: selection)
            case .localBinary, .remoteBinary:
                selection.linkedArtifactNames.contains(dependency.name) ? dependency : nil
            }
        }

        return DependencyGraph(identity: identity,
                               name: name,
                               type: type,
                               dependencies: filteredDependencies)
    }
}

enum DependencyGraphDependencyType: Codable, Sendable, Equatable, Hashable {
    case remotePackage(url: String, version: String)
    case remoteBinary(url: String, checksum: String)
    case localBinary(path: String)

    var redacted: DependencyGraphDependencyType {
        switch self {
        case let .remotePackage(url, version):
            .remotePackage(url: redact(originUrl: url), version: version)
        case let .remoteBinary(url, checksum):
            .remoteBinary(url: redact(originUrl: url), checksum: checksum)
        case .localBinary:
            self
        }
    }
}

extension [DependencyGraph] {
    var flattenedByIdentity: [String: DependencyGraph] {
        reduce(into: [:]) { flattened, dependency in
            if flattened[dependency.identity] == nil {
                flattened[dependency.identity] = dependency
            }

            flattened.merge(dependency.dependencies.flattenedByIdentity,
                            uniquingKeysWith: { current, _ in current })
        }
    }
}

extension DependencyGraphDependencyType {
    nonisolated(unsafe) static var domains: Set<String> = []
    func redact(originUrl: String) -> String {
        guard var url = URLComponents(string: originUrl),
              let host = url.host,
              Self.domains.contains(host) else { return originUrl }
        
        url.host = "REDACTED"
        
        return url.string ?? originUrl
    }
}
