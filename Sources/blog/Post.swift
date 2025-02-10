import Foundation

public struct Update: Codable, Sendable {
    public let date: Date
    public let description: String
    
    public init(date: Date, description: String) {
        self.date = date
        self.description = description
    }
    
    private enum CodingKeys: String, CodingKey {
        case date, description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(String.self, forKey: .date)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if dateString.contains("T") {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date format")
        }
        
        self.date = date
        self.description = try container.decode(String.self, forKey: .description)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: date), forKey: .date)
        try container.encode(description, forKey: .description)
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