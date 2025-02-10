import ArgumentParser
import blog
import Foundation

@main
struct BlogCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "blog",
        abstract: "A static blog generator",
        subcommands: [BuildCommand.self]
    )
}

struct BuildCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the static site"
    )
    
    @Option(name: .shortAndLong, help: "The directory containing the posts")
    var postsDir: String = "posts"
    
    @Option(name: .shortAndLong, help: "The output directory for the static site")
    var outputDir: String = "public"
    
    func run() async throws {
        let postsURL = URL(filePath: postsDir)
        let outputURL = URL(filePath: outputDir)
        
        print("Loading posts from \(postsDir)...")
        let loader = PostLoader(postsDirectory: postsURL)
        let posts = try await loader.loadPosts()
        print("Loaded \(posts.count) posts")
        
        print("Generating static site in \(outputDir)...")
        let generator = HTMLGenerator(outputDirectory: outputURL, posts: posts)
        try await generator.generate()
        print("Static site generation complete!")
    }
} 