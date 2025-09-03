# MarkupViewer Integration Guide

A quick guide for integrating MarkupViewer into your existing project for fast, read-only HTML rendering.

## 🚀 Quick Start

### 1. Add the Package

**Swift Package Manager (Recommended):**
```
File → Add Package Dependencies...
https://github.com/stevengharris/MarkupEditor
```

**Or add to your `Package.swift`:**
```swift
dependencies: [
    .package(url: "https://github.com/stevengharris/MarkupEditor", from: "0.8.0")
]
```

### 2. Import and Use

```swift
import SwiftUI
import MarkupEditor

struct MyContentView: View {
    let htmlContent = """
    <h1>Welcome</h1>
    <p>This renders <strong>instantly</strong> with perfect sizing.</p>
    """
    
    var body: some View {
        ScrollView {
            MarkupViewerView(staticHtml: htmlContent)
                .padding()
        }
    }
}
```

That's it! Your HTML will render instantly with automatic height adjustment.

## 📋 Common Integration Scenarios

### Scenario 1: Static Content Display

**Use Case:** FAQ pages, help documentation, marketing content

```swift
struct FAQView: View {
    let faqHtml = loadFAQFromBundle() // Your HTML loading logic
    
    var body: some View {
        NavigationView {
            ScrollView {
                MarkupViewerView(staticHtml: faqHtml)
                    .padding()
            }
            .navigationTitle("FAQ")
        }
    }
}
```

### Scenario 2: Dynamic Content from API

**Use Case:** Blog posts, articles, user-generated content

```swift
struct ArticleView: View {
    @State private var articleHtml = "<p>Loading...</p>"
    let articleId: String
    
    var body: some View {
        ScrollView {
            MarkupViewerView(html: .constant(articleHtml))
                .padding()
        }
        .task {
            articleHtml = await fetchArticle(id: articleId)
        }
    }
    
    private func fetchArticle(id: String) async -> String {
        // Your API call here
        // Returns HTML string
    }
}
```

### Scenario 3: List of HTML Cards

**Use Case:** News feed, product listings, comment threads

```swift
struct NewsListView: View {
    @State private var articles: [Article] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(articles) { article in
                    MarkupViewerView(staticHtml: article.htmlContent)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                }
            }
        }
    }
}
```

### Scenario 4: Custom Styling

**Use Case:** Brand-specific styling, dark mode support

```swift
struct StyledContentView: View {
    let htmlContent: String
    
    var body: some View {
        let config = MarkupViewerConfiguration(
            userCssFile: "brand-styles.css"
        )
        
        MarkupViewerView(
            html: .constant(htmlContent),
            configuration: config
        )
    }
}
```

**Create `brand-styles.css` in your app bundle:**
```css
/* Custom brand colors and fonts */
h1, h2, h3 { 
    color: #2196F3; 
    font-family: -apple-system-headline;
}

p { 
    line-height: 1.6; 
    color: #333;
}

@media (prefers-color-scheme: dark) {
    p { color: #fff; }
    h1, h2, h3 { color: #64B5F6; }
}
```

## 🔄 Migrating from Other Solutions

### From UIWebView/WKWebView

**Before (Manual WKWebView):**
```swift
// Lots of boilerplate code
let webView = WKWebView()
webView.loadHTMLString(html, baseURL: nil)
// Manual height calculations, scrolling issues, etc.
```

**After (MarkupViewer):**
```swift
// One line of code
MarkupViewerView(staticHtml: html)
// Automatic height, no scrolling, instant rendering
```

### From UITextView with AttributedString

**Before:**
```swift
// Complex HTML → AttributedString conversion
let textView = UITextView()
textView.attributedText = html.attributedString()
// Limited HTML support, performance issues
```

**After:**
```swift
// Full HTML support, better performance
MarkupViewerView(staticHtml: html)
```

### From Third-Party Web Components

Most web-based HTML viewers can be replaced with:
```swift
MarkupViewerView(html: .constant(yourHtml))
```

## ⚡ Performance Optimization Tips

### 1. Use Static HTML When Possible
```swift
// ✅ Best performance - content doesn't change
MarkupViewerView(staticHtml: html)

// ⚠️ Use only when content changes
MarkupViewerView(html: .constant(html))
```

