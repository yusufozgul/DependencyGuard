import ArgumentParser

@main
struct DependencyGuard: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate and validate Swift package dependency graphs.",
        subcommands: [
            GenerateDependencyGraph.self,
            ValidateDependencyGraph.self
        ],
        defaultSubcommand: GenerateDependencyGraph.self
    )
}
