//
//  MarkupViewerWKWebView.swift
//  MarkupEditor
//
//  Created by MarkupEditor on 1/20/25.
//  Copyright © 2025 Steven Harris. All rights reserved.
//

import SwiftUI
import WebKit
import Combine
import OSLog
import UniformTypeIdentifiers

/// A specialized WKWebView for read-only HTML viewing with extremely fast rendering.
///
/// The MarkupViewerWKWebView is optimized for displaying styled HTML content without editing capabilities.
/// It automatically adjusts its height to fit the content and provides a custom selection menu
/// with "Select All" and "Copy" options only.
///
/// Key features:
/// - Instantaneous rendering with no perceptible flicker
/// - Automatic height adjustment to fit content
/// - Respects container width, disables scrolling
/// - Custom selection menu (Select All, Copy only)
/// - Swift-JavaScript bridge for height updates and selection handling
/// - Singleton warm-up strategy for optimal performance
public class MarkupViewerWKWebView: WKWebView, ObservableObject {
    
    private static var warmUpPool: WKProcessPool?
    private static var warmUpDataStore: WKWebsiteDataStore?
    
    /// The HTML content currently loaded
    private var html: String?
    
    /// Whether the viewer is ready for content
    public private(set) var isReady: Bool = false
    
    /// Delegate for handling viewer events
    private var viewerDelegate: MarkupViewerDelegate?
    
    /// Height constraint that will be updated as content changes
    private var heightConstraint: NSLayoutConstraint?
    
    /// Current document height
    private var documentHeight: CGFloat = 0
    
    /// Base URL for loading resources
    public var baseUrl: URL { cacheUrl() }
    
    /// Unique identifier for this viewer instance
    public let id: String = UUID().uuidString
    
