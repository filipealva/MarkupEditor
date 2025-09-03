//
//  MarkupViewerDebug.swift
//  Debug helper to check resource loading
//

import SwiftUI
import WebKit
import MarkupEditor

class DebugMarkupViewerWKWebView: MarkupViewerWKWebView {
    
    override init(html: String? = nil, viewerDelegate: MarkupViewerDelegate? = nil, configuration: MarkupViewerConfiguration? = nil) {
        print("🔍 DebugMarkupViewerWKWebView: Initializing with html: \(html?.prefix(50) ?? "nil")")
        super.init(html: html, viewerDelegate: viewerDelegate, configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        print("🔍 DebugMarkupViewerWKWebView: init with coder")
        super.init(coder: coder)
    }
    
    override func initRootFiles() {
        print("🔍 DebugMarkupViewerWKWebView: initRootFiles called")
        
        // Check each resource file individually
        let resources = [
            ("markupViewer", "html"),
            ("markupViewer", "js"), 
            ("markup", "css"),
            ("mirror", "css")
        ]
        
        for (name, ext) in resources {
            if let url = url(forResource: name, withExtension: ext) {
                print("✅ Found resource: \(name).\(ext) at \(url.path)")
                
                // Check if file actually exists and has content
                do {
                    let content = try String(contentsOf: url)
                    print("   Content length: \(content.count) chars")
                    if content.count < 100 {
                        print("   Content preview: \(content)")
                    } else {
                        print("   Content preview: \(content.prefix(100))...")
                    }
                } catch {
                    print("❌ Error reading \(name).\(ext): \(error)")
                }
            } else {
                print("❌ Missing resource: \(name).\(ext)")
            }
        }
        
        super.initRootFiles()
        
        // Check cache directory after copying
        let cacheUrl = cacheUrl()
        print("🔍 Cache URL: \(cacheUrl.path)")
        
        do {
            let cacheContents = try FileManager.default.contentsOfDirectory(at: cacheUrl, includingPropertiesForKeys: nil)
            print("📁 Cache contents: \(cacheContents.map { $0.lastPathComponent })")
        } catch {
            print("❌ Error reading cache directory: \(error)")
        }
    }
    
    override func loadFileURL(_ URL: URL, allowingReadAccessTo readAccessURL: URL) {
        print("🔍 DebugMarkupViewerWKWebView: Loading file URL: \(URL.path)")
        print("🔍 Read access URL: \(readAccessURL.path)")
        
        // Check if the file exists before loading
        if FileManager.default.fileExists(atPath: URL.path) {
            print("✅ File exists, attempting to load...")
            super.loadFileURL(URL, allowingReadAccessTo: readAccessURL)
        } else {
            print("❌ File does not exist at path: \(URL.path)")
        }
    }
}

struct DebugMarkupViewerView: View, MarkupViewerDelegate {
    @State private var debugLogs: [String] = []
    @State private var viewerHeight: CGFloat = 0
    
    let testHtml = """
    <h1>Debug Test</h1>
    <p>If you see this, the viewer is working!</p>
    """
    
    var body: some View {
        VStack(spacing: 16) {
            // Debug info
            VStack(alignment: .leading, spacing: 8) {
                Text("Debug Info")
                    .font(.headline)
                
                Text("Height: \(viewerHeight, specifier: "%.0f")px")
                    .font(.caption)
                
                if !debugLogs.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(debugLogs.enumerated()), id: \.offset) { index, log in
                                Text("\(index + 1). \(log)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.gray.opacity(0.1))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            
            // The viewer with visible bounds
            DebugMarkupViewerRepresentable(
                html: .constant(testHtml),
                viewerDelegate: self
            )
            .background(Color.red.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 2)
            )
            
            Spacer()
        }
        .onAppear {
            addLog("View appeared")
        }
    }
    
    private func addLog(_ message: String) {
        debugLogs.append("\(Date().formatted(date: .omitted, time: .complete)): \(message)")
    }
    
    // MARK: - MarkupViewerDelegate
    
    func viewerSetup(_ viewer: MarkupViewerWKWebView) {
        addLog("viewerSetup called")
    }
    
    func viewerDidLoad(_ viewer: MarkupViewerWKWebView) {
        addLog("viewerDidLoad called")
    }
    
    func viewer(_ viewer: MarkupViewerWKWebView, heightDidChange height: CGFloat) {
        addLog("height changed to \(height)")
        viewerHeight = height
    }
    
    func viewer(_ viewer: MarkupViewerWKWebView, didSelectText text: String, hasSelection: Bool) {
        addLog("selection: '\(text)'")
    }
}

private struct DebugMarkupViewerRepresentable: UIViewRepresentable {
    @Binding var html: String
    let viewerDelegate: MarkupViewerDelegate?
    
    func makeUIView(context: Context) -> DebugMarkupViewerWKWebView {
        print("🔍 DebugMarkupViewerRepresentable: makeUIView called")
        let viewer = DebugMarkupViewerWKWebView(
            html: html,
            viewerDelegate: viewerDelegate,
            configuration: nil
        )
        return viewer
    }
    
    func updateUIView(_ viewer: DebugMarkupViewerWKWebView, context: Context) {
        print("🔍 DebugMarkupViewerRepresentable: updateUIView called with html: \(html.prefix(50))")
        viewer.setHtml(html)
    }
}

#if DEBUG
struct DebugMarkupViewerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DebugMarkupViewerView()
                .navigationTitle("Debug Viewer")
        }
    }
}
#endif
