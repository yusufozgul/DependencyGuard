import Foundation
import Subprocess

struct PackageProductsProcessor {
    func products(from dependencyList: [SPMDependency]) async throws -> [SPMPackageProducts] {
        try await withThrowingTaskGroup(of: SPMPackageProducts.self) { group in
            var processedPaths = Set<String>()

            for dependency in dependencyList.flattened where processedPaths.insert(dependency.path).inserted {
                group.addTask {
                    try await products(for: dependency)
                }
            }

            return try await group.reduce(into: []) { products, packageProducts in
                products.append(packageProducts)
            }
        }
    }

    private func products(for dependency: SPMDependency) async throws -> SPMPackageProducts {
        var standardOutput = ""
        var standardError = ""

        let result = try await run(
            .name("swift"),
            arguments: ["package", "dump-package", "--package-path", dependency.path],
            workingDirectory: .init(dependency.path),
            input: .none,
            output: .sequence,
            error: .sequence
        ) { execution in
            for try await line in execution.standardOutput.strings() {
                standardOutput += line + "\n"
            }
            for try await line in execution.standardError.strings() {
                standardError += line + "\n"
            }
        }

        guard result.terminationStatus == .exited(0) else {
            throw PackageProductsProcessorError.failedToReadProducts(
                path: dependency.path,
                message: standardError
            )
        }

        let description = try JSONDecoder().decode(
            SPMPackageDescription.self,
            from: Data(standardOutput.utf8)
        )

        return SPMPackageProducts(
            identity: dependency.identity,
            names: Set(description.products.map(\.name))
        )
    }
}

private extension [SPMDependency] {
    var flattened: [SPMDependency] {
        flatMap { [$0] + $0.dependencies.flattened }
    }
}

enum PackageProductsProcessorError: LocalizedError {
    case failedToReadProducts(path: String, message: String)

    var errorDescription: String? {
        switch self {
        case let .failedToReadProducts(path, message):
            "Failed to read package products at '\(path)': \(message)"
        }
    }
}
