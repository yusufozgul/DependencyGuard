struct SPMPackageProducts: Sendable, Equatable, Hashable {
    let identity: String
    let names: Set<String>
}

struct SPMPackageDescription: Decodable {
    let products: [Product]

    struct Product: Decodable {
        let name: String
    }
}
