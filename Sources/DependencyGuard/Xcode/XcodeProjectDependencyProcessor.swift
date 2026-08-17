import Foundation
import PathKit
import XcodeProj

struct XcodeProjectDependencySelection: Sendable, Equatable {
    let targetNames: Set<String>
    let packageProductNames: Set<String>
    let packageIdentities: Set<String>
    let linkedArtifactNames: Set<String>
}

struct XcodeProjectDependencyProcessor {
    func selection(
        projectPath: String,
        targetName: String,
        packageProducts: [SPMPackageProducts] = []
    ) throws -> XcodeProjectDependencySelection {
        let project = try XcodeProj(path: Path(projectPath))
        let targets = project.pbxproj.projects.flatMap(\.targets)
        
        guard let target = targets.first(where: { $0.name == targetName }) else {
            throw XcodeProjectDependencyProcessorError.targetNotFound(targetName)
        }
        
        let result = try collect(target)
        let packageIdentities = result.packageIdentities.union(
                packageIdentities(
                matching: result.linkedArtifactNames,
                in: packageProducts
            )
        )

        return XcodeProjectDependencySelection(targetNames: result.targetNames,
                                               packageProductNames: result.packageProductNames,
                                               packageIdentities: packageIdentities,
                                               linkedArtifactNames: result.linkedArtifactNames)
    }

    func packageIdentities(matching linkedArtifactNames: Set<String>, in packageProducts: [SPMPackageProducts]) -> Set<String> {
        let linkedNames = Set(linkedArtifactNames.map { $0.lowercased() })
        return Set(packageProducts.compactMap { package in
            package.names.contains { linkedNames.contains($0.lowercased()) }
                ? package.identity.lowercased()
                : nil
        })
    }
    
    private func collect(_ target: PBXTarget, visitedTargetIDs: Set<String> = []) throws -> CollectionResult {
        guard !visitedTargetIDs.contains(target.uuid) else {  return CollectionResult() }
        
        var result = CollectionResult(visitedTargetIDs: visitedTargetIDs)
        result.visitedTargetIDs.insert(target.uuid)
        result.targetNames.insert(target.name)
        
        for packageProduct in target.packageProductDependencies ?? [] {
            result.packageProductNames.insert(packageProduct.productName.lowercased())
            if let repositoryURL = packageProduct.package?.repositoryURL {
                result.packageIdentities.insert(packageIdentity(from: repositoryURL))
            }
        }
        
        for buildPhase in target.buildPhases {
            guard buildPhase is PBXFrameworksBuildPhase || buildPhase is PBXCopyFilesBuildPhase else {
                continue
            }
            
            for buildFile in buildPhase.files ?? [] {
                if let product = buildFile.product {
                    result.packageProductNames.insert(product.productName.lowercased())
                    if let repositoryURL = product.package?.repositoryURL {
                        result.packageIdentities.insert(packageIdentity(from: repositoryURL))
                    }
                }
                
                if let file = buildFile.file {
                    if let fileName = file.name ?? file.path {
                        result.linkedArtifactNames.insert(normalizedName(fileName))
                    }
                }
            }
        }
        
        for dependency in target.dependencies {
            if let dependencyTarget = dependency.target {
                let dependencyResult = try collect(
                    dependencyTarget,
                    visitedTargetIDs: result.visitedTargetIDs
                )
                result.merge(dependencyResult)
            } else if let remoteInfo = dependency.targetProxy?.remoteInfo {
                result.targetNames.insert(remoteInfo)
                result.linkedArtifactNames.insert(normalizedName(remoteInfo))
            }
        }
        
        return result
    }
    
    private struct CollectionResult {
        var visitedTargetIDs = Set<String>()
        var targetNames = Set<String>()
        var packageProductNames = Set<String>()
        var packageIdentities = Set<String>()
        var linkedArtifactNames = Set<String>()
        
        mutating func merge(_ other: CollectionResult) {
            visitedTargetIDs.formUnion(other.visitedTargetIDs)
            targetNames.formUnion(other.targetNames)
            packageProductNames.formUnion(other.packageProductNames)
            packageIdentities.formUnion(other.packageIdentities)
            linkedArtifactNames.formUnion(other.linkedArtifactNames)
        }
    }
    
    private func packageIdentity(from repositoryURL: String) -> String {
        repositoryURL
            .split(separator: "/")
            .last
            .map { $0.replacingOccurrences(of: ".git", with: "").lowercased() }
        ?? repositoryURL.lowercased()
    }
    
    private func normalizedName(_ value: String) -> String {
        URL(fileURLWithPath: value)
            .deletingPathExtension()
            .lastPathComponent
    }
}

enum XcodeProjectDependencyProcessorError: LocalizedError {
    case targetNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case let .targetNotFound(targetName):
            "Target '\(targetName)' was not found in the Xcode project"
        }
    }
}
