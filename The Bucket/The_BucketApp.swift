//
//  The_BucketApp.swift
//  The Bucket
//
//  Created by Sam Ayler on 12/12/24.
//

import SwiftUI

@main
struct The_BucketApp: App {
    @StateObject private var viewModel = BucketViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        // Load preview data
                        Task {
                            print("Preview mode detected, attempting to load preview PDF")
                            if let pdfURL = Bundle.main.url(forResource: "CAC Initial Dec 2024",
                                                          withExtension: "pdf",
                                                          subdirectory: "Preview Content") {
                                print("Found preview PDF at: \(pdfURL)")
                                await viewModel.importPDF(pdfURL)
                            } else {
                                print("⚠️ Preview PDF not found in Preview Content directory")
                                // List contents of Preview Content directory for debugging
                                if let previewContentURL = Bundle.main.url(forResource: "Preview Content", withExtension: nil) {
                                    do {
                                        let contents = try FileManager.default.contentsOfDirectory(at: previewContentURL, 
                                                                                                includingPropertiesForKeys: nil)
                                        print("Preview Content directory contents:")
                                        contents.forEach { print("- \($0.lastPathComponent)") }
                                    } catch {
                                        print("Error listing Preview Content directory: \(error)")
                                    }
                                } else {
                                    print("⚠️ Preview Content directory not found")
                                }
                            }
                        }
                    }
                    #endif
                }
        }
    }
}
