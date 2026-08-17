//
//  SPMDependencyList.swift
//  DependencyGuard
//
//  Created by Yusuf Tayyip Özgül on 3.08.2026.
//

struct SPMDependencyList: Decodable, Sendable, Equatable, Hashable {
    let dependencies: [SPMDependency]
}

struct SPMDependency: Decodable, Sendable, Equatable, Hashable {
    let identity: String
    let name: String
    let url: String
    let version: String
    let path: String
    let dependencies: [SPMDependency]
}
