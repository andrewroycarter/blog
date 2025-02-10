import Testing
import Foundation
@testable import blog

struct PostTests {
    func testPostInitialization() throws {
        let date = Date()
        let post = Post(
            title: "Test Post",
            date: date,
            tags: ["test1", "test2"],
            categories: ["cat1", "cat2"],
            slug: "test-post",
            content: "Test content"
        )
        
        #expect(post.title == "Test Post")
        #expect(post.date == date)
        #expect(post.tags == ["test1", "test2"])
        #expect(post.categories == ["cat1", "cat2"])
        #expect(post.slug == "test-post")
        #expect(post.content == "Test content")
    }
    
    func testPostCoding() throws {
        let date = Date()
        let originalPost = Post(
            title: "Test Post",
            date: date,
            tags: ["test1", "test2"],
            categories: ["cat1", "cat2"],
            slug: "test-post",
            content: "Test content"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(originalPost)
        let decodedPost = try decoder.decode(Post.self, from: data)
        
        #expect(decodedPost.title == originalPost.title)
        #expect(decodedPost.date == originalPost.date)
        #expect(decodedPost.tags == originalPost.tags)
        #expect(decodedPost.categories == originalPost.categories)
        #expect(decodedPost.slug == originalPost.slug)
        #expect(decodedPost.content == originalPost.content)
    }
} 