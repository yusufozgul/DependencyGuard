import Testing
@testable import DependencyGuard

@Suite(.serialized)
struct URLRedactorTests {
    @Test
    func testRedactReplacesDomainWithPlaceholder() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/ios/dependency-guard")

        #expect(result == "https://REDACTED/ios/dependency-guard")
    }

    @Test
    func testRedactReplacesDomainWithPort() {
        DependencyGraphDependencyType.domains = ["s3.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://s3.example.com/Dependencies/ios/dependency-guard.xcframework.zip")

        #expect(result == "https://REDACTED/Dependencies/ios/dependency-guard.xcframework.zip")
    }

    @Test
    func testRedactPreservesQueryAndFragment() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/repo?ref=main&token=secret#section")

        #expect(result == "https://REDACTED/repo?ref=main&token=secret#section")
    }

    @Test
    func testRedactDoesNotAffectExternalDomains() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let external = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://github.com/Alamofire/Alamofire.git")

        #expect(external == "https://github.com/Alamofire/Alamofire.git")
    }

    @Test
    func testRedactWithEmptyDomainListReturnsOriginal() {
        DependencyGraphDependencyType.domains = []

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/repo")

        #expect(result == "https://gitlab.example.com/repo")
    }

    @Test
    func testRedactHandlesMultipleDomains() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com", "s3.example.com"]

        let result1 = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/ios/sample-dependency")
        let result2 = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://s3.example.com/Dependencies/ios/dependency-guard.xcframework.zip")

        #expect(result1 == "https://REDACTED/ios/sample-dependency")
        #expect(result2 == "https://REDACTED/Dependencies/ios/dependency-guard.xcframework.zip")
    }

    @Test
    func testRedactHandlesExactDomainMatch() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/ios/dependency-guard")

        #expect(result == "https://REDACTED/ios/dependency-guard")
    }

    @Test
    func testRedactHandlesInvalidURL() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "not-a-url")

        #expect(result == "not-a-url")
    }
}

@Suite(.serialized)
struct DependencyGraphRedactionTests {
    @Test
    func testRedactedRemotePackageMasksURL() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let type = DependencyGraphDependencyType.remotePackage(url: "https://gitlab.example.com/ios/dependency-guard", version: "1.1.8")

        #expect(type.redacted == .remotePackage(url: "https://REDACTED/ios/dependency-guard", version: "1.1.8"))
    }

    @Test
    func testRedactedRemoteBinaryMasksURL() {
        DependencyGraphDependencyType.domains = ["s3.example.com"]

        let type = DependencyGraphDependencyType.remoteBinary(url: "https://s3.example.com/Dependencies/ios/dependency-guard.xcframework.zip", checksum: "abc123")

        #expect(type.redacted == .remoteBinary(url: "https://REDACTED/Dependencies/ios/dependency-guard.xcframework.zip", checksum: "abc123"))
    }

    @Test
    func testRedactedLocalBinaryIsUnchanged() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let type = DependencyGraphDependencyType.localBinary(path: "/Users/user/.build/checkouts/sfmc-sdk-ios/Frameworks/SFMCSDK.xcframework")

        #expect(type.redacted == .localBinary(path: "/Users/user/.build/checkouts/sfmc-sdk-ios/Frameworks/SFMCSDK.xcframework"))
    }

    @Test
    func testRedactedDoesNotAffectExternalURLs() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let type = DependencyGraphDependencyType.remotePackage(url: "https://github.com/Alamofire/Alamofire.git", version: "5.9.1")

        #expect(type.redacted == .remotePackage(url: "https://github.com/Alamofire/Alamofire.git", version: "5.9.1"))
    }
}
