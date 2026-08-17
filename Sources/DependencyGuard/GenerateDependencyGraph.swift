import ArgumentParser
import Foundation

struct GenerateDependencyGraph: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate a dependency graph for a Swift package."
    )

    @Argument var spmRoot: String = "."
    @Option(name: .long, help: "Path to an Xcode project used to select target dependencies.")
    var xcodeProject: String?
    @Option(name: .long, help: "Xcode target name to include in the dependency graph.")
    var target: String?
    @Flag(help: "verbose logging") var verbose: Bool = false
    @Option(name: .long, help: "Comma-separated list of domains to redact from URLs in the output graph.")
    var redactedDomains: String?

    mutating func run() async throws {
        switch (xcodeProject, target) {
        case (.some, .none):
            throw ValidationError("--target is required when --xcode-project is provided")
        case (.none, .some):
            throw ValidationError("--xcode-project is required when --target is provided")
        default:
            break
        }

        let xcFrameworks = try await WorkspaceStateProcessor().xcFrameworks(from: spmRoot)
        let dependencyList = try await DependencyListProcessor().dependencyTree(from: spmRoot)

        let completeDependencyGraph = DependencyGraphGenerator().generate(
            dependencyList: dependencyList,
            xcFrameworks: xcFrameworks
        )
        var dependencyGraph = completeDependencyGraph

        if let xcodeProject, let target {
            let packageProducts = try await PackageProductsProcessor().products(from: dependencyList)
            let selection = try XcodeProjectDependencyProcessor().selection(
                projectPath: xcodeProject,
                targetName: target,
                packageProducts: packageProducts
            )
            dependencyGraph = dependencyGraph.filtered(using: selection)
        }

        if let redactedDomains {
            DependencyGraphDependencyType.domains = Set(redactedDomains.components(separatedBy: ","))
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(dependencyGraph)

        let fileUrl = URL(filePath: FileManager.default.currentDirectoryPath).appending(path: "DependencyGraph.json")
        try data.write(to: fileUrl)

        print("Dependency list generation complete")
        print("generation result", fileUrl.path())
        print(" - Direct Dependency Count: \(dependencyGraph.count)")
        let uniqueDependencyNames = Set(dependencyGraph.flattenedByIdentity.values.map(\.name))
        print(" - Total Dependency Count: \(uniqueDependencyNames.count)")

        if verbose {
            print("All Dependencies:")
            let dependencies = uniqueDependencyNames
                .sorted()
                .enumerated()
                .map { "\t\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            print(dependencies)

            if xcodeProject != nil, target != nil {
                let allDependencies = completeDependencyGraph.flattenedByIdentity
                let selectedDependencies = dependencyGraph.flattenedByIdentity
                let unusedDependencies = allDependencies
                    .filter { selectedDependencies[$0.key] == nil }
                    .map(\.value.name)
                    .sorted()

                print("Unused Dependencies:")
                print(unusedDependencies.enumerated()
                    .map { "\t\($0.offset + 1). \($0.element)" }
                    .joined(separator: "\n"))
            }
        }
    }
}
