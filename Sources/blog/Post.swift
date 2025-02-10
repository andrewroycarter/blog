import Foundation

public struct Post: Codable, Sendable {
    public let title: String
    public let date: Date
    public let tags: [String]
    public let categories: [String]
    public let slug: String
    public let content: String
    
    public init(
        title: String,
        date: Date,
        tags: [String],
        categories: [String],
        slug: String,
        content: String
    ) {
        self.title = title
        self.date = date
        self.tags = tags
        self.categories = categories
        self.slug = slug
        self.content = content
    }
} 