# Markdown Test

This post tests all Markdown features to ensure our styling works correctly.

## Text Formatting

Here's some **bold text** and *italic text*. You can also use ***bold and italic*** together.

Here's some `inline code` in a paragraph.

## Links and Lists

Here's [a link](https://example.com) in a paragraph.

Unordered list:
- First item
- Second item
  - Nested item
  - Another nested item
- Third item

Ordered list:
1. First item
2. Second item
   1. Nested item
   2. Another nested item
3. Third item

## Code Blocks

Here's a code block with syntax highlighting:

```swift
struct Post {
    let title: String
    let content: String
    
    func render() -> String {
        // Some code here
        return "Rendered content"
    }
}
```

And one without language specification:

```
Plain text code block
Multiple lines
No syntax highlighting
```

## Blockquotes

Here's a blockquote:

> This is a blockquote
> It can span multiple lines
>
> And have multiple paragraphs

## Tables

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

## Horizontal Rules

Here's some text above a horizontal rule.

---

And some text below it.

## Task Lists

- [x] Completed task
- [ ] Incomplete task
- [x] Another completed task

## Images

![Example image](https://example.com/image.jpg)

## Mixed Content

> Here's a blockquote with **bold text** and a `code snippet`
> - And a list item
> - With another item

1. First item with `inline code`
2. Second item with **bold text**
   > And a nested blockquote
3. Third item with *italic text* 