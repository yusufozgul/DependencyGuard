# DependencyGuard

DependencyGuard exports Swift Package Manager dependencies as JSON and compares two dependency graphs.

## Requirements

- macOS 26 or later
- Swift 6.2 or later
- A Swift Package Manager project whose dependencies will be inspected

## Usage

### 0. Install DependencyGuard
[Github Releases](https://github.com/yusufozgul/DependencyGuard/releases/latest)
```bash
sudo mv DependencyGuard usr/local/bin/DependencyGuard
```

### 1. Generate a dependency graph

Pass the path of the Swift package for which you want to generate a dependency graph:

```bash
DependencyGuard generate /path/to/swift-package
```

If no root path is provided, the current directory is used:

```bash
DependencyGuard generate
```

The command creates a `DependencyGraph.json` file in the current directory.

To generate the complete dependency graph and keep only the dependencies used by
an Xcode target, pass the Xcode project and target name. The positional path is
still the Swift package root used to generate the complete graph:

```bash
DependencyGuard generate /path/to/swift-package \
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
DependencyGuard generate /path/to/swift-package --verbose
```

When filtering with `--xcode-project` and `--target`, `--verbose` also prints
the list of unused dependencies that were filtered out.

Use `--redacted-domains` to mask sensitive host names (e.g. internal Git or
storage servers) in the output graph. Pass a comma-separated list of domains;
matching hosts are replaced with `REDACTED` while the rest of the URL is
preserved:

```bash
DependencyGuard generate /path/to/swift-package \
  --redacted-domains gitlab.example.com,s3.example.com
```

Redaction applies to both remote package and remote binary URLs. Local binary
paths and external (non-listed) domains are left unchanged.

After building the release version, run the executable directly:

```bash
DependencyGuard generate /path/to/swift-package
```

### 2. Compare two graphs

Pass the source and target dependency graph files with the `-s` and `-t` options:

```bash
DependencyGuard validate \
  --source-dependency-graph /path/to/source/DependencyGraph.json \
  --target-dependency-graph /path/to/target/DependencyGraph.json
```

Short options can also be used:

```bash
DependencyGuard validate \
  -s /path/to/source/DependencyGraph.json \
  -t /path/to/target/DependencyGraph.json
```

Each issue is printed as:

```
SEVERITY identity: message
```

The validation output uses the following severity levels:

- `WARNING` indicates a difference that does not fail validation:
  - Source version is newer than target version (same major)
  - Dependency URL differs between source and target
- `ERROR` indicates a validation failure and causes the command to exit with a non-zero status code:
  - Target version is not compatible with source version (different major)
  - Binary checksum differs
  - Dependency type differs between source and target
  - Invalid semantic version

## Running tests

```bash
swift test
```

## Help

To list all available commands:

```bash
DependencyGuard --help
```

To list the options for a specific command:

```bash
ependencyGuard generate --help
DependencyGuard validate --help
```

### Options

| Command | Option | Description |
| --- | --- | --- |
| `generate` | `--xcode-project` | Path to an Xcode project used to select target dependencies |
| `generate` | `--target` | Xcode target name to include in the dependency graph |
| `generate` | `--verbose` | Print the complete dependency list and unused dependencies |
| `generate` | `--redacted-domains` | Comma-separated list of domains to redact from URLs |
| `validate` | `-s`, `--source-dependency-graph` | Path to the source dependency graph |
| `validate` | `-t`, `--target-dependency-graph` | Path to the target dependency graph |
