import Testing
import Foundation
@testable import blog

class HTMLGeneratorTests {
    let testOutputPath: URL
    
    init() throws {
        testOutputPath = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("blog_test_output_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testOutputPath, withIntermediateDirectories: true)
    }
    
    deinit {
        try? FileManager.default.removeItem(at: testOutputPath)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func testGenerateBasicSite() async throws {
        let posts = [
            Post(
                title: "Test Post",
                date: Date(),
                tags: ["test1", "test2"],
                categories: ["cat1", "cat2"],
                slug: "test-post",
                content: "Test content"
            )
        ]
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: posts)
        try await generator.generate()
        
        // Check that all required directories exist
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: testOutputPath.path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "posts").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "tags").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "categories").path))
        
        // Check that index files exist
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "index.html").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "tags/index.html").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "categories/index.html").path))
        
        // Check that post files exist
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "posts/test-post/index.html").path))
        
        // Check that tag and category pages exist
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "tags/test1/index.html").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "tags/test2/index.html").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "categories/cat1/index.html").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "categories/cat2/index.html").path))
    }
    
    func testGenerateEmptySite() async throws {
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [])
        try await generator.generate()
        
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: testOutputPath.path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "index.html").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "tags/index.html").path))
        #expect(fileManager.fileExists(atPath: testOutputPath.appending(path: "categories/index.html").path))
        
        let indexHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        #expect(indexHTML.contains("No posts found"))
    }
    
    func testMarkdownContentRendering() async throws {
        let post = Post(
            title: "Test Post",
            date: Date(),
            tags: ["test"],
            categories: ["cat"],
            slug: "test-post",
            content: "# Heading\n\nThis is a **bold** text."
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        #expect(postHTML.contains("<h1>Heading</h1>"))
        #expect(postHTML.contains("This is a <strong>bold</strong> text."))
    }
    
    func testContentSanitization() async throws {
        let post = Post(
            title: "Test Post",
            date: Date(),
            tags: ["test"],
            categories: ["cat"],
            slug: "test-post",
            content: "Normal text <script>alert('xss')</script> More text"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        #expect(!postHTML.contains("<script>"))
        #expect(postHTML.contains("Normal text"))
        #expect(postHTML.contains("More text"))
    }
    
    func testMetadataRendering() async throws {
        let date = Date()
        let post = Post(
            title: "Test Post",
            date: date,
            tags: ["test1", "test2"],
            categories: ["cat1", "cat2"],
            slug: "test-post",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        
        // Check title
        #expect(postHTML.contains("<title>Test Post</title>"))
        #expect(postHTML.contains("<h1>Test Post</h1>"))
        
        // Check tags
        #expect(postHTML.contains("href=\"/tags/test1/\""))
        #expect(postHTML.contains("href=\"/tags/test2/\""))
        
        // Check categories
        #expect(postHTML.contains("href=\"/categories/cat1/\""))
        #expect(postHTML.contains("href=\"/categories/cat2/\""))
    }
    
    func testDateFormatting() async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "2024-02-10")!
        
        let post = Post(
            title: "Test Post",
            date: date,
            tags: ["test"],
            categories: ["cat"],
            slug: "test-post",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        
        // Check machine-readable date
        #expect(postHTML.contains("datetime=\"2024-02-10"))
        
        // Check human-readable date
        #expect(postHTML.contains("February 10, 2024"))
    }
    
    func testRelativeLinks() async throws {
        let post = Post(
            title: "Test Post",
            date: Date(),
            tags: ["test1", "test2"],
            categories: ["cat1", "cat2"],
            slug: "test-post",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        let indexHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        let tagHTML = try String(contentsOf: testOutputPath.appending(path: "tags/test1/index.html"))
        let categoryHTML = try String(contentsOf: testOutputPath.appending(path: "categories/cat1/index.html"))
        
        // Check post links
        #expect(indexHTML.contains("href=\"/posts/test-post/\""))
        #expect(tagHTML.contains("href=\"/posts/test-post/\""))
        #expect(categoryHTML.contains("href=\"/posts/test-post/\""))
        
        // Check tag links
        #expect(postHTML.contains("href=\"/tags/test1/\""))
        #expect(postHTML.contains("href=\"/tags/test2/\""))
        
        // Check category links
        #expect(postHTML.contains("href=\"/categories/cat1/\""))
        #expect(postHTML.contains("href=\"/categories/cat2/\""))
    }
    
    func testPostSorting() async throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)
        
        let posts = [
            Post(title: "Old Post", date: twoDaysAgo, tags: [], categories: [], slug: "old-post", content: ""),
            Post(title: "New Post", date: now, tags: [], categories: [], slug: "new-post", content: ""),
            Post(title: "Middle Post", date: yesterday, tags: [], categories: [], slug: "middle-post", content: "")
        ]
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: posts)
        try await generator.generate()
        
        let indexHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        
        // Check that posts are ordered from newest to oldest
        let newPostIndex = indexHTML.range(of: "New Post")?.lowerBound
        let middlePostIndex = indexHTML.range(of: "Middle Post")?.lowerBound
        let oldPostIndex = indexHTML.range(of: "Old Post")?.lowerBound
        
        guard let new = newPostIndex, let middle = middlePostIndex, let old = oldPostIndex else {
            throw TestError("Could not find all posts in index.html")
        }
        
        #expect(new < middle)
        #expect(middle < old)
    }
    
    func testPostUpdates() async throws {
        let publishDate = Date()
        let firstUpdateDate = publishDate.addingTimeInterval(86400) // 1 day later
        let secondUpdateDate = publishDate.addingTimeInterval(172800) // 2 days later
        
        let post = Post(
            title: "Test Post",
            date: publishDate,
            tags: ["test"],
            categories: ["cat"],
            slug: "test-post",
            content: "Original content",
            updates: [
                Update(date: firstUpdateDate, description: "Added new section"),
                Update(date: secondUpdateDate, description: "Fixed typos")
            ]
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/test-post/index.html"))
        
        // Check updates section exists
        #expect(postHTML.contains("<section class=\"updates\">"))
        #expect(postHTML.contains("<h2>Updates</h2>"))
        
        // Check updates are displayed in reverse chronological order
        let firstUpdateIndex = postHTML.range(of: "Added new section")?.lowerBound
        let secondUpdateIndex = postHTML.range(of: "Fixed typos")?.lowerBound
        
        guard let first = firstUpdateIndex, let second = secondUpdateIndex else {
            throw TestError("Could not find update descriptions in HTML")
        }
        
        #expect(second < first, "Updates should be displayed in reverse chronological order")
        
        // Check update dates are properly formatted
        #expect(postHTML.contains(formatDate(firstUpdateDate)))
        #expect(postHTML.contains(formatDate(secondUpdateDate)))
        
        // Check updates badge in post lists
        let indexHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        #expect(indexHTML.contains("<span class=\"update-badge\""))
        #expect(indexHTML.contains("Last updated \(formatDate(secondUpdateDate))"))
    }
    
    func testAllPostsPage() async throws {
        let date = Date()
        let posts = [
            Post(
                title: "First Post",
                date: date.addingTimeInterval(-86400), // Yesterday
                tags: ["tag1"],
                categories: ["cat1"],
                slug: "first-post",
                content: "First content"
            ),
            Post(
                title: "Second Post",
                date: date,
                tags: ["tag2"],
                categories: ["cat2"],
                slug: "second-post",
                content: "Second content",
                updates: [Update(date: date, description: "Updated content")]
            )
        ]
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: posts)
        try await generator.generate()
        
        let allPostsHTML = try String(contentsOf: testOutputPath.appending(path: "posts/index.html"))
        
        // Check page structure
        #expect(allPostsHTML.contains("<main>"))
        #expect(allPostsHTML.contains("<h1>All Posts</h1>"))
        #expect(allPostsHTML.contains("<ul class=\"post-list\">"))
        #expect(allPostsHTML.contains("<footer>"))
        
        // Check navigation
        #expect(allPostsHTML.contains("<nav role=\"navigation\""))
        #expect(allPostsHTML.contains("<a href=\"../\">Home</a>"))
        
        // Check post entries
        #expect(allPostsHTML.contains("<h2><a href=\"first-post\">First Post</a></h2>"))
        #expect(allPostsHTML.contains("<h2><a href=\"second-post\">Second Post</a></h2>"))
        
        // Check metadata
        #expect(allPostsHTML.contains("class=\"meta\""))
        #expect(allPostsHTML.contains("class=\"meta-label\""))
        #expect(allPostsHTML.contains("<time datetime="))
        
        // Check updates
        #expect(allPostsHTML.contains("Updated content"))
        
        // Check tags and categories
        #expect(allPostsHTML.contains("href=\"../tags/tag1\""))
        #expect(allPostsHTML.contains("href=\"../tags/tag2\""))
        #expect(allPostsHTML.contains("href=\"../categories/cat1\""))
        #expect(allPostsHTML.contains("href=\"../categories/cat2\""))
    }
    
    func testAllPostsSorting() async throws {
        let now = Date()
        let posts = [
            Post(
                title: "Old Post",
                date: now.addingTimeInterval(-172800), // 2 days ago
                tags: [],
                categories: [],
                slug: "old-post",
                content: ""
            ),
            Post(
                title: "New Post",
                date: now,
                tags: [],
                categories: [],
                slug: "new-post",
                content: ""
            ),
            Post(
                title: "Middle Post",
                date: now.addingTimeInterval(-86400), // Yesterday
                tags: [],
                categories: [],
                slug: "middle-post",
                content: ""
            )
        ]
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: posts)
        try await generator.generate()
        
        let allPostsHTML = try String(contentsOf: testOutputPath.appending(path: "posts/index.html"))
        
        // Check that posts are ordered from newest to oldest
        let newPostIndex = allPostsHTML.range(of: "New Post")?.lowerBound
        let middlePostIndex = allPostsHTML.range(of: "Middle Post")?.lowerBound
        let oldPostIndex = allPostsHTML.range(of: "Old Post")?.lowerBound
        
        guard let new = newPostIndex, let middle = middlePostIndex, let old = oldPostIndex else {
            throw TestError("Could not find all posts in index.html")
        }
        
        #expect(new < middle)
        #expect(middle < old)
    }
    
    func testAllPostsAccessibility() async throws {
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
        
        let allPostsHTML = try String(contentsOf: testOutputPath.appending(path: "posts/index.html"))
        
        // Check semantic HTML structure
        #expect(allPostsHTML.contains("<main>"))
        #expect(allPostsHTML.contains("<h1>"))
        #expect(allPostsHTML.contains("<footer>"))
        
        // Check ARIA roles
        #expect(allPostsHTML.contains("role=\"navigation\""))
        #expect(allPostsHTML.contains("aria-label=\"Main navigation\""))
        #expect(allPostsHTML.contains("role=\"list\""))
        #expect(allPostsHTML.contains("role=\"listitem\""))
        
        // Check meta tags
        #expect(allPostsHTML.contains("<meta charset=\"UTF-8\">"))
        #expect(allPostsHTML.contains("<meta name=\"viewport\""))
        
        // Check dark mode support
        #expect(allPostsHTML.contains("@media (prefers-color-scheme: dark)"))
        
        // Check responsive design
        #expect(allPostsHTML.contains("@media (max-width: 480px)"))
    }
} 