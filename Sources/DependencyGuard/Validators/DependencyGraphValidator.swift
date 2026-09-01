import Foundation

struct DependencyGraphValidator {
    private let skippableVersionValues: Set<String> = ["unspecified"]

    func validate(
        source: [DependencyGraph],
        target: [DependencyGraph],
        sourceLabel: String = "source",
        targetLabel: String = "target"
    ) -> [DependencyValidationIssue] {
        let sourceDependencies = source.flattenedByIdentity
        let targetDependencies = target.flattenedByIdentity
        
        return sourceDependencies.keys
            .sorted()
            .flatMap { identity -> [DependencyValidationIssue] in
                guard let source = sourceDependencies[identity],
                      let target = targetDependencies[identity]
                else { return [] }
                
                return validate(source: source, target: target, sourceLabel: sourceLabel, targetLabel: targetLabel)
            }
    }
    
    private func validate(
        source: DependencyGraph,
        target: DependencyGraph,
        sourceLabel: String,
        targetLabel: String
    ) -> [DependencyValidationIssue] {
        switch (source.type, target.type) {
        case let (.remotePackage(sourceURL, sourceVersion), .remotePackage(targetURL, targetVersion)):
            return validateURLs(identity: source.identity,
                                sourceURL: sourceURL,
                                targetURL: targetURL,
                                sourceLabel: sourceLabel,
                                targetLabel: targetLabel)
                + validateVersions(identity: source.identity,
                                   sourceVersion: sourceVersion,
                                   targetVersion: targetVersion,
                                   sourceLabel: sourceLabel,
                                   targetLabel: targetLabel)
            
        case let (.remoteBinary(sourceURL, sourceChecksum), .remoteBinary(targetURL, targetChecksum)):
            if sourceChecksum == targetChecksum { return [] }

            return validateURLs(identity: source.identity,
                                sourceURL: sourceURL,
                                targetURL: targetURL,
                                sourceLabel: sourceLabel,
                                targetLabel: targetLabel) + [
                .error(identity: source.identity,
                       message: "Binary checksum differs (\(sourceLabel): \(sourceChecksum), \(targetLabel): \(targetChecksum))")
            ]
            
        case (.localBinary, .localBinary):
            return []
            
        default:
            return [
                .error(identity: source.identity,
                       message: "Dependency type differs between \(sourceLabel) and \(targetLabel)")
            ]
        }
    }

    private func validateURLs(
        identity: String,
        sourceURL: String,
        targetURL: String,
        sourceLabel: String,
        targetLabel: String
    ) -> [DependencyValidationIssue] {
        guard sourceURL != targetURL else { return [] }

        return [
            .warning(identity: identity,
                     message: "Dependency URL differs (\(sourceLabel): \(sourceURL), \(targetLabel): \(targetURL))")
        ]
    }
    
    private func validateVersions(
        identity: String,
        sourceVersion: String,
        targetVersion: String,
        sourceLabel: String,
        targetLabel: String
    ) -> [DependencyValidationIssue] {
        if skippableVersionValues.contains(sourceVersion) || skippableVersionValues.contains(targetVersion) {
            return [
                .warning(identity: identity,
                         message: "Version unspecified (\(sourceLabel): \(sourceVersion), \(targetLabel): \(targetVersion))")
            ]
        }

        guard let source = SemanticVersion(sourceVersion),
              let target = SemanticVersion(targetVersion)
        else {
            return [
                .error(identity: identity,
                       message: "Invalid semantic version (\(sourceLabel): \(sourceVersion), \(targetLabel): \(targetVersion))")
            ]
        }
        
        if source == target {
            return []
        }
        
        if source > target && source.major == target.major {
            return [
                .warning(identity: identity,
                         message: "\(sourceLabel) version \(sourceVersion) is newer than \(targetLabel) version \(targetVersion)")
            ]
        }
        
        return [
            .error(identity: identity,
                   message: "\(targetLabel) version \(targetVersion) is not compatible with \(sourceLabel) version \(sourceVersion)")
        ]
    }
}

struct DependencyValidationIssue: Sendable, Equatable, CustomStringConvertible {
    let severity: DependencyValidationSeverity
    let identity: String
    let message: String

    var description: String {
        if DependencyValidationIssue.supportsColor {
            "\(severity.colorCode)\(severity.rawValue)\(Self.resetCode) \(identity): \(message)"
        } else {
            "\(severity.rawValue) \(identity): \(message)"
        }
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

        var colorCode: String {
            switch self {
            case .warning: return "\u{1B}[33m"
            case .error: return "\u{1B}[31m"
            }
        }
    }

    private static let resetCode = "\u{1B}[0m"
    private static let supportsColor: Bool = {
        isatty(fileno(stdout)) != 0 && ProcessInfo.processInfo.environment["TERM"] != "dumb"
    }()
}