    /// Configuration for the viewer
    public var viewerConfiguration: MarkupViewerConfiguration?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        initForViewing()
    }
    
    public required init?(coder: NSCoder) {
        super.init(frame: CGRect.zero, configuration: Self.optimizedConfiguration())
        initForViewing()
    }
    
    public init(html: String? = nil, 
                viewerDelegate: MarkupViewerDelegate? = nil, 
                configuration: MarkupViewerConfiguration? = nil) {
        super.init(frame: CGRect.zero, configuration: Self.optimizedConfiguration())
        self.html = html
        self.viewerDelegate = viewerDelegate
        self.viewerConfiguration = configuration
        initForViewing()
    }
    
    /// Create an optimized WKWebViewConfiguration for fast viewing
    private static func optimizedConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        
        // Use shared process pool for faster initialization
        if warmUpPool == nil {
            warmUpPool = WKProcessPool()
        }
        config.processPool = warmUpPool!
        
        // Use shared data store
        if warmUpDataStore == nil {
            warmUpDataStore = WKWebsiteDataStore.default()
        }
        config.websiteDataStore = warmUpDataStore!
        
        // Optimize for viewing
        config.suppressesIncrementalRendering = false // Allow fast incremental rendering
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        
        // Disable selection and editing features we don't need
        config.selectionGranularity = .character
        
        return config
    }
    
    /// Initialize the viewer for displaying HTML content
    private func initForViewing() {
        isOpaque = false
        backgroundColor = .systemBackground
        scrollView.isScrollEnabled = false // Disable scrolling - we'll size to content
        
        initRootFiles()
        viewerDelegate?.viewerSetup(self)
        
        // Load the viewer HTML template
        let viewerHtml = cacheUrl().appendingPathComponent("markupViewer.html")
        loadFileURL(viewerHtml, allowingReadAccessTo: viewerHtml.deletingLastPathComponent())
        
        // Set up message handling
        configuration.userContentController.add(ViewerMessageHandler(viewer: self), name: "markup")
        
        setupForAutoSizing()
    }
    
    /// Set up auto-sizing behavior
    private func setupForAutoSizing() {
        // Disable scrolling and set up proper sizing
        scrollView.isScrollEnabled = false
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        // Set up height constraint
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
    }
    
    // MARK: - Resource Management
    
    /// Return the bundle that contains the viewer resources
    func bundle() -> Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: MarkupViewerWKWebView.self)
        #endif
    }
    
    /// Get the URL for a resource, checking main bundle first
    func url(forResource name: String, withExtension ext: String?) -> URL? {
        let url = bundle().url(forResource: name, withExtension: ext)
        return Bundle.main.url(forResource: name, withExtension: ext) ?? url
    }
    
    /// Initialize viewer resource files
    private func initRootFiles() {
        guard
            let viewerHtml = url(forResource: "markupViewer", withExtension: "html"),
            let viewerJs = url(forResource: "markupViewer", withExtension: "js"),
            let markupCss = url(forResource: "markup", withExtension: "css"),
            let mirrorCss = url(forResource: "mirror", withExtension: "css") else {
            assertionFailure("Could not find markupViewer.html, js, css files.")
            return
        }
        
        var srcUrls = [viewerHtml, viewerJs, markupCss, mirrorCss]
        
        // Add user CSS if specified
        if let userCssFile = viewerConfiguration?.userCssFile,
           let userCss = url(forResource: userCssFile, withExtension: nil) {
            srcUrls.append(userCss)
        }
        
        // Add user script if specified
        if let userScriptFile = viewerConfiguration?.userScriptFile,
           let userScript = url(forResource: userScriptFile, withExtension: nil) {
            srcUrls.append(userScript)
        }
        
        // Add additional resources
        if let userResourceFiles = viewerConfiguration?.userResourceFiles {
            for file in userResourceFiles {
                if let userResource = url(forResource: file, withExtension: nil) {
                    srcUrls.append(userResource)
                }
            }
        }
        
        let fileManager = FileManager.default
        let cacheUrl = cacheUrl()
        
        do {
            try fileManager.createDirectory(at: cacheUrl, withIntermediateDirectories: true)
            
            for srcUrl in srcUrls {
                let dstUrl = cacheUrl.appendingPathComponent(srcUrl.lastPathComponent)
                try? fileManager.removeItem(at: dstUrl)
                try fileManager.copyItem(at: srcUrl, to: dstUrl)
            }
        } catch {
            assertionFailure("Failed to set up viewer cache directory: \(error.localizedDescription)")
        }
    }
    
    /// Get cache URL for this viewer instance
    private func cacheUrl() -> URL {
        let cacheUrls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return cacheUrls[0].appendingPathComponent("MarkupViewer-\(id)")
    }
    
    // MARK: - Content Management
    
    /// Set the HTML content to display
    public func setHtml(_ html: String, completion: (() -> Void)? = nil) {
        guard isReady else {
            self.html = html
            completion?()
            return
        }
        
        self.html = html
        evaluateJavaScript("MV.setHTML('\(html.escaped)', false)") { result, error in
            if let error {
                Logger.webview.error("Error setting HTML: \(error.localizedDescription)")
            }
            completion?()
        }
    }
    
    /// Get the current document height
    public func getHeight(completion: @escaping (CGFloat) -> Void) {
        evaluateJavaScript("MV.getHeight()") { result, error in
            let height = result as? CGFloat ?? 0
            completion(height)
        }
    }
    
    /// Update the view height based on content
    private func updateHeight(to newHeight: CGFloat) {
        guard newHeight != documentHeight else { return }
        
        documentHeight = newHeight
        heightConstraint?.constant = newHeight
        
        // Notify delegate
        viewerDelegate?.viewer(self, heightDidChange: newHeight)
    }
    
    // MARK: - Selection and Menu Handling
    
    /// Select all text in the document
    public func selectAll() {
        evaluateJavaScript("MV.selectAll()") { result, error in
            if let error {
                Logger.webview.error("Error selecting all: \(error.localizedDescription)")
            }
        }
    }
    
    /// Get the currently selected text
    public func getSelectionText(completion: @escaping (String) -> Void) {
        evaluateJavaScript("MV.getSelectionText()") { result, error in
            completion(result as? String ?? "")
        }
    }
    
    /// Copy the current selection (handled by the system)
    @objc public override func copy(_ sender: Any?) {
        // Let the system handle copying - the JavaScript has already prepared the selection
        super.copy(sender)
    }
    
    /// Override to provide custom menu actions
    @objc public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(UIResponderStandardEditActions.selectAll(_:)):
            return true
        case #selector(UIResponderStandardEditActions.copy(_:)):
            return true
        default:
            return false
        }
    }
    
    // MARK: - Message Handling
    
    /// Handle messages from JavaScript
    fileprivate func handleMessage(_ message: [String: Any]) {
        guard let messageType = message["messageType"] as? String else { return }
        
        switch messageType {
        case "heightChanged":
            if let height = message["height"] as? CGFloat {
                DispatchQueue.main.async {
                    self.updateHeight(to: height)
                }
            }
            
        case "textSelected":
            if let hasSelection = message["hasSelection"] as? Bool,
               let selectedText = message["selectedText"] as? String {
                viewerDelegate?.viewer(self, didSelectText: selectedText, hasSelection: hasSelection)
            }
            
        case "selectionCleared":
            viewerDelegate?.viewer(self, didSelectText: "", hasSelection: false)
            
        case "htmlLoaded":
            if !isReady {
                isReady = true
                viewerDelegate?.viewerDidLoad(self)
            }
            
        case "userFilesLoaded":
            // Load initial HTML if we have it
            if let html = html {
                setHtml(html)
            }
            
        case "error":
            if let errorMessage = message["error"] as? String {
                Logger.webview.error("Viewer error: \(errorMessage)")
            }
            
        default:
            break
        }
    }
    
    // MARK: - Cleanup
    
    /// Clean up resources
    public func teardown() {
        try? FileManager.default.removeItem(at: cacheUrl())
    }
}

