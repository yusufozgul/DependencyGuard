import XCTest
@testable import DependencyGuard

final class DependencyGraphValidatorTests: XCTestCase {
    func testEqualVersionsProduceNoIssues() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "5.10.2"),
            target: package(identity: "Alamofire", version: "5.10.2")
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testNewerSourceVersionProducesWarning() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "5.11.0"),
            target: package(identity: "Alamofire", version: "5.10.2")
        )

        XCTAssertEqual(issues.map(\.severity), [.warning])
    }

    func testNewerTargetVersionProducesError() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "5.10.2"),
            target: package(identity: "Alamofire", version: "5.11.0")
        )

        XCTAssertEqual(issues.map(\.severity), [.error])
    }

    func testDifferentMajorVersionProducesError() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "6.0.0"),
            target: package(identity: "Alamofire", version: "5.10.2")
        )

        XCTAssertEqual(issues.map(\.severity), [.error])
    }

    func testNewerTargetMajorVersionProducesError() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "5.10.2"),
            target: package(identity: "Alamofire", version: "6.0.0")
        )

        XCTAssertEqual(issues.map(\.severity), [.error])
    }

    func testNewerSourcePatchVersionProducesWarning() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "5.10.3"),
            target: package(identity: "Alamofire", version: "5.10.2")
        )

        XCTAssertEqual(issues.map(\.severity), [.warning])
    }

    func testPreReleaseVersionsFollowSemanticVersionPrecedence() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "5.10.2"),
            target: package(identity: "Alamofire", version: "5.10.2-rc.1")
        )

        XCTAssertEqual(issues.map(\.severity), [.warning])
    }

    func testDifferentPackageURLsProduceWarning() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "5.10.2", url: "https://github.com/one/Alamofire"),
            target: package(identity: "Alamofire", version: "5.10.2", url: "https://github.com/two/Alamofire")
        )

        XCTAssertEqual(issues.map(\.severity), [.warning])
        XCTAssertEqual(
            issues.first?.message,
            "Dependency URL differs (source: https://github.com/one/Alamofire, target: https://github.com/two/Alamofire)"
        )
    }

    func testRemoteAndLocalBinaryMismatchProducesError() {
        let issues = validate(
            source: binary(identity: "Analytics", checksum: "checksum"),
            target: localBinary(identity: "Analytics", path: "/Analytics.xcframework")
        )

        XCTAssertEqual(issues.map(\.severity), [.error])
    }

    func testNestedDependenciesAreCompared() {
        let source = package(
            identity: "Root",
            version: "1.0.0",
            dependencies: [package(identity: "Nested", version: "2.0.0")]
        )
        let target = package(
            identity: "Root",
            version: "1.0.0",
            dependencies: [package(identity: "Nested", version: "2.1.0")]
        )

        let issues = validate(source: [source], target: [target])

        XCTAssertEqual(issues.map(\.identity), ["Nested"])
        XCTAssertEqual(issues.map(\.severity), [.error])
    }

    func testDependenciesMissingFromEitherGraphAreIgnored() {
        let issues = validate(
            source: [package(identity: "SourceOnly", version: "1.0.0")],
            target: [package(identity: "TargetOnly", version: "1.0.0")]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testBinaryChecksumMismatchProducesError() {
        let issues = validate(
            source: binary(identity: "Analytics", checksum: "source-checksum"),
            target: binary(identity: "Analytics", checksum: "target-checksum")
        )

        XCTAssertEqual(issues.map(\.severity), [.error])
    }

    func testDifferentBinaryURLsProduceWarning() {
        let issues = validate(
            source: binary(
                identity: "Analytics",
                url: "https://example.com/source/Analytics.zip",
                checksum: "checksum"
            ),
            target: binary(
                identity: "Analytics",
                url: "https://example.com/target/Analytics.zip",
                checksum: "checksum"
            )
        )

        XCTAssertEqual(issues.map(\.severity), [.warning])
    }

    func testMatchingLocalBinariesProduceNoIssues() {
        let issues = validate(
            source: localBinary(identity: "Analytics", path: "/source/Analytics.xcframework"),
            target: localBinary(identity: "Analytics", path: "/target/Analytics.xcframework")
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testInvalidVersionProducesError() {
        let issues = validate(
            source: package(identity: "Alamofire", version: "unspecified"),
            target: package(identity: "Alamofire", version: "5.10.2")
        )

        XCTAssertEqual(issues.map(\.severity), [.error])
    }

    private func validate(source: DependencyGraph, target: DependencyGraph) -> [DependencyValidationIssue] {
        validate(source: [source], target: [target])
    }

    private func validate(source: [DependencyGraph], target: [DependencyGraph]) -> [DependencyValidationIssue] {
        DependencyGraphValidator().validate(source: source, target: target)
    }

    private func package(
        identity: String,
        version: String,
        url: String = "https://example.com/Package",
        dependencies: [DependencyGraph] = []
    ) -> DependencyGraph {
        DependencyGraph(
            identity: identity,
            name: identity,
            type: .remotePackage(url: url, version: version),
            dependencies: dependencies
        )
    }

    private func binary(
        identity: String,
        url: String = "https://example.com/Analytics.zip",
        checksum: String
    ) -> DependencyGraph {
        DependencyGraph(
            identity: identity,
            name: identity,
            type: .remoteBinary(url: url, checksum: checksum),
            dependencies: []
        )
    }

    private func localBinary(identity: String, path: String) -> DependencyGraph {
        DependencyGraph(
            identity: identity,
            name: identity,
            type: .localBinary(path: path),
            dependencies: []
        )
    }
}
