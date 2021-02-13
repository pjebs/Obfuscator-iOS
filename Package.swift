// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Obfuscator",
    products: [.library(name: "Obfuscator", targets: ["Obfuscator"])],
    targets: [.target(name: "Obfuscator",
                      path: ".",
                      exclude: ["Obfuscator.podspec", "./Example/ExampleTests/"],
                      resources: [.copy("./Example"),
                                  .copy("README.md"),
                                  .copy("LICENSE")],
                      publicHeadersPath: "include"
    )]
)
