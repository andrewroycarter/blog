import XCTest
@testable import blog
import Foundation

final class PostLoaderTests: XCTestCase {
    let testDataPath = FileManager.default.temporaryDirectory.appending(path: "blog_test_data")
    
    override func setUp() async throws {
        try FileManager.default.createDirectory(at: testDataPath, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testDataPath)
    }
    
    func createTestPost(slug: String, title: String, date: Date) throws {
        let postDir = testDataPath.appending(path: slug)
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let meta: [String: Any] = [
            "title": title,
            "date": date.ISO8601Format(),
            "tags": ["test", "swift"],
            "categories": ["testing"]
        ]
        let metaData = try JSONSerialization.data(withJSONObject: meta)
        try metaData.write(to: postDir.appending(path: "meta.json"))
        
        try "Test content for \(title)".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
    }
    
    func testLoadValidPost() async throws {
        let date = Date()
        try createTestPost(slug: "test-post", title: "Test Post", date: date)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        XCTAssertEqual(posts.count, 1)
        let post = try XCTUnwrap(posts.first)
        XCTAssertEqual(post.title, "Test Post")
        XCTAssertEqual(post.slug, "test-post")
        XCTAssertEqual(post.content, "Test content for Test Post")
        XCTAssertEqual(post.tags, ["test", "swift"])
        XCTAssertEqual(post.categories, ["testing"])
    }
    
    func testLoadMultiplePosts() async throws {
        let date = Date()
        try createTestPost(slug: "first-post", title: "First Post", date: date)
        try createTestPost(slug: "second-post", title: "Second Post", date: date)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        XCTAssertEqual(posts.count, 2)
        XCTAssertTrue(posts.contains { $0.title == "First Post" })
        XCTAssertTrue(posts.contains { $0.title == "Second Post" })
    }
    
    func testInvalidMetadataFile() async throws {
        let postDir = testDataPath.appending(path: "invalid-post")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        // Write invalid JSON
        try "{ invalid json }".write(to: postDir.appending(path: "meta.json"), atomically: true, encoding: .utf8)
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        do {
            _ = try await loader.loadPosts()
            XCTFail("Expected error loading invalid metadata")
        } catch {
            // Expected error
        }
    }
    
    func testMissingContentFile() async throws {
        let postDir = testDataPath.appending(path: "missing-content")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let meta: [String: Any] = [
            "title": "Test",
            "date": Date().ISO8601Format(),
            "tags": [],
            "categories": []
        ]
        let metaData = try JSONSerialization.data(withJSONObject: meta)
        try metaData.write(to: postDir.appending(path: "meta.json"))
        
        let loader = PostLoader(postsDirectory: testDataPath)
        do {
            _ = try await loader.loadPosts()
            XCTFail("Expected error loading post with missing content")
        } catch {
            // Expected error
        }
    }
    
    func testEmptyDirectory() async throws {
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        XCTAssertTrue(posts.isEmpty)
    }
    
    func testInvalidDateFormat() async throws {
        let postDir = testDataPath.appending(path: "invalid-date")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let meta: [String: Any] = [
            "title": "Test",
            "date": "invalid-date",
            "tags": [],
            "categories": []
        ]
        let metaData = try JSONSerialization.data(withJSONObject: meta)
        try metaData.write(to: postDir.appending(path: "meta.json"))
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        do {
            _ = try await loader.loadPosts()
            XCTFail("Expected error loading post with invalid date")
        } catch {
            // Expected error
        }
    }
    
    func testMissingRequiredFields() async throws {
        let postDir = testDataPath.appending(path: "missing-fields")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let meta: [String: Any] = [
            "date": Date().ISO8601Format()
            // Missing title, tags, and categories
        ]
        let metaData = try JSONSerialization.data(withJSONObject: meta)
        try metaData.write(to: postDir.appending(path: "meta.json"))
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        do {
            _ = try await loader.loadPosts()
            XCTFail("Expected error loading post with missing required fields")
        } catch {
            // Expected error
        }
    }
    
    func testNonDirectoryInPostsFolder() async throws {
        // Create a file instead of a directory in the posts folder
        try "Not a post directory".write(to: testDataPath.appending(path: "not-a-post"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        // The file should be ignored, resulting in no posts
        XCTAssertTrue(posts.isEmpty)
    }
    
    func testConcurrentLoading() async throws {
        // Create many posts to test concurrent loading
        for i in 1...10 {
            try createTestPost(
                slug: "post-\(i)",
                title: "Post \(i)",
                date: Date().addingTimeInterval(Double(i) * -86400)
            )
        }
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        XCTAssertEqual(posts.count, 10)
        
        // Verify all posts were loaded correctly
        let titles = Set(posts.map { $0.title })
        for i in 1...10 {
            XCTAssertTrue(titles.contains("Post \(i)"))
        }
    }
    
    func testPostDateParsing() async throws {
        let postDir = testDataPath.appending(path: "date-formats")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        // Test both date formats
        let meta: [String: Any] = [
            "title": "Date Test",
            "date": "2024-02-10", // Simple date format
            "tags": [],
            "categories": []
        ]
        let metaData = try JSONSerialization.data(withJSONObject: meta)
        try metaData.write(to: postDir.appending(path: "meta.json"))
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        XCTAssertEqual(posts.count, 1)
        let post = try XCTUnwrap(posts.first)
        
        // Verify the date was parsed correctly
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: post.date)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 10)
    }
} 