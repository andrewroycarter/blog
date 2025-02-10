import Testing
import Foundation
@testable import blog

class AccessibilityTests {
    let testOutputPath: URL
    
    init() throws {
        testOutputPath = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("blog_test_output_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testOutputPath, withIntermediateDirectories: true)
    }
    
    deinit {
        try? FileManager.default.removeItem(at: testOutputPath)
    }
    
    func testPostPageAccessibility() async throws {
        let post = Post(
            title: "Test Post",
            date: Date(),
            tags: ["test1", "test2"],
            categories: ["cat1"],
            slug: "test-post",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        
        // Check for semantic HTML structure
        #expect(postHTML.contains("<main>"))
        #expect(postHTML.contains("<header>"))
        #expect(postHTML.contains("<article>"))
        #expect(postHTML.contains("<footer>"))
        
        // Check for ARIA roles and labels
        #expect(postHTML.contains("role=\"navigation\""))
        #expect(postHTML.contains("aria-label=\"Main navigation\""))
        #expect(postHTML.contains("role=\"list\""))
        #expect(postHTML.contains("role=\"listitem\""))
        
        // Check for meta tags
        #expect(postHTML.contains("<meta name=\"viewport\""))
        #expect(postHTML.contains("<meta name=\"description\""))
        
        // Check for dark mode support
        #expect(postHTML.contains("@media (prefers-color-scheme: dark)"))
        
        // Check for responsive design
        #expect(postHTML.contains("@media (max-width: 480px)"))
        #expect(postHTML.contains("@media (min-width: 640px)"))
        
        // Check for image responsiveness
        #expect(postHTML.contains("max-width: 100%"))
        #expect(postHTML.contains("height: auto"))
    }
    
    func testMetadataAccessibility() async throws {
        let post = Post(
            title: "Test Post",
            date: Date(),
            tags: ["test"],
            categories: ["cat"],
            slug: "test-post",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        
        // Check for semantic metadata structure
        #expect(postHTML.contains("<time datetime="))
        #expect(postHTML.contains("class=\"meta-label\""))
        
        // Check for proper heading hierarchy
        let h1Count = postHTML.components(separatedBy: "<h1>").count - 1
        #expect(h1Count == 1, "Page should have exactly one h1 heading")
    }
    
    func testNavigationAccessibility() async throws {
        let post = Post(
            title: "Test Post",
            date: Date(),
            tags: ["test"],
            categories: ["cat"],
            slug: "test-post",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        // Check homepage navigation
        let homeHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        #expect(homeHTML.contains("role=\"navigation\""))
        
        // Check category page navigation
        let categoryHTML = try String(contentsOf: testOutputPath.appending(path: "categories/cat/index.html"))
        #expect(categoryHTML.contains("role=\"navigation\""))
        
        // Check tag page navigation
        let tagHTML = try String(contentsOf: testOutputPath.appending(path: "tags/test/index.html"))
        #expect(tagHTML.contains("role=\"navigation\""))
    }
    
    func testColorContrast() async throws {
        let post = Post(
            title: "Test Post",
            date: Date(),
            tags: [],
            categories: [],
            slug: "test-post",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        
        // Check for proper color contrast in light and dark modes
        #expect(postHTML.contains("color: #666")) // Meta text color
        #expect(postHTML.contains("color: #0366d6")) // Link color
        #expect(postHTML.contains("color: #58a6ff")) // Dark mode link color
    }
} 