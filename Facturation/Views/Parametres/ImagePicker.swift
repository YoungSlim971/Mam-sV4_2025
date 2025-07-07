//
//  ImagePicker.swift
//  Facturation
//
//  Created by Young Slim on 05/07/2025.
//
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ImagePicker: NSViewControllerRepresentable {
    @Binding var image: NSImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            if #available(macOS 12.0, *) {
                panel.allowedContentTypes = [.png, .jpeg, .heic]
            } else {
                panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic"]
            }
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.url, let nsImage = NSImage(contentsOf: url) {
                image = nsImage
            }
            context.coordinator.parent.image = image
        }
        return controller
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    
    class Coordinator: NSObject {
        var parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
    }
}