// MARK: - Message Handler

private class ViewerMessageHandler: NSObject, WKScriptMessageHandler {
    weak var viewer: MarkupViewerWKWebView?
    
    init(viewer: MarkupViewerWKWebView) {
        self.viewer = viewer
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? String,
              let data = messageBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        viewer?.handleMessage(json)
    }
}

// MARK: - MarkupViewerDelegate Protocol

/// Protocol for handling MarkupViewer events
public protocol MarkupViewerDelegate {
    /// Called when the viewer is set up and ready for configuration
    func viewerSetup(_ viewer: MarkupViewerWKWebView)
    
    /// Called when the viewer finishes loading and is ready for content
    func viewerDidLoad(_ viewer: MarkupViewerWKWebView)
    
    /// Called when the content height changes
    func viewer(_ viewer: MarkupViewerWKWebView, heightDidChange height: CGFloat)
    
    /// Called when text selection changes
    func viewer(_ viewer: MarkupViewerWKWebView, didSelectText text: String, hasSelection: Bool)
}

// MARK: - Default implementations for protocol

public extension MarkupViewerDelegate {
    func viewerSetup(_ viewer: MarkupViewerWKWebView) {}
    func viewerDidLoad(_ viewer: MarkupViewerWKWebView) {}
    func viewer(_ viewer: MarkupViewerWKWebView, heightDidChange height: CGFloat) {}
    func viewer(_ viewer: MarkupViewerWKWebView, didSelectText text: String, hasSelection: Bool) {}
}

// MARK: - Configuration

/// Configuration for MarkupViewer
public class MarkupViewerConfiguration {
    /// User-provided CSS file to load
    public var userCssFile: String?
    
    /// User-provided JavaScript file to load
    public var userScriptFile: String?
    
    /// Additional resource files to copy to the cache directory
    public var userResourceFiles: [String]?
    
    public init(userCssFile: String? = nil, userScriptFile: String? = nil, userResourceFiles: [String]? = nil) {
        self.userCssFile = userCssFile
        self.userScriptFile = userScriptFile
        self.userResourceFiles = userResourceFiles
    }
}
