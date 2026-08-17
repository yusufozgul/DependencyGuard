import ArgumentParser
import Foundation

struct ValidateDependencyGraph: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate source and target dependency graphs."
    )

    @Option(name: .shortAndLong, help: "Path to the source dependency graph.")
    var sourceDependencyGraph: String

    @Option(name: .shortAndLong, help: "Path to the target dependency graph.")
    var targetDependencyGraph: String

    mutating func run() async throws {
        let jsonDecoder = JSONDecoder()
        let sourceData = try Data(contentsOf: URL(filePath: sourceDependencyGraph))
        let targetData = try Data(contentsOf: URL(filePath: targetDependencyGraph))
        let source = try jsonDecoder.decode([DependencyGraph].self, from: sourceData)
        let target = try jsonDecoder.decode([DependencyGraph].self, from: targetData)

        let issues = DependencyGraphValidator().validate(source: source, target: target)
        issues.forEach { print($0.description, "\n") }

        let warnings = issues.filter { $0.severity == .warning }.count
        let errors = issues.filter { $0.severity == .error }.count
        print("Validation completed with \(warnings) warning(s) and \(errors) error(s).")

        if errors > 0 {
            throw ExitCode.failure
        }
    }
}
