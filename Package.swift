import PackageDescription

let package = Package(
    name: "SocketKit",
    dependencies: [
        .Package(url: "../StreamKit", majorVersion: 0, minor: 8)
    ]
)