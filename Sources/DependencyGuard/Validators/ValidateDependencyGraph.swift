import ArgumentParser
import Foundation

struct ValidateDependencyGraph: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate source and target dependency graphs."
    )

    @Option(name: .shortAndLong, help: "Path to the source dependency graph (project graph).")
    var sourceDependencyGraph: String

    @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Path to a target dependency graph. Repeatable: -t a.json -t b.json")
    var targetDependencyGraph: [String]

    mutating func run() async throws {
        guard !targetDependencyGraph.isEmpty else { throw ValidationError("At least one --target-dependency-graph is required.") }

        let jsonDecoder = JSONDecoder()

        let sourceData = try Data(contentsOf: URL(filePath: sourceDependencyGraph))
        let source = try jsonDecoder.decode([DependencyGraph].self, from: sourceData)
        let sourceLabel = label(for: sourceDependencyGraph, isSource: true)

        print("Source: \(sourceDependencyGraph)")
        print("Targets:")

        var targets: [(label: String, graph: [DependencyGraph])] = []
        for (index, path) in targetDependencyGraph.enumerated() {
            do {
                let data = try Data(contentsOf: URL(filePath: path))
                let graph = try jsonDecoder.decode([DependencyGraph].self, from: data)
                let label = label(for: path, isSource: false)
                targets.append((label: label, graph: graph))
                print("  \(index + 1). \(path) (\(label))")
            } catch {
                print("  \(index + 1). \(path) — FAILED: \(error)")
                throw ExitCode.failure
            }
        }
        print("")

        let results = validateAll(
            source: (label: sourceLabel, graph: source),
            targets: targets
        )

        for comparison in results.comparisons {
            if comparison.issues.isEmpty {
                print("── \(comparison.sourceLabel) vs \(comparison.targetLabel) ── No issues.\n")
            } else {
                print("── \(comparison.sourceLabel) vs \(comparison.targetLabel) ──\n")
                comparison.issues.forEach { print($0.description, "\n") }
            }
        }

        if results.totalErrors == 0 && results.totalWarnings == 0 {
            print("All validations passed. No issues found.")
        } else {
            print("Validation completed with \(results.totalWarnings) warning(s) and \(results.totalErrors) error(s).")
        }

        if results.totalErrors > 0 {
            throw ExitCode.failure
        }
    }

    func validateAll(source: (label: String, graph: [DependencyGraph]), targets: [(label: String, graph: [DependencyGraph])]) -> ValidationResults {
        let validator = DependencyGraphValidator()
        var comparisons: [ComparisonResult] = []

        for target in targets {
            let issues = validator.validate(source: source.graph, target: target.graph, sourceLabel: source.label, targetLabel: target.label)
            comparisons.append(ComparisonResult(sourceLabel: source.label, targetLabel: target.label, issues: issues))
        }

        for i in 0..<targets.count {
            for j in (i + 1)..<targets.count {
                let issues = validator.validate(source: targets[i].graph, target: targets[j].graph, sourceLabel: targets[i].label, targetLabel: targets[j].label)
                comparisons.append(ComparisonResult(sourceLabel: targets[i].label, targetLabel: targets[j].label, issues: issues))
            }
        }

        return ValidationResults(comparisons: comparisons)
    }

    func label(for path: String, isSource: Bool) -> String {
        if isSource { return "source" }
        let url = URL(filePath: path)
        let parent = url.deletingLastPathComponent()
        let parentName = parent.lastPathComponent
        if parentName.isEmpty || parentName == "." || parent.path == FileManager.default.currentDirectoryPath {
            return url.lastPathComponent
        }
        return parentName
    }
}

struct ComparisonResult: Sendable {
    let sourceLabel: String
    let targetLabel: String
    let issues: [DependencyValidationIssue]
}

struct ValidationResults: Sendable {
    let comparisons: [ComparisonResult]

    var totalWarnings: Int {
        comparisons.flatMap(\.issues).filter { $0.severity == .warning }.count
    }

    var totalErrors: Int {
        comparisons.flatMap(\.issues).filter { $0.severity == .error }.count
    }
}
