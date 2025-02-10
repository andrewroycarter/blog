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

### Performance Optimizations

To ensure fast site generation, we've implemented several optimizations:

1. **Parallel Page Generation**: All pages (posts, tags, categories) are generated concurrently
2. **Efficient File Handling**: Using atomic writes for file operations
3. **Smart Caching**: Reusing formatted dates and parsed markdown
4. **Minimal Dependencies**: No heavy external libraries

### Accessibility and Dark Mode

The blog is designed to be accessible to all users:

- **Semantic HTML**: Using proper heading hierarchy and ARIA roles
- **Dark Mode Support**: Automatically adapts to system preferences
- **Responsive Design**: Works great on all screen sizes
- **High Contrast**: Ensuring readable text in both light and dark modes
- **Keyboard Navigation**: Full keyboard support for navigation

## Future Plans

- Add RSS feed support
- Implement markdown extensions
- Add syntax highlighting
- Create GitHub Actions workflow

Stay tuned for more updates about this project! 