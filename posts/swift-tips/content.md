# Essential Swift Tips and Tricks

Here are some essential Swift tips that will make your code more elegant and efficient.

## String Interpolation

Swift's string interpolation is powerful and extensible:

```swift
let name = "Swift"
print("Hello, \(name)!")

// Custom string interpolation
extension String.StringInterpolation {
    mutating func appendInterpolation(number: Int, style: NumberFormatter.Style) {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        appendLiteral(formatter.string(from: number as NSNumber)!)
    }
}
print("The cost is \(number: 1000, style: .currency)")
```

## Type Inference

Let Swift's type inference work for you:

```swift
// Instead of
let array: [String] = ["a", "b", "c"]

// Write
let array = ["a", "b", "c"]
```

## Trailing Closure Syntax

Use trailing closure syntax for cleaner code:

```swift
// Instead of
buttons.forEach({ button in
    button.isEnabled = false
})

// Write
buttons.forEach { button in
    button.isEnabled = false
}
```

Stay tuned for more Swift tips! 