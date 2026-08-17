# DependencyGuard

DependencyGuard exports Swift Package Manager dependencies as JSON and compares two dependency graphs.

## Requirements

- macOS 26 or later
- Swift 6.2 or later
- A Swift Package Manager project whose dependencies will be inspected

## Usage

### 1. Generate a dependency graph

Pass the path of the Swift package for which you want to generate a dependency graph:

```bash
swift run DependencyGuard generate /path/to/swift-package
```

If no root path is provided, the current directory is used:

```bash
swift run DependencyGuard generate
```

The command creates a `DependencyGraph.json` file in the current directory.

To generate the complete dependency graph and keep only the dependencies used by
an Xcode target, pass the Xcode project and target name. The positional path is
still the Swift package root used to generate the complete graph:

```bash
swift run DependencyGuard generate /path/to/swift-package \
  --xcode-project /path/to/MyApp.xcodeproj \
  --target MyApp
```

The Xcode project is parsed with `XcodeProj`. Direct target dependencies,
transitive target dependencies, Swift Package products, and linked framework or
XCFramework names are collected from the target. Filtering is applied after the
complete Swift Package graph is generated, so selected package subdependencies
remain in the output. The Swift package root should point to the directory whose
`.build/workspace-state.json` and `swift package show-dependencies` describe the
resolved dependency graph.

Use `--verbose` to print the complete dependency list:

```bash
swift run DependencyGuard generate /path/to/swift-package --verbose
```

After building the release version, run the executable directly:

```bash
swift run DependencyGuard generate /path/to/swift-package
```

### 2. Compare two graphs

Pass the source and target dependency graph files with the `-s` and `-t` options:

```bash
swift run DependencyGuard validate \
  --source-dependency-graph /path/to/source/DependencyGraph.json \
  --target-dependency-graph /path/to/target/DependencyGraph.json
```

Short options can also be used:

```bash
swift run DependencyGuard validate \
  -s /path/to/source/DependencyGraph.json \
  -t /path/to/target/DependencyGraph.json
```

The validation output uses the following severity levels:

- `WARNING` indicates a difference that does not fail validation.
- `ERROR` indicates a validation failure and causes the command to exit with a non-zero status code.

## Running tests

```bash
swift test
```

## Help

To list all available commands:

```bash
swift run DependencyGuard --help
```

To list the options for a specific command:

```bash
swift run DependencyGuard generate --help
swift run DependencyGuard validate --help
```
