import XCTest
@testable import DependencyGuard

final class URLRedactorTests: XCTestCase {
    func testRedactReplacesDomainWithPlaceholder() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/ios/dependency-guard")

        XCTAssertEqual(result, "https://REDACTED/ios/dependency-guard")
    }

    func testRedactReplacesDomainWithPort() {
        DependencyGraphDependencyType.domains = ["s3.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://s3.example.com/Dependencies/ios/dependency-guard.xcframework.zip")

        XCTAssertEqual(result, "https://REDACTED/Dependencies/ios/dependency-guard.xcframework.zip")
    }

    func testRedactPreservesQueryAndFragment() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/repo?ref=main&token=secret#section")

        XCTAssertEqual(result, "https://REDACTED/repo?ref=main&token=secret#section")
    }

    func testRedactDoesNotAffectExternalDomains() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let external = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://github.com/Alamofire/Alamofire.git")

        XCTAssertEqual(external, "https://github.com/Alamofire/Alamofire.git")
    }

    func testRedactWithEmptyDomainListReturnsOriginal() {
        DependencyGraphDependencyType.domains = []

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/repo")

        XCTAssertEqual(result, "https://gitlab.example.com/repo")
    }

    func testRedactHandlesMultipleDomains() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com", "s3.example.com"]

        let result1 = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/ios/sample-dependency")
        let result2 = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://s3.example.com/Dependencies/ios/dependency-guard.xcframework.zip")

        XCTAssertEqual(result1, "https://REDACTED/ios/sample-dependency")
        XCTAssertEqual(result2, "https://REDACTED/Dependencies/ios/dependency-guard.xcframework.zip")
    }

    func testRedactHandlesExactDomainMatch() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "https://gitlab.example.com/ios/dependency-guard")

        XCTAssertEqual(result, "https://REDACTED/ios/dependency-guard")
    }

    func testRedactHandlesInvalidURL() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let result = DependencyGraphDependencyType.remotePackage(url: "", version: "").redact(originUrl: "not-a-url")

        XCTAssertEqual(result, "not-a-url")
    }
}

final class DependencyGraphRedactionTests: XCTestCase {
    func testRedactedRemotePackageMasksURL() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let type = DependencyGraphDependencyType.remotePackage(url: "https://gitlab.example.com/ios/dependency-guard", version: "1.1.8")

        XCTAssertEqual(type.redacted, .remotePackage(url: "https://REDACTED/ios/dependency-guard", version: "1.1.8"))
    }

    func testRedactedRemoteBinaryMasksURL() {
        DependencyGraphDependencyType.domains = ["s3.example.com"]

        let type = DependencyGraphDependencyType.remoteBinary(url: "https://s3.example.com/Dependencies/ios/dependency-guard.xcframework.zip", checksum: "abc123")

        XCTAssertEqual(type.redacted, .remoteBinary(url: "https://REDACTED/Dependencies/ios/dependency-guard.xcframework.zip", checksum: "abc123"))
    }

    func testRedactedLocalBinaryIsUnchanged() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let type = DependencyGraphDependencyType.localBinary(path: "/Users/user/.build/checkouts/sfmc-sdk-ios/Frameworks/SFMCSDK.xcframework")

        XCTAssertEqual(type.redacted, .localBinary(path: "/Users/user/.build/checkouts/sfmc-sdk-ios/Frameworks/SFMCSDK.xcframework"))
    }

    func testRedactedDoesNotAffectExternalURLs() {
        DependencyGraphDependencyType.domains = ["gitlab.example.com"]

        let type = DependencyGraphDependencyType.remotePackage(url: "https://github.com/Alamofire/Alamofire.git", version: "5.9.1")

        XCTAssertEqual(type.redacted, .remotePackage(url: "https://github.com/Alamofire/Alamofire.git", version: "5.9.1"))
    }
}
