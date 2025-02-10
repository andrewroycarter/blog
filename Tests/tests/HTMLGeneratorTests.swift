import XCTest
@testable import blog
import Foundation

final class HTMLGeneratorTests: XCTestCase {
    let testOutputPath = FileManager.default.temporaryDirectory.appending(path: "blog_test_output")
    
    override func setUp() async throws {
        try? FileManager.default.removeItem(at: testOutputPath)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testOutputPath)
    }
    
    func testGenerateBasicSite() async throws {
        let posts = [
            Post(
                title: "First Post",
                date: Date(),
                tags: ["swift", "programming"],
                categories: ["development"],
                slug: "first-post",
                content: "This is my first post"
            ),
            Post(
                title: "Second Post",
                date: Date().addingTimeInterval(-86400), // Yesterday
                tags: ["swift"],
                categories: ["development"],
                slug: "second-post",
                content: "This is my second post"
            )
        ]
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: posts)
        try await generator.generate()
        
        // Check that all required directories were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "posts").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "categories").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "tags").path()))
        
        // Check that index.html was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "index.html").path()))
        
        // Check that post files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "posts/first-post/index.html").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "posts/second-post/index.html").path()))
        
        // Check that category files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "categories/development/index.html").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "categories/index.html").path()))
        
        // Check that tag files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "tags/swift/index.html").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "tags/programming/index.html").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "tags/index.html").path()))
        
        // Check content of a post file
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/first-post/index.html"))
        XCTAssertTrue(postHTML.contains("First Post"))
        XCTAssertTrue(postHTML.contains("This is my first post"))
        XCTAssertTrue(postHTML.contains("swift"))
        XCTAssertTrue(postHTML.contains("programming"))
        XCTAssertTrue(postHTML.contains("development"))
        
        // Check content of homepage
        let homeHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        XCTAssertTrue(homeHTML.contains("First Post"))
        XCTAssertTrue(homeHTML.contains("Second Post"))
        
        // Check content of a category page
        let categoryHTML = try String(contentsOf: testOutputPath.appending(path: "categories/development/index.html"))
        XCTAssertTrue(categoryHTML.contains("First Post"))
        XCTAssertTrue(categoryHTML.contains("Second Post"))
        
        // Check content of a tag page
        let tagHTML = try String(contentsOf: testOutputPath.appending(path: "tags/swift/index.html"))
        XCTAssertTrue(tagHTML.contains("First Post"))
        XCTAssertTrue(tagHTML.contains("Second Post"))
    }
    
    func testGenerateEmptySite() async throws {
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [])
        try await generator.generate()
        
        // Check that all required directories were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "posts").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "categories").path()))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "tags").path()))
        
        // Check that index.html was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: testOutputPath.appending(path: "index.html").path()))
        
        // Check content of homepage (should be empty but valid)
        let homeHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        XCTAssertTrue(homeHTML.contains("Recent Posts"))
        XCTAssertTrue(homeHTML.contains("View all posts"))
    }
    
    func testMarkdownContentRendering() async throws {
        let post = Post(
            title: "Content Test",
            date: Date(),
            tags: [],
            categories: [],
            slug: "content-test",
            content: "# Test Heading\n\nTest paragraph"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/content-test/index.html"))
        
        // Only test that content is rendered within the content div
        XCTAssertTrue(postHTML.contains("<div class=\"content\">"))
        XCTAssertTrue(postHTML.contains("Test Heading"))
        XCTAssertTrue(postHTML.contains("Test paragraph"))
    }
    
    func testContentSanitization() async throws {
        let post = Post(
            title: "Sanitization Test",
            date: Date(),
            tags: [],
            categories: [],
            slug: "sanitization-test",
            content: "<script>alert('xss')</script>\nNormal content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/sanitization-test/index.html"))
        
        // Verify that script tags are escaped/removed
        XCTAssertFalse(postHTML.contains("<script>"))
        XCTAssertTrue(postHTML.contains("Normal content"))
    }
    
    func testMetadataRendering() async throws {
        let date = Date()
        let post = Post(
            title: "Metadata Test",
            date: date,
            tags: ["tag1", "tag2"],
            categories: ["cat1"],
            slug: "metadata-test",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/metadata-test/index.html"))
        
        // Test that metadata is properly rendered in the HTML
        XCTAssertTrue(postHTML.contains("Metadata Test</h1>"))
        XCTAssertTrue(postHTML.contains("href=\"../../tags/tag1\""))
        XCTAssertTrue(postHTML.contains("href=\"../../tags/tag2\""))
        XCTAssertTrue(postHTML.contains("href=\"../../categories/cat1\""))
        XCTAssertTrue(postHTML.contains(formatDate(date)))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func testDateFormatting() async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: "2024-02-10T15:30:00+0000")!
        
        let post = Post(
            title: "Date Test",
            date: date,
            tags: [],
            categories: [],
            slug: "date-test",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/date-test/index.html"))
        
        // Check both machine-readable and human-readable dates
        XCTAssertTrue(postHTML.contains("datetime=\"2024-02-10T15:30:00Z\""))
        XCTAssertTrue(postHTML.contains("February 10, 2024"))
    }
    
    func testRelativeLinks() async throws {
        let post = Post(
            title: "Link Test",
            date: Date(),
            tags: ["test"],
            categories: ["testing"],
            slug: "link-test",
            content: "Test content"
        )
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: [post])
        try await generator.generate()
        
        // Check homepage links
        let homeHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        XCTAssertTrue(homeHTML.contains("href=\"posts/link-test\""))
        XCTAssertTrue(homeHTML.contains("href=\"categories\""))
        XCTAssertTrue(homeHTML.contains("href=\"tags\""))
        
        // Check post page links
        let postHTML = try String(contentsOf: testOutputPath.appending(path: "posts/link-test/index.html"))
        XCTAssertTrue(postHTML.contains("href=\"../../\"")) // Home link
        XCTAssertTrue(postHTML.contains("href=\"../../categories/testing\""))
        XCTAssertTrue(postHTML.contains("href=\"../../tags/test\""))
        
        // Check category page links
        let categoryHTML = try String(contentsOf: testOutputPath.appending(path: "categories/testing/index.html"))
        XCTAssertTrue(categoryHTML.contains("href=\"../../\"")) // Home link
        XCTAssertTrue(categoryHTML.contains("href=\"../../posts/link-test\""))
        
        // Check tag page links
        let tagHTML = try String(contentsOf: testOutputPath.appending(path: "tags/test/index.html"))
        XCTAssertTrue(tagHTML.contains("href=\"../../\"")) // Home link
        XCTAssertTrue(tagHTML.contains("href=\"../../posts/link-test\""))
    }
    
    func testPostSorting() async throws {
        let now = Date()
        let posts = [
            Post(title: "Oldest", date: now.addingTimeInterval(-172800), tags: [], categories: [], slug: "oldest", content: ""),
            Post(title: "Newest", date: now, tags: [], categories: [], slug: "newest", content: ""),
            Post(title: "Middle", date: now.addingTimeInterval(-86400), tags: [], categories: [], slug: "middle", content: "")
        ]
        
        let generator = HTMLGenerator(outputDirectory: testOutputPath, posts: posts)
        try await generator.generate()
        
        let homeHTML = try String(contentsOf: testOutputPath.appending(path: "index.html"))
        
        // Check that posts are sorted newest to oldest
        let firstPostIndex = homeHTML.range(of: "Newest")!.lowerBound
        let secondPostIndex = homeHTML.range(of: "Middle")!.lowerBound
        let thirdPostIndex = homeHTML.range(of: "Oldest")!.lowerBound
        
        XCTAssertTrue(firstPostIndex < secondPostIndex)
        XCTAssertTrue(secondPostIndex < thirdPostIndex)
    }
} 