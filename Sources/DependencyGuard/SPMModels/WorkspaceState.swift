//
//  WorkspaceState.swift
//  DependencyGuard
//
//  Created by Yusuf Tayyip Özgül on 3.08.2026.
//

struct WorkspaceState: Decodable, Sendable, Equatable, Hashable {
    let object: SPMWorkspaceObject
}

struct SPMWorkspaceObject: Decodable, Sendable, Equatable, Hashable {
    let artifacts: [SPMArtifact]
}

struct SPMArtifact: Decodable, Sendable, Equatable, Hashable {
    let kind: Kind
    let packageRef: PackageRef
    let path: String
    let source: Source
    let targetName: String
    
    enum Kind: Decodable, Sendable, Equatable, Hashable {
        case xcframework
        case artifactsArchive
        case typedArtifactsArchive([String])
        case unknown
    }
    
    struct PackageRef: Decodable, Sendable, Equatable, Hashable {
        let identity: String
        let kind: Kind
        let location: String
        let name: String
        
        enum Kind: String, Decodable, Sendable, Equatable, Hashable {
            case remoteSourceControl
            case root
            case fileSystem
            case localSourceControl
            case registry
        }
    }
    
    struct Source: Decodable, Sendable, Equatable, Hashable {
        let checksum: String?
        let type: SourceType
        let url: String?
        
        enum SourceType: String, Decodable, Sendable, Equatable, Hashable {
            case remote
            case local
        }
    }
}
