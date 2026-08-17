import Foundation

struct SemanticVersion: Comparable {
    private enum PreReleaseIdentifier: Equatable {
        case numeric(Int)
        case text(String)
    }
    
    let major: Int
    let minor: Int
    let patch: Int
    private let preRelease: [PreReleaseIdentifier]
    
    init?(_ value: String) {
        let components = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false)

        guard components.count <= 2,
              components.dropFirst().allSatisfy(Self.isValidIdentifiers)
        else { return nil }

        let version = components[0].split(
            separator: "-", maxSplits: 1, omittingEmptySubsequences: false
        )
        let core = version[0].split(separator: ".", omittingEmptySubsequences: false)

        guard core.count == 3,
              let major = Self.parseNumericIdentifier(core[0]),
              let minor = Self.parseNumericIdentifier(core[1]),
              let patch = Self.parseNumericIdentifier(core[2])
        else { return nil }

        self.major = major
        self.minor = minor
        self.patch = patch

        guard version.count == 1 || !version[1].isEmpty else { return nil }

        if version.count == 1 {
            self.preRelease = []
        } else {
            let identifiers = version[1].split(separator: ".", omittingEmptySubsequences: false)
            let parsedIdentifiers = identifiers.compactMap(Self.parsePreReleaseIdentifier)

            guard parsedIdentifiers.count == identifiers.count else { return nil }
            self.preRelease = parsedIdentifiers
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        if lhs.preRelease.isEmpty || rhs.preRelease.isEmpty {
            return !lhs.preRelease.isEmpty && rhs.preRelease.isEmpty
        }

        for (lhsIdentifier, rhsIdentifier) in zip(lhs.preRelease, rhs.preRelease) {
            switch (lhsIdentifier, rhsIdentifier) {
            case let (.numeric(lhsValue), .numeric(rhsValue)) where lhsValue != rhsValue:
                return lhsValue < rhsValue
            case (.numeric, .text):
                return true
            case (.text, .numeric):
                return false
            case let (.text(lhsValue), .text(rhsValue)) where lhsValue != rhsValue:
                return lhsValue < rhsValue
            default:
                continue
            }
        }

        return lhs.preRelease.count < rhs.preRelease.count
    }

    private static func parseNumericIdentifier(_ value: Substring) -> Int? {
        guard !value.isEmpty,
              value.allSatisfy({ $0 >= "0" && $0 <= "9" }),
              value.count == 1 || value.first != "0"
        else { return nil }

        return Int(value)
    }

    private static func parsePreReleaseIdentifier(_ value: Substring) -> PreReleaseIdentifier? {
        guard isValidIdentifier(value) else { return nil }

        if value.allSatisfy({ $0 >= "0" && $0 <= "9" }) {
            return parseNumericIdentifier(value).map { .numeric($0) }
        }

        return .text(String(value))
    }

    private static let validIdentifierCharacters = CharacterSet(
        charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-"
    )

    private static func isValidIdentifier(_ value: Substring) -> Bool {
        !value.isEmpty && value.unicodeScalars.allSatisfy {
            validIdentifierCharacters.contains($0)
        }
    }

    private static func isValidIdentifiers(_ value: Substring) -> Bool {
        value.split(separator: ".", omittingEmptySubsequences: false).allSatisfy {
            isValidIdentifier($0)
        }
    }
}
