# Building a Static Blog Engine in Swift

I recently built this blog engine in Swift! Here's how it works and why I made certain technical decisions.

## Design Goals

1. **Simple**: No JavaScript, no external dependencies
2. **Fast**: Concurrent generation of pages
3. **Type-safe**: Leverage Swift's type system
4. **Cross-platform**: Works on macOS and Linux

## Key Features

### Content Structure

Posts are organized in directories:
```
posts/
  my-post/
    content.md
    meta.json
```

### Metadata

Each post has a JSON metadata file:
```json
{
    "title": "My Post",
    "date": "2024-02-10",
    "tags": ["swift"],
    "categories": ["development"]
}
```

### Concurrent Generation

The engine generates all pages concurrently using Swift's structured concurrency:

```swift
try await withThrowingTaskGroup(of: Void.self) { group in
    for post in posts {
        group.addTask {
            try await generatePost(post)
        }
    }
}
```

## Future Plans

- Add RSS feed support
- Implement markdown extensions
- Add syntax highlighting
- Create GitHub Actions workflow

Stay tuned for more updates about this project! 