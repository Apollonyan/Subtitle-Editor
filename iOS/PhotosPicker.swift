//
//  PhotosPicker.swift
//  Subtitle Editor (iOS)
//
//  Created by Apollo Zhu on 8/28/20.
//

import SwiftUI
import PhotosUI
import os

let ppLogger = Logger(subsystem: "io.github.apollonyan.Subtitle-Editor", category: "PhotosPicker")

struct PhotosPicker: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let handleURL: (URL) -> Void

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var configuration = PHPickerConfiguration()
    configuration.filter = .videos
    let controller = PHPickerViewController(configuration: configuration)
    controller.delegate = context.coordinator
    return controller
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController,
                              context: Context) {
    // no state to update
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let parent: PhotosPicker
    init(_ parent: PhotosPicker) {
      self.parent = parent
    }

    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
      parent.isPresented = false
      let movie = UTType.movie.identifier
      guard let provider = results.first?.itemProvider,
            provider.hasItemConformingToTypeIdentifier(movie)
            else { return }
      provider.loadItem(forTypeIdentifier: movie, options: nil) {
        [weak self] (url, error) in
        guard let parent = self?.parent,
              let url = url as? URL
        else { return }
        parent.handleURL(url)
      }
    }
  }
}

struct PHPicker_Previews: PreviewProvider {
  static var previews: some View {
    PhotosPicker(isPresented: .constant(true)) { print($0) }
  }
}