### 2. Batch Updates for Lists
```swift
struct OptimizedListView: View {
    @State private var articles: [Article] = []
    
    var body: some View {
        ScrollView {
            // Use LazyVStack for large lists
            LazyVStack(spacing: 12) {
                ForEach(articles) { article in
                    MarkupViewerView(staticHtml: article.content)
                        .id(article.id) // Helps with reuse
                }
            }
        }
    }
}
```

### 3. Pre-process Content
```swift
// ✅ Do expensive operations once
let processedHtml = preprocessHtml(rawHtml)
MarkupViewerView(staticHtml: processedHtml)

func preprocessHtml(_ html: String) -> String {
    // Clean, optimize, or transform HTML once
    return html.replacingOccurrences(of: "old", with: "new")
}
```

## 🎨 Advanced Customization

### Custom Selection Handling

```swift
struct CustomViewerView: View, MarkupViewerDelegate {
    @State private var selectedText = ""
    
    var body: some View {
        MarkupViewerView(
            html: .constant(htmlContent),
            viewerDelegate: self
        )
        .alert("Selected", isPresented: .constant(!selectedText.isEmpty)) {
            Button("Copy") { 
                UIPasteboard.general.string = selectedText 
            }
            Button("Share") { 
                shareText(selectedText) 
            }
        }
    }
    
    func viewer(_ viewer: MarkupViewerWKWebView, didSelectText text: String, hasSelection: Bool) {
        selectedText = hasSelection ? text : ""
    }
}
```

### Height Change Handling

```swift
struct ResponsiveViewer: View, MarkupViewerDelegate {
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        VStack {
            Text("Content Height: \(contentHeight, specifier: "%.0f")")
            
            MarkupViewerView(
                html: .constant(htmlContent),
                viewerDelegate: self
            )
        }
    }
    
    func viewer(_ viewer: MarkupViewerWKWebView, heightDidChange height: CGFloat) {
        contentHeight = height
    }
}
```

## 🔧 Troubleshooting

### Common Issues

**Issue: Content not rendering**
```swift
// ✅ Ensure HTML is valid
let validHtml = """
<html>
<body>
    <h1>Title</h1>
    <p>Content</p>
</body>
</html>
"""

// ❌ Don't use incomplete HTML fragments for complex content
let incompleteHtml = "<h1>Title" // Missing closing tag
```

**Issue: Styling not applied**
```swift
// ✅ Include CSS file in your app bundle
guard let cssPath = Bundle.main.path(forResource: "styles", ofType: "css") else {
    return // Handle missing file
}

let config = MarkupViewerConfiguration(userCssFile: "styles.css")
```

**Issue: Slow rendering in lists**
```swift
// ✅ Use LazyVStack and proper IDs
LazyVStack {
    ForEach(items, id: \.id) { item in
        MarkupViewerView(staticHtml: item.html)
            .id(item.id)
    }
}

// ❌ Don't use regular VStack for large lists
VStack {
    ForEach(items) { item in
        MarkupViewerView(staticHtml: item.html)
    }
}
```

## 📊 Performance Comparison

| Feature | MarkupViewer | WKWebView | UITextView |
|---------|-------------|-----------|------------|
| Setup Code | 1 line | 20+ lines | 10+ lines |
| HTML Support | Full | Full | Limited |
| Auto-sizing | ✅ | Manual | Manual |
| Performance | Fastest | Fast | Slow |
| Memory Usage | Optimized | Standard | High |

## 🎯 Best Practices

### DO ✅
- Use `staticHtml` for content that doesn't change
- Implement `MarkupViewerDelegate` for custom interactions
- Pre-process HTML content when possible
- Use `LazyVStack` for large lists
- Include custom CSS files for branding

### DON'T ❌
- Use `MarkupViewer` for editable content (use `MarkupEditor` instead)
- Load extremely large HTML documents without pagination
- Ignore the delegate callbacks for height changes
- Forget to handle loading states for async content

## 🚀 Ready to Ship!

With these patterns, you can integrate MarkupViewer into any iOS app for lightning-fast HTML rendering. The viewer handles all the complexity of WebKit integration, sizing, and performance optimization automatically.

Need more help? Check out the demo apps in the MarkupEditor repository for complete working examples!
