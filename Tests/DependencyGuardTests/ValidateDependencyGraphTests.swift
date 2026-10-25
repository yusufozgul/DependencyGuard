import Testing
@testable import DependencyGuard

// MARK: - validateAll: comparison count

@Test
func testSingleTargetProducesOneComparison() {
    let results = ValidateDependencyGraph().validateAll(
        source: ("source", [package("source-pkg", "1.0.0")]),
        targets: [("SDK1", [package("dep", "2.0.0")])]
    )

    #expect(results.comparisons.count == 1)
    #expect(results.comparisons[0].sourceLabel == "source")
    #expect(results.comparisons[0].targetLabel == "SDK1")
}

@Test
func testTwoTargetsProduceThreeComparisons() {
    let results = ValidateDependencyGraph().validateAll(
        source: ("source", [package("source-pkg", "1.0.0")]),
        targets: [
            ("SDK1", [package("dep", "2.0.0")]),
            ("SDK2", [package("dep", "3.0.0")])
        ]
    )

    #expect(results.comparisons.count == 3)
    #expect(results.comparisons[0].sourceLabel == "source")
    #expect(results.comparisons[0].targetLabel == "SDK1")
    #expect(results.comparisons[1].sourceLabel == "source")
    #expect(results.comparisons[1].targetLabel == "SDK2")
    #expect(results.comparisons[2].sourceLabel == "SDK1")
    #expect(results.comparisons[2].targetLabel == "SDK2")
}

@Test
func testThreeTargetsProduceSixComparisons() {
    let results = ValidateDependencyGraph().validateAll(
        source: ("source", [package("source-pkg", "1.0.0")]),
        targets: [
            ("SDK1", [package("dep", "1.0.0")]),
            ("SDK2", [package("dep", "2.0.0")]),
            ("SDK3", [package("dep", "3.0.0")])
        ]
    )

    #expect(results.comparisons.count == 6)
}

// MARK: - validateAll: issue collection

@Test
func testNoIssuesWhenAllGraphsMatch() {
    let graph = [package("dep", "1.0.0")]

    let results = ValidateDependencyGraph().validateAll(
        source: ("source", graph),
        targets: [("SDK1", graph), ("SDK2", graph)]
    )

    #expect(results.totalWarnings == 0)
    #expect(results.totalErrors == 0)
}

@Test
func testSourceVsTargetIssuesAreCollected() {
    let results = ValidateDependencyGraph().validateAll(
        source: ("source", [package("dep", "1.0.0")]),
        targets: [("SDK1", [package("dep", "2.0.0")])]
    )

    #expect(results.totalErrors == 1)
}

@Test
func testTargetVsTargetIssuesAreCollected() {
    let results = ValidateDependencyGraph().validateAll(
        source: ("source", [package("source-pkg", "1.0.0")]),
        targets: [
            ("SDK1", [package("dep", "1.0.0")]),
            ("SDK2", [package("dep", "2.0.0")])
        ]
    )

    #expect(results.totalErrors == 1)
    let targetVsTarget = results.comparisons[2]
    #expect(targetVsTarget.sourceLabel == "SDK1")
    #expect(targetVsTarget.targetLabel == "SDK2")
    #expect(targetVsTarget.issues.count == 1)
    #expect(targetVsTarget.issues[0].severity == .error)
}

@Test
func testWarningsAndErrorsAreCountedSeparately() {
    let results = ValidateDependencyGraph().validateAll(
        source: ("source", [package("dep", "5.11.0")]),
        targets: [
            ("SDK1", [package("dep", "6.0.0")]),
            ("SDK2", [package("dep", "5.10.2")])
        ]
    )

    #expect(results.totalWarnings == 1)
    #expect(results.totalErrors == 2)
}

// MARK: - label

@Test
func testLabelForSourceAlwaysReturnsSource() {
    #expect(ValidateDependencyGraph().label(for: "./DependencyGraph.json", isSource: true) == "source")
    #expect(ValidateDependencyGraph().label(for: "/any/path/DependencyGraph.json", isSource: true) == "source")
}

@Test
func testLabelForTargetUsesParentDirectory() {
    #expect(
        ValidateDependencyGraph().label(for: "Tuist/.build/artifacts/tuist/SomeSDK/DependencyGraph.json", isSource: false) == "SomeSDK"
    )
}

@Test
func testLabelForTargetWithFlatPathFallsBackToFilename() {
    #expect(
        ValidateDependencyGraph().label(for: "DependencyGraph.json", isSource: false) == "DependencyGraph.json"
    )
}

// MARK: - Helpers

private func package(
    _ identity: String,
    _ version: String,
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
