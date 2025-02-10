import Foundation

public struct Update: Codable, Sendable {
    public let date: Date
    public let description: String
    
    public init(date: Date, description: String) {
        self.date = date
        self.description = description
    }
}

public struct Post: Codable, Sendable {
    public let title: String
    public let date: Date
    public let tags: [String]
    public let categories: [String]
    public let slug: String
    public let content: String
    public let updates: [Update]
    
    public init(
        title: String,
        date: Date,
        tags: [String],
        categories: [String],
        slug: String,
        content: String,
        updates: [Update] = []
    ) {
        self.title = title
        self.date = date
        self.tags = tags
        self.categories = categories
        self.slug = slug
        self.content = content
        self.updates = updates
    }
} 