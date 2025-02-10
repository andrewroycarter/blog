import Testing
import Foundation
@testable import blog

class PostLoaderTests {
    let testDataPath: URL
    
    init() throws {
        testDataPath = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("blog_test_data_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDataPath, withIntermediateDirectories: true)
    }
    
    deinit {
        try? FileManager.default.removeItem(at: testDataPath)
    }
    
    func testLoadValidPost() async throws {
        let date = Date()
        let postDir = testDataPath.appending(path: "test-post")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let metadata = """
        {
            "title": "Test Post",
            "date": "\(ISO8601DateFormatter().string(from: date))",
            "tags": ["test1", "test2"],
            "categories": ["cat1", "cat2"],
            "slug": "test-post"
        }
        """
        try metadata.write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        #expect(posts.count == 1)
        guard let post = posts.first else {
            throw TestError("Expected a post but found none")
        }
        #expect(post.title == "Test Post")
        #expect(post.tags == ["test1", "test2"])
        #expect(post.categories == ["cat1", "cat2"])
        #expect(post.slug == "test-post")
        #expect(post.content == "Test content")
    }
    
    func testLoadMultiplePosts() async throws {
        let date = Date()
        for i in 1...3 {
            let postDir = testDataPath.appending(path: "post-\(i)")
            try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
            
            let metadata = """
            {
                "title": "Post \(i)",
                "date": "\(ISO8601DateFormatter().string(from: date))",
                "tags": ["test"],
                "categories": ["cat"],
                "slug": "post-\(i)"
            }
            """
            try metadata.write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
            try "Content \(i)".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        }
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        #expect(posts.count == 3)
    }
    
    func testInvalidMetadataFile() async throws {
        let postDir = testDataPath.appending(path: "invalid-post")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        try "Invalid JSON".write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        
        do {
            _ = try await loader.loadPosts()
            throw TestError("Expected error loading invalid metadata")
        } catch {
            // Expected error
        }
    }
    
    func testMissingContentFile() async throws {
        let postDir = testDataPath.appending(path: "missing-content")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let metadata = """
        {
            "title": "Test Post",
            "date": "\(ISO8601DateFormatter().string(from: Date()))",
            "tags": ["test"],
            "categories": ["cat"],
            "slug": "test-post"
        }
        """
        try metadata.write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        
        do {
            _ = try await loader.loadPosts()
            throw TestError("Expected error loading post with missing content")
        } catch {
            // Expected error
        }
    }
    
    func testEmptyDirectory() async throws {
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        #expect(posts.isEmpty)
    }
    
    func testInvalidDateFormat() async throws {
        let postDir = testDataPath.appending(path: "invalid-date")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let metadata = """
        {
            "title": "Test Post",
            "date": "invalid-date",
            "tags": ["test"],
            "categories": ["cat"],
            "slug": "test-post"
        }
        """
        try metadata.write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        
        do {
            _ = try await loader.loadPosts()
            throw TestError("Expected error loading post with invalid date")
        } catch {
            // Expected error
        }
    }
    
    func testMissingRequiredFields() async throws {
        let postDir = testDataPath.appending(path: "missing-fields")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let metadata = """
        {
            "title": "Test Post",
            "date": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """
        try metadata.write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        
        do {
            _ = try await loader.loadPosts()
            throw TestError("Expected error loading post with missing required fields")
        } catch {
            // Expected error
        }
    }
    
    func testNonDirectoryInPostsFolder() async throws {
        try "Not a post directory".write(to: testDataPath.appending(path: "not-a-post"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        #expect(posts.isEmpty)
    }
    
    func testConcurrentLoading() async throws {
        for i in 1...10 {
            let postDir = testDataPath.appending(path: "post-\(i)")
            try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
            
            let metadata = """
            {
                "title": "Post \(i)",
                "date": "\(ISO8601DateFormatter().string(from: Date()))",
                "tags": ["test"],
                "categories": ["cat"],
                "slug": "post-\(i)"
            }
            """
            try metadata.write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
            try "Content \(i)".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        }
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        #expect(posts.count == 10)
    }
    
    func testPostDateParsing() async throws {
        let postDir = testDataPath.appending(path: "date-formats")
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let date = Date()
        let metadata = """
        {
            "title": "Test Post",
            "date": "\(ISO8601DateFormatter().string(from: date))",
            "tags": ["test"],
            "categories": ["cat"],
            "slug": "test-post"
        }
        """
        try metadata.write(to: postDir.appending(path: "metadata.json"), atomically: true, encoding: .utf8)
        try "Test content".write(to: postDir.appending(path: "content.md"), atomically: true, encoding: .utf8)
        
        let loader = PostLoader(postsDirectory: testDataPath)
        let posts = try await loader.loadPosts()
        
        #expect(posts.count == 1)
        guard let post = posts.first else {
            throw TestError("Expected a post but found none")
        }
        
        // Check that the date was parsed correctly
        let formatter = ISO8601DateFormatter()
        let expectedDateString = formatter.string(from: date)
        let actualDateString = formatter.string(from: post.date)
        #expect(actualDateString == expectedDateString)
    }
}

struct TestError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
} 