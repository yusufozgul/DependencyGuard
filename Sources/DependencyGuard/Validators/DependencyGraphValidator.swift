import Foundation

struct DependencyGraphValidator {
    func validate(source: [DependencyGraph], target: [DependencyGraph]) -> [DependencyValidationIssue] {
        let sourceDependencies = source.flattenedByIdentity
        let targetDependencies = target.flattenedByIdentity
        
        return sourceDependencies.keys
            .sorted()
            .flatMap { identity -> [DependencyValidationIssue] in
                guard let source = sourceDependencies[identity],
                      let target = targetDependencies[identity]
                else { return [] }
                
                return validate(source: source, target: target)
            }
    }
    
    private func validate(source: DependencyGraph, target: DependencyGraph) -> [DependencyValidationIssue] {
        switch (source.type, target.type) {
        case let (.remotePackage(sourceURL, sourceVersion), .remotePackage(targetURL, targetVersion)):
            return validateURLs(identity: source.identity,
                                sourceURL: sourceURL,
                                targetURL: targetURL)
                + validateVersions(identity: source.identity,
                                   sourceVersion: sourceVersion,
                                   targetVersion: targetVersion)
            
        case let (.remoteBinary(sourceURL, sourceChecksum), .remoteBinary(targetURL, targetChecksum)):
            let checksumIssues: [DependencyValidationIssue] = sourceChecksum == targetChecksum
                ? []
                : [.error(identity: source.identity,
                          message: "Binary checksum differs (source: \(sourceChecksum), target: \(targetChecksum))")]

            return validateURLs(identity: source.identity,
                                sourceURL: sourceURL,
                                targetURL: targetURL) + checksumIssues
            
        case (.localBinary, .localBinary):
            return []
            
        default:
            return [
                .error(identity: source.identity,
                       message: "Dependency type differs between source and target")
            ]
        }
    }

    private func validateURLs(identity: String, sourceURL: String, targetURL: String) -> [DependencyValidationIssue] {
        guard sourceURL != targetURL else { return [] }

        return [
            .warning(identity: identity,
                     message: "Dependency URL differs (source: \(sourceURL), target: \(targetURL))")
        ]
    }
    
    private func validateVersions(identity: String, sourceVersion: String, targetVersion: String) -> [DependencyValidationIssue] {
        guard let source = SemanticVersion(sourceVersion),
              let target = SemanticVersion(targetVersion)
        else {
            return [
                .error(identity: identity,
                       message: "Invalid semantic version (source: \(sourceVersion), target: \(targetVersion))")
            ]
        }
        
        if source == target {
            return []
        }
        
        if source > target && source.major == target.major {
            return [
                .warning(identity: identity,
                         message: "Source version \(sourceVersion) is newer than target version \(targetVersion)")
            ]
        }
        
        return [
            .error(identity: identity,
                   message: "Target version \(targetVersion) is not compatible with source version \(sourceVersion)")
        ]
    }
}

struct DependencyValidationIssue: Sendable, Equatable, CustomStringConvertible {
    let severity: DependencyValidationSeverity
    let identity: String
    let message: String
    
    var description: String {
        "\(severity.rawValue) \(identity): \(message)"
    }
    
    static func warning(identity: String, message: String) -> Self {
        Self(severity: .warning, identity: identity, message: message)
    }
    
    static func error(identity: String, message: String) -> Self {
        Self(severity: .error, identity: identity, message: message)
    }
    
    enum DependencyValidationSeverity: String, Sendable, Equatable {
        case warning = "WARNING"
        case error = "ERROR"
    }
}
