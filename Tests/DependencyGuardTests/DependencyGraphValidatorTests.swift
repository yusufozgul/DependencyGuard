import Testing
@testable import DependencyGuard

@Test
func testEqualVersionsProduceNoIssues() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.10.2"),
        target: package(identity: "Alamofire", version: "5.10.2")
    )

    #expect(issues.isEmpty)
}

@Test
func testNewerSourceVersionProducesWarning() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.11.0"),
        target: package(identity: "Alamofire", version: "5.10.2")
    )

    #expect(issues.map(\.severity) == [.warning])
}

@Test
func testNewerTargetVersionProducesError() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.10.2"),
        target: package(identity: "Alamofire", version: "5.11.0")
    )

    #expect(issues.map(\.severity) == [.error])
}

@Test
func testDifferentMajorVersionProducesError() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "6.0.0"),
        target: package(identity: "Alamofire", version: "5.10.2")
    )

    #expect(issues.map(\.severity) == [.error])
}

@Test
func testNewerTargetMajorVersionProducesError() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.10.2"),
        target: package(identity: "Alamofire", version: "6.0.0")
    )

    #expect(issues.map(\.severity) == [.error])
}

@Test
func testNewerSourcePatchVersionProducesWarning() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.10.3"),
        target: package(identity: "Alamofire", version: "5.10.2")
    )

    #expect(issues.map(\.severity) == [.warning])
}

@Test
func testPreReleaseVersionProducesWarning() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.10.2"),
        target: package(identity: "Alamofire", version: "5.10.2-rc.1")
    )

    #expect(issues.map(\.severity) == [.warning])
}

@Test
func testDifferentPackageURLsProduceWarning() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.10.2", url: "https://github.com/one/Alamofire"),
        target: package(identity: "Alamofire", version: "5.10.2", url: "https://github.com/two/Alamofire")
    )

    #expect(issues.map(\.severity) == [.warning])
    #expect(
        issues.first?.message == "Dependency URL differs (source: https://github.com/one/Alamofire, target: https://github.com/two/Alamofire)"
    )
}

@Test
func testURLsDifferingOnlyByGitSuffixProduceNoIssues() {
    let issues = validate(
        source: package(identity: "nanopb", version: "1.0.0", url: "https://github.com/firebase/nanopb"),
        target: package(identity: "nanopb", version: "1.0.0", url: "https://github.com/firebase/nanopb.git")
    )

    #expect(issues.isEmpty)
}

@Test
func testURLsDifferingOnlyByTrailingSlashProduceNoIssues() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "5.10.2", url: "https://github.com/Alamofire/Alamofire"),
        target: package(identity: "Alamofire", version: "5.10.2", url: "https://github.com/Alamofire/Alamofire/")
    )

    #expect(issues.isEmpty)
}

@Test
func testURLsDifferingByGitSuffixAndTrailingSlashProduceNoIssues() {
    let issues = validate(
        source: package(identity: "nanopb", version: "1.0.0", url: "https://github.com/firebase/nanopb.git"),
        target: package(identity: "nanopb", version: "1.0.0", url: "https://github.com/firebase/nanopb/")
    )

    #expect(issues.isEmpty)
}

@Test
func testRemoteAndLocalBinaryMismatchProducesError() {
    let issues = validate(
        source: binary(identity: "Analytics", checksum: "checksum"),
        target: localBinary(identity: "Analytics", path: "/Analytics.xcframework")
    )

    #expect(issues.map(\.severity) == [.error])
}

@Test
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

    #expect(issues.map(\.identity) == ["Nested"])
    #expect(issues.map(\.severity) == [.error])
}

@Test
func testDependenciesMissingFromEitherGraphAreIgnored() {
    let issues = validate(
        source: [package(identity: "SourceOnly", version: "1.0.0")],
        target: [package(identity: "TargetOnly", version: "1.0.0")]
    )

    #expect(issues.isEmpty)
}

@Test
func testBinaryChecksumMismatchProducesError() {
    let issues = validate(
        source: binary(identity: "Analytics", checksum: "source-checksum"),
        target: binary(identity: "Analytics", checksum: "target-checksum")
    )

    #expect(issues.map(\.severity) == [.error])
}

@Test
func testDifferentBinaryURLsWithSameChecksumProduceNoIssues() {
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

    #expect(issues.isEmpty)
}

