//
//  ViewerDemoContentView.swift
//  SwiftUIDemo
//
//  Created by MarkupEditor on 1/20/25.
//  Copyright © 2025 Steven Harris. All rights reserved.
//

import SwiftUI
import MarkupEditor

/// A dedicated demo view showcasing the MarkupViewer functionality.
///
/// This view demonstrates:
/// - Extremely fast rendering with no perceptible flicker
/// - Automatic height adjustment to fit content
/// - Custom selection menu with "Select All" and "Copy" only
/// - Multiple HTML content samples for testing
struct ViewerDemoContentView: View {
    
    @State private var selectedSample = 0
    @State private var currentHtml: String = ""
    
    // Sample HTML content for demonstration
    private let htmlSamples = [
        ("Simple Content", """
        <h1>Welcome to MarkupViewer</h1>
        <p>This is a <strong>read-only</strong> HTML viewer that automatically adjusts its height to fit the content.</p>
        <p>Try selecting text to see the custom menu with limited options.</p>
        """),
        
        ("Rich Content", """
        <h1>Rich HTML Content</h1>
        <h2>Features</h2>
        <ul>
            <li><strong>Extremely fast rendering</strong> - No perceptible flicker</li>
            <li><em>Auto-sizing behavior</em> - Respects container width, grows/shrinks in height</li>
            <li><code>Custom selection menu</code> - "Select All" and "Copy" only</li>
            <li><u>Performance optimized</u> - Singleton warm-up strategy</li>
        </ul>
        
        <h3>Code Example</h3>
        <pre><code>MarkupViewerView(html: .constant(htmlContent))
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)</code></pre>
        
        <blockquote>
            <p>Select text anywhere to see the custom context menu in action. Notice how only "Select All" and "Copy" are available.</p>
        </blockquote>
        """),
        
        ("Table Content", """
        <h2>Data Tables</h2>
        <p>Tables automatically adjust to the container width:</p>
        
        <table>
            <thead>
                <tr>
                    <th>Feature</th>
                    <th>MarkupEditor</th>
                    <th>MarkupViewer</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Editing</td>
                    <td>✅ Full editing capabilities</td>
                    <td>❌ Read-only</td>
                </tr>
                <tr>
                    <td>Rendering Speed</td>
                    <td>⚡ Fast</td>
                    <td>⚡⚡ Extremely fast</td>
                </tr>
                <tr>
                    <td>Memory Usage</td>
                    <td>📊 Standard</td>
                    <td>📉 Optimized</td>
                </tr>
                <tr>
                    <td>Selection Menu</td>
                    <td>🛠️ Full menu</td>
                    <td>👁️ View-only menu</td>
                </tr>
            </tbody>
        </table>
        """),
        
        ("Long Content", """
        <h1>Performance Test: Long Content</h1>
        <p>This sample tests the viewer's performance with longer content that requires scrolling.</p>
        
        <h2>Lorem Ipsum</h2>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
        
        <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
        
        <h3>Multiple Paragraphs</h3>
        <p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
        
        <p>Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.</p>
        
        <h3>Lists and More</h3>
        <ol>
            <li>First item with some longer text to test wrapping behavior</li>
            <li>Second item that demonstrates how lists render in the viewer</li>
            <li>Third item to show consistent spacing and formatting</li>
            <li>Fourth item with <strong>bold text</strong> and <em>italic text</em></li>
            <li>Fifth item with a <a href="#">link that won't navigate</a></li>
        </ol>
        
        <p>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.</p>
        
        <blockquote>
            <p>This blockquote contains a longer passage to test how the viewer handles quoted content with proper indentation and styling.</p>
            <p>Multiple paragraphs within blockquotes should maintain proper spacing and visual hierarchy.</p>
        </blockquote>
        
        <p>Similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio.</p>
        """)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with sample selector
            VStack {
                HStack {
                    Text("MarkupViewer Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                HStack {
                    Text("Sample:")
                    Picker("HTML Sample", selection: $selectedSample) {
                        ForEach(0..<htmlSamples.count, id: \.self) { index in
                            Text(htmlSamples[index].0).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedSample) { newValue in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentHtml = htmlSamples[newValue].1
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Instructions:")
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("•")
                        Text("Select text to see the custom menu (Select All, Copy only)")
                    }
                    HStack {
                        Text("•")
                        Text("Notice the instant rendering with no flicker")
                    }
                    HStack {
                        Text("•")
                        Text("Observe how the viewer auto-sizes to fit content")
                    }
                    HStack {
                        Text("•")
                        Text("Switch between samples to test performance")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBlue).opacity(0.1))
            
            // Viewer container
            ScrollView {
                VStack {
                    MarkupViewerView(html: .constant(currentHtml))
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .padding()
                    
                    // Performance info
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.green)
                            Text("Performance Features")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("✅ Singleton warm-up strategy for instant loading")
                            }
                            HStack {
                                Text("✅ Optimized JavaScript bundle with tree shaking")
                            }
                            HStack {
                                Text("✅ Critical CSS inlined for fast first paint")
                            }
                            HStack {
                                Text("✅ Disabled scrolling with auto-height sizing")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemGreen).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Viewer Demo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load the first sample
            currentHtml = htmlSamples[0].1
        }
    }
}

#if DEBUG
struct ViewerDemoContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ViewerDemoContentView()
        }
    }
}
#endif
