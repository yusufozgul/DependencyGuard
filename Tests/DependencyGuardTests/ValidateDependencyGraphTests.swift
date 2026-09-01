import XCTest
@testable import DependencyGuard

final class ValidateDependencyGraphTests: XCTestCase {

    // MARK: - validateAll: comparison count

    func testSingleTargetProducesOneComparison() {
        let results = ValidateDependencyGraph().validateAll(
            source: ("source", [package("source-pkg", "1.0.0")]),
            targets: [("SDK1", [package("dep", "2.0.0")])]
        )

        XCTAssertEqual(results.comparisons.count, 1)
        XCTAssertEqual(results.comparisons[0].sourceLabel, "source")
        XCTAssertEqual(results.comparisons[0].targetLabel, "SDK1")
    }

    func testTwoTargetsProduceThreeComparisons() {
        let results = ValidateDependencyGraph().validateAll(
            source: ("source", [package("source-pkg", "1.0.0")]),
            targets: [
                ("SDK1", [package("dep", "2.0.0")]),
                ("SDK2", [package("dep", "3.0.0")])
            ]
        )

        XCTAssertEqual(results.comparisons.count, 3)
        XCTAssertEqual(results.comparisons[0].sourceLabel, "source")
        XCTAssertEqual(results.comparisons[0].targetLabel, "SDK1")
        XCTAssertEqual(results.comparisons[1].sourceLabel, "source")
        XCTAssertEqual(results.comparisons[1].targetLabel, "SDK2")
        XCTAssertEqual(results.comparisons[2].sourceLabel, "SDK1")
        XCTAssertEqual(results.comparisons[2].targetLabel, "SDK2")
    }

    func testThreeTargetsProduceSixComparisons() {
        let results = ValidateDependencyGraph().validateAll(
            source: ("source", [package("source-pkg", "1.0.0")]),
            targets: [
                ("SDK1", [package("dep", "1.0.0")]),
                ("SDK2", [package("dep", "2.0.0")]),
                ("SDK3", [package("dep", "3.0.0")])
            ]
        )

        XCTAssertEqual(results.comparisons.count, 6)
    }

    // MARK: - validateAll: issue collection

    func testNoIssuesWhenAllGraphsMatch() {
        let graph = [package("dep", "1.0.0")]

        let results = ValidateDependencyGraph().validateAll(
            source: ("source", graph),
            targets: [("SDK1", graph), ("SDK2", graph)]
        )

        XCTAssertEqual(results.totalWarnings, 0)
        XCTAssertEqual(results.totalErrors, 0)
    }

    func testSourceVsTargetIssuesAreCollected() {
        let results = ValidateDependencyGraph().validateAll(
            source: ("source", [package("dep", "1.0.0")]),
            targets: [("SDK1", [package("dep", "2.0.0")])]
        )

        XCTAssertEqual(results.totalErrors, 1)
    }

    func testTargetVsTargetIssuesAreCollected() {
        let results = ValidateDependencyGraph().validateAll(
            source: ("source", [package("source-pkg", "1.0.0")]),
            targets: [
                ("SDK1", [package("dep", "1.0.0")]),
                ("SDK2", [package("dep", "2.0.0")])
            ]
        )

        XCTAssertEqual(results.totalErrors, 1)
        let targetVsTarget = results.comparisons[2]
        XCTAssertEqual(targetVsTarget.sourceLabel, "SDK1")
        XCTAssertEqual(targetVsTarget.targetLabel, "SDK2")
        XCTAssertEqual(targetVsTarget.issues.count, 1)
        XCTAssertEqual(targetVsTarget.issues[0].severity, .error)
    }

    func testWarningsAndErrorsAreCountedSeparately() {
        let results = ValidateDependencyGraph().validateAll(
            source: ("source", [package("dep", "5.11.0")]),
            targets: [
                ("SDK1", [package("dep", "6.0.0")]),
                ("SDK2", [package("dep", "5.10.2")])
            ]
        )

        // source vs SDK1: 5.11.0 vs 6.0.0 → error (major mismatch)
        // source vs SDK2: 5.11.0 vs 5.10.2 → warning (newer source, same major)
        // SDK1 vs SDK2: 6.0.0 vs 5.10.2 → error (major mismatch)
        XCTAssertEqual(results.totalWarnings, 1)
        XCTAssertEqual(results.totalErrors, 2)
    }

    // MARK: - label

    func testLabelForSourceAlwaysReturnsSource() {
        XCTAssertEqual(ValidateDependencyGraph().label(for: "./DependencyGraph.json", isSource: true), "source")
        XCTAssertEqual(ValidateDependencyGraph().label(for: "/any/path/DependencyGraph.json", isSource: true), "source")
    }

    func testLabelForTargetUsesParentDirectory() {
        XCTAssertEqual(
            ValidateDependencyGraph().label(for: "Tuist/.build/artifacts/tuist/SomeSDK/DependencyGraph.json", isSource: false),
            "SomeSDK"
        )
    }

    func testLabelForTargetWithFlatPathFallsBackToFilename() {
        XCTAssertEqual(
            ValidateDependencyGraph().label(for: "DependencyGraph.json", isSource: false),
            "DependencyGraph.json"
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
}
