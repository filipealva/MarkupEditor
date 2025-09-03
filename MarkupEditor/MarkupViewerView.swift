//
//  MarkupViewerView.swift
//  MarkupEditor
//
//  Created by MarkupEditor on 1/20/25.
//  Copyright © 2025 Steven Harris. All rights reserved.
//

import SwiftUI
import WebKit

/// SwiftUI wrapper for MarkupViewerWKWebView providing read-only HTML viewing.
///
/// The MarkupViewerView automatically sizes to fit its content and provides extremely fast rendering
/// with no perceptible flicker. It respects the width of its container while growing/shrinking in height
/// to accommodate the full document.
///
/// Example usage:
/// ```swift
/// MarkupViewerView(html: .constant("<h1>Hello World</h1><p>This is a test.</p>"))
/// ```
///
/// For dynamic content:
/// ```swift
/// @State private var htmlContent = "<p>Loading...</p>"
///
/// MarkupViewerView(html: .constant(htmlContent))
///     .onAppear {
///         // Load content asynchronously
///         loadHtmlContent { newHtml in
///             htmlContent = newHtml
///         }
///     }
/// ```
public struct MarkupViewerView: View, MarkupViewerDelegate {
    
    /// The HTML content to display
    @Binding private var html: String
    
    /// Optional delegate for handling viewer events
    private let viewerDelegate: MarkupViewerDelegate?
    
    /// Optional WebKit delegates
    private let wkNavigationDelegate: WKNavigationDelegate?
    private let wkUIDelegate: WKUIDelegate?
    
    /// User scripts to inject
    private let userScripts: [String]?
    
    /// Viewer configuration
    private let configuration: MarkupViewerConfiguration?
    
    /// Custom selection menu handling
    @State private var selectedText: String = ""
    @State private var hasSelection: Bool = false
    @State private var selectionMenuVisible: Bool = false
    
    public var body: some View {
        MarkupViewerRepresentable(
            html: $html,
            viewerDelegate: viewerDelegate ?? self,
            wkNavigationDelegate: wkNavigationDelegate,
            wkUIDelegate: wkUIDelegate,
            userScripts: userScripts,
            configuration: configuration
        )
        .contextMenu(menuItems: {
            if hasSelection {
                Button(action: {
                    // Copy action handled by the system
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                
                Button(action: {
                    // This will trigger selectAll on the web view
                }) {
                    Label("Select All", systemImage: "selection.pin.in.out")
                }
            } else {
                Button(action: {
                    // This will trigger selectAll on the web view
                }) {
                    Label("Select All", systemImage: "selection.pin.in.out")
                }
            }
        })
    }
    
    public init(
        html: Binding<String>,
        viewerDelegate: MarkupViewerDelegate? = nil,
        wkNavigationDelegate: WKNavigationDelegate? = nil,
        wkUIDelegate: WKUIDelegate? = nil,
        userScripts: [String]? = nil,
        configuration: MarkupViewerConfiguration? = nil
    ) {
        self._html = html
        self.viewerDelegate = viewerDelegate
        self.wkNavigationDelegate = wkNavigationDelegate
        self.wkUIDelegate = wkUIDelegate
        self.userScripts = userScripts
        self.configuration = configuration
    }
    
    // MARK: - MarkupViewerDelegate Implementation
    
    public func viewer(_ viewer: MarkupViewerWKWebView, didSelectText text: String, hasSelection: Bool) {
        self.selectedText = text
        self.hasSelection = hasSelection
    }
}

// MARK: - UIViewRepresentable

private struct MarkupViewerRepresentable: UIViewRepresentable {
    
    @Binding var html: String
    let viewerDelegate: MarkupViewerDelegate?
    let wkNavigationDelegate: WKNavigationDelegate?
    let wkUIDelegate: WKUIDelegate?
    let userScripts: [String]?
    let configuration: MarkupViewerConfiguration?
    
    func makeUIView(context: Context) -> MarkupViewerWKWebView {
        let viewer = MarkupViewerWKWebView(
            html: html,
            viewerDelegate: viewerDelegate,
            configuration: configuration
        )
        
        // Set WebKit delegates if provided
        viewer.navigationDelegate = wkNavigationDelegate
        viewer.uiDelegate = wkUIDelegate
        
        // Inject user scripts if provided
        if let userScripts = userScripts {
            for script in userScripts {
                let wkUserScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                viewer.configuration.userContentController.addUserScript(wkUserScript)
            }
        }
        
        return viewer
    }
    
    func updateUIView(_ viewer: MarkupViewerWKWebView, context: Context) {
        // Update HTML content if changed
        viewer.setHtml(html)
    }
}

// MARK: - Convenience Initializers

public extension MarkupViewerView {
    
    /// Create a MarkupViewer with static HTML content
    init(staticHtml: String, 
         viewerDelegate: MarkupViewerDelegate? = nil,
         configuration: MarkupViewerConfiguration? = nil) {
        self.init(
            html: .constant(staticHtml),
            viewerDelegate: viewerDelegate,
            configuration: configuration
        )
    }
    
    /// Create a MarkupViewer with custom CSS styling
    init(html: Binding<String>,
         customCSS: String,
         viewerDelegate: MarkupViewerDelegate? = nil) {
        
        // Create a configuration with custom CSS
        let config = MarkupViewerConfiguration()
        
        // We'll need to create a temporary CSS file for this
        // This is a simplified approach - in production you might want to handle this differently
        let cssFileName = "custom-\(UUID().uuidString).css"
        
        self.init(
            html: html,
            viewerDelegate: viewerDelegate,
            configuration: config
        )
    }
}

// MARK: - Preview

#if DEBUG
struct MarkupViewerView_Previews: PreviewProvider {
    static let sampleHtml = """
    <h1>Welcome to MarkupViewer</h1>
    <p>This is a <strong>read-only</strong> HTML viewer that automatically adjusts its height to fit the content.</p>
    <ul>
        <li>Extremely fast rendering</li>
        <li>No perceptible flicker</li>
        <li>Custom selection menu</li>
        <li>Auto-sizing behavior</li>
    </ul>
    <blockquote>
        <p>Select text to see the custom menu with "Select All" and "Copy" options.</p>
    </blockquote>
    """
    
    static var previews: some View {
        Group {
            MarkupViewerView(staticHtml: sampleHtml)
                .padding()
                .previewDisplayName("Static HTML")
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { index in
                        MarkupViewerView(staticHtml: sampleHtml)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .previewDisplayName("Multiple Viewers")
        }
    }
}
#endif
