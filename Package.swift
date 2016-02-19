import PackageDescription

let package = Package(
    name: "SocketKit",
    dependencies: [
        .Package(url: "https://github.com/eswick/StreamKit.git", majorVersion: 0, minor: 8)
    ]
)