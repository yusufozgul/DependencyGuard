import XCTest
@testable import DependencyGuard

final class SemanticVersionTests: XCTestCase {
    func testPreReleaseVersionsFollowSemanticVersionPrecedence() {
        let versions = [
            "1.0.0-alpha",
            "1.0.0-alpha.1",
            "1.0.0-alpha.beta",
            "1.0.0-beta",
            "1.0.0-beta.2",
            "1.0.0-beta.11",
            "1.0.0-rc.1",
            "1.0.0"
        ].compactMap(SemanticVersion.init)

        XCTAssertEqual(versions.count, 8)
        XCTAssertTrue(zip(versions, versions.dropFirst()).allSatisfy(<))
    }

    func testBuildMetadataDoesNotAffectPrecedence() {
        let first = SemanticVersion("1.0.0+build.1")
        let second = SemanticVersion("1.0.0+build.2")

        XCTAssertEqual(first, second)
    }

    func testLeadingZeroNumericIdentifiersAreInvalid() {
        XCTAssertNil(SemanticVersion("01.0.0"))
        XCTAssertNil(SemanticVersion("1.0.0-01"))
    }
}
