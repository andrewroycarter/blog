import XCTest
@testable import blog

final class PostTests: XCTestCase {
    func testPostInitialization() throws {
        let date = Date()
        let post = Post(
            title: "Test Post",
            date: date,
            tags: ["swift", "blogging"],
            categories: ["programming"],
            slug: "test-post",
            content: "This is a test post"
        )
        
        XCTAssertEqual(post.title, "Test Post")
        XCTAssertEqual(post.date, date)
        XCTAssertEqual(post.tags, ["swift", "blogging"])
        XCTAssertEqual(post.categories, ["programming"])
        XCTAssertEqual(post.slug, "test-post")
        XCTAssertEqual(post.content, "This is a test post")
    }
    
    func testPostCoding() throws {
        let date = Date()
        let originalPost = Post(
            title: "Test Post",
            date: date,
            tags: ["swift", "blogging"],
            categories: ["programming"],
            slug: "test-post",
            content: "This is a test post"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(originalPost)
        let decodedPost = try decoder.decode(Post.self, from: data)
        
        XCTAssertEqual(decodedPost.title, originalPost.title)
        XCTAssertEqual(decodedPost.date, originalPost.date)
        XCTAssertEqual(decodedPost.tags, originalPost.tags)
        XCTAssertEqual(decodedPost.categories, originalPost.categories)
        XCTAssertEqual(decodedPost.slug, originalPost.slug)
        XCTAssertEqual(decodedPost.content, originalPost.content)
    }
} 