@Test
func testDifferentBinaryURLsWithDifferentChecksumProducesErrorOnly() {
    let issues = validate(
        source: binary(
            identity: "Analytics",
            url: "https://example.com/source/Analytics.zip",
            checksum: "source-checksum"
        ),
        target: binary(
            identity: "Analytics",
            url: "https://example.com/target/Analytics.zip",
            checksum: "target-checksum"
        )
    )

    #expect(issues.map(\.severity) == [.warning, .error])
}

@Test
func testMatchingLocalBinariesProduceNoIssues() {
    let issues = validate(
        source: localBinary(identity: "Analytics", path: "/source/Analytics.xcframework"),
        target: localBinary(identity: "Analytics", path: "/target/Analytics.xcframework")
    )

    #expect(issues.isEmpty)
}

@Test
func testInvalidVersionProducesError() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "not-a-version"),
        target: package(identity: "Alamofire", version: "5.10.2")
    )

    #expect(issues.map(\.severity) == [.error])
}

@Test
func testUnspecifiedVersionProducesWarning() {
    let issues = validate(
        source: package(identity: "Alamofire", version: "unspecified"),
        target: package(identity: "Alamofire", version: "5.10.2")
    )

    #expect(issues.map(\.severity) == [.warning])
}

@Test
func testSameDependencyAsSourceAndBinaryProducesError() {
    let source = DependencyGraph(
        identity: "dependencya",
        name: "DependencyA",
        type: .remotePackage(url: "https://github.com/example/DependencyA", version: "1.0.0"),
        dependencies: []
    )
    let target = DependencyGraph(
        identity: "DependencyA",
        name: "DependencyA",
        type: .remoteBinary(url: "https://example.com/DependencyA.zip", checksum: "checksum"),
        dependencies: []
    )

    let issues = validate(source: [source], target: [target])

    #expect(issues.map(\.severity) == [.error])
    #expect(issues.first?.identity == "DependencyA")
    #expect(
        issues.first?.message == "Dependency linked as both source and binary (source: source, target: remote binary)"
    )
}

@Test
func testSameDependencyAsSourceAndLocalBinaryProducesError() {
    let source = DependencyGraph(
        identity: "dependencya",
        name: "DependencyA",
        type: .remotePackage(url: "https://github.com/example/DependencyA", version: "1.0.0"),
        dependencies: []
    )
    let target = DependencyGraph(
        identity: "DependencyA",
        name: "DependencyA",
        type: .localBinary(path: "/path/DependencyA.xcframework"),
        dependencies: []
    )

    let issues = validate(source: [source], target: [target])

    #expect(issues.map(\.severity) == [.error])
    #expect(
        issues.first?.message == "Dependency linked as both source and binary (source: source, target: local binary)"
    )
}

@Test
func testSameDependencyAsBinaryInBothGraphsDoesNotProduceConflict() {
    let source = DependencyGraph(
        identity: "DependencyA-source",
        name: "DependencyA",
        type: .remoteBinary(url: "https://example.com/source/DependencyA.zip", checksum: "checksum"),
        dependencies: []
    )
    let target = DependencyGraph(
        identity: "DependencyA-target",
        name: "DependencyA",
        type: .remoteBinary(url: "https://example.com/target/DependencyA.zip", checksum: "checksum"),
        dependencies: []
    )

    let issues = validate(source: [source], target: [target])

    #expect(issues.isEmpty)
}

@Test
func testSameDependencyAsSourceInBothGraphsDoesNotProduceConflict() {
    let source = DependencyGraph(
        identity: "dependencya-source",
        name: "DependencyA",
        type: .remotePackage(url: "https://github.com/example/DependencyA", version: "1.0.0"),
        dependencies: []
    )
    let target = DependencyGraph(
        identity: "dependencya-target",
        name: "DependencyA",
        type: .remotePackage(url: "https://github.com/example/DependencyA", version: "1.0.0"),
        dependencies: []
    )

    let issues = validate(source: [source], target: [target])

    #expect(issues.isEmpty)
}

@Test
func testSourceBinaryConflictDetectedCaseInsensitively() {
    let source = DependencyGraph(
        identity: "dependencya",
        name: "DependencyA",
        type: .remotePackage(url: "https://github.com/example/DependencyA", version: "1.0.0"),
        dependencies: []
    )
    let target = DependencyGraph(
        identity: "dependencya-binary",
        name: "dependencya",
        type: .remoteBinary(url: "https://example.com/DependencyA.zip", checksum: "checksum"),
        dependencies: []
    )

    let issues = validate(source: [source], target: [target])

    #expect(issues.map(\.severity) == [.error])
}

// MARK: - Helpers

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
