//
//  DependencyGraphGenerator.swift
//  DependencyGuard
//
//  Created by Yusuf Tayyip Özgül on 3.08.2026.
//

struct DependencyGraphGenerator {
    func generate(dependencyList: [SPMDependency], xcFrameworks: [SPMArtifact]) -> [DependencyGraph] {
        let dependencies = dependencyList.map { $0.asDependencyGraph(with: xcFrameworks) }
        let rootXCFrameworks: [DependencyGraph] = xcFrameworks
            .filter { $0.packageRef.kind == .root }
            .map { xcFramework in
                let type: DependencyGraphDependencyType = xcFramework.source.type == .remote ? .remoteBinary(url: xcFramework.source.url ?? "", checksum: xcFramework.source.checksum ?? "") : .localBinary(path: xcFramework.path)
                return DependencyGraph(identity: xcFramework.targetName,
                                name: xcFramework.targetName,
                                type: type.redacted,
                                dependencies: [])
            }
        
        return dependencies + rootXCFrameworks
    }
}

private extension SPMDependency {
    func asDependencyGraph(with xcFrameworks: [SPMArtifact]) -> DependencyGraph {
        let binaryDependencies: [DependencyGraph] = xcFrameworks
            .filter { $0.packageRef.identity == identity }
            .map { xcFramework in
                let type: DependencyGraphDependencyType = xcFramework.source.type == .remote ? .remoteBinary(url: xcFramework.source.url ?? "", checksum: xcFramework.source.checksum ?? "") : .localBinary(path: xcFramework.path)
                
                return DependencyGraph(identity: xcFramework.targetName,
                                name: xcFramework.targetName,
                                type: type.redacted,
                                dependencies: [])
            }
        
        return DependencyGraph(identity: identity,
                               name: name,
                               type: .remotePackage(url: url, version: version).redacted,
                               dependencies: dependencies.map { $0.asDependencyGraph(with: xcFrameworks) } + binaryDependencies)
    }
}
