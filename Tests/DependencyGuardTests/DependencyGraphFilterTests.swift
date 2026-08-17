import XCTest
@testable import DependencyGuard

final class DependencyGraphFilterTests: XCTestCase {
    func testLinkedPackageProductSelectsItsPackageIdentity() {
        let packageProducts = [
            SPMPackageProducts(identity: "trendyol-toolkit", names: ["TYUtils"])
        ]

        let identities = XcodeProjectDependencyProcessor().packageIdentities(
            matching: ["TYUtils"],
            in: packageProducts
        )

        XCTAssertEqual(identities, ["trendyol-toolkit"])
    }

    func testSelectedPackageKeepsItsSubdependencies() {
        let graph = [
            package(
                identity: "root-package",
                url: "https://example.com/root-package.git",
                dependencies: [package(identity: "nested-package")]
            ),
            package(identity: "unused-package")
        ]
        let selection = XcodeProjectDependencySelection(
            targetNames: ["App"],
            packageProductNames: [],
            packageIdentities: ["root-package"],
            linkedArtifactNames: []
        )

        let filtered = graph.filtered(using: selection)

        XCTAssertEqual(filtered.map(\.identity), ["root-package"])
        XCTAssertEqual(filtered.first?.dependencies.map(\.identity), ["nested-package"])
    }

    func testSelectedSubdependencyKeepsItsParentPackage() {
        let graph = [
            package(
                identity: "root-package",
                dependencies: [package(identity: "nested-package")]
            )
        ]
        let selection = XcodeProjectDependencySelection(
            targetNames: ["App"],
            packageProductNames: [],
            packageIdentities: ["nested-package"],
            linkedArtifactNames: []
        )

        let filtered = graph.filtered(using: selection)

        XCTAssertEqual(filtered.map(\.identity), ["root-package"])
        XCTAssertEqual(filtered.first?.dependencies.map(\.identity), ["nested-package"])
    }

    func testSelectedRemoteBinaryIsIncluded() {
        let graph = [
            DependencyGraph(
                identity: "Analytics",
                name: "Analytics",
                type: .remoteBinary(url: "https://example.com/Analytics.zip", checksum: "checksum"),
                dependencies: []
            ),
            DependencyGraph(
                identity: "Unused",
                name: "Unused",
                type: .localBinary(path: "/Unused.xcframework"),
                dependencies: []
            )
        ]
        let selection = XcodeProjectDependencySelection(
            targetNames: ["App"],
            packageProductNames: [],
            packageIdentities: [],
            linkedArtifactNames: ["Analytics"]
        )

        let filtered = graph.filtered(using: selection)

        XCTAssertEqual(filtered.map(\.identity), ["Analytics"])
    }

    func testUnusedBinaryChildIsRemovedFromSelectedPackage() {
        let graph = [
            package(
                identity: "root-package",
                dependencies: [
                    binary(identity: "UsedBinary"),
                    binary(identity: "UnusedBinary")
                ]
            )
        ]
        let selection = XcodeProjectDependencySelection(
            targetNames: ["App"],
            packageProductNames: [],
            packageIdentities: ["root-package"],
            linkedArtifactNames: ["UsedBinary"]
        )

        let filtered = graph.filtered(using: selection)

        XCTAssertEqual(filtered.first?.dependencies.map(\.identity), ["UsedBinary"])
    }

    func testPackageContainingSelectedBinaryIsIncluded() {
        let graph = [
            package(
                identity: "third-party-dependencies",
                dependencies: [
                    binary(identity: "Clarity"),
                    binary(identity: "UnusedBinary")
                ]
            )
        ]
        let selection = XcodeProjectDependencySelection(
            targetNames: ["App"],
            packageProductNames: [],
            packageIdentities: [],
            linkedArtifactNames: ["Clarity"]
        )

        let filtered = graph.filtered(using: selection)

        XCTAssertEqual(filtered.map(\.identity), ["third-party-dependencies"])
        XCTAssertEqual(filtered.first?.dependencies.map(\.identity), ["Clarity"])
    }

    func testSelectedUmbrellaPackageKeepsAllDependencies() {
        let graph = [
            package(
                identity: "third-party-dependencies",
                name: "ThirdPartyDependencies",
                dependencies: [
                    binary(identity: "Cosmos"),
                    binary(identity: "UnusedBinary")
                ]
            )
        ]
        let selection = XcodeProjectDependencySelection(
            targetNames: ["App"],
            packageProductNames: [],
            packageIdentities: [],
            linkedArtifactNames: ["ThirdPartyDependencies"]
        )

        let filtered = graph.filtered(using: selection)

        XCTAssertEqual(filtered.first?.dependencies.map(\.identity), ["Cosmos", "UnusedBinary"])
    }

    private func package(
        identity: String,
        url: String = "https://example.com/package.git",
        name: String? = nil,
        dependencies: [DependencyGraph] = []
    ) -> DependencyGraph {
        DependencyGraph(
            identity: identity,
            name: name ?? identity,
            type: .remotePackage(url: url, version: "1.0.0"),
            dependencies: dependencies
        )
    }

    private func binary(identity: String) -> DependencyGraph {
        DependencyGraph(
            identity: identity,
            name: identity,
            type: .remoteBinary(url: "https://example.com/\(identity).zip", checksum: "checksum"),
            dependencies: []
        )
    }
}
