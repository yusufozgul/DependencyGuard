import Testing
@testable import DependencyGuard

@Test
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

    #expect(versions.count == 8)
    #expect(zip(versions, versions.dropFirst()).allSatisfy(<))
}

@Test
func testBuildMetadataDoesNotAffectPrecedence() {
    let first = SemanticVersion("1.0.0+build.1")
    let second = SemanticVersion("1.0.0+build.2")

    #expect(first == second)
}

@Test
func testLeadingZeroNumericIdentifiersAreInvalid() {
    #expect(SemanticVersion("01.0.0") == nil)
    #expect(SemanticVersion("1.0.0-01") == nil)
}
