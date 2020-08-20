//
//  DocumentPicker.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
  let documentTypes: [UTType]
  let delegate: Delegate

  struct Delegate {
    let onSelect: (URL) -> ()
    let onCancel: (() -> ())?
  }

  func updateUIViewController(
    _ uiViewController: UIDocumentPickerViewController,
    context: Context
  ) {
    // do nothing, no states
  }
  
  func makeUIViewController(
    context: Context
  ) -> UIDocumentPickerViewController {
    let controller = UIDocumentPickerViewController(
      forOpeningContentTypes: documentTypes
    )
    controller.allowsMultipleSelection = false
    controller.delegate = context.coordinator
    return controller
  }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(delegate)
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    let delegate: Delegate

    init(_ delegate: Delegate) {
      self.delegate = delegate
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      delegate.onSelect(urls[0])
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      delegate.onCancel?()
    }
  }
}

struct DocumentPicker_Previews: PreviewProvider {
  static var previews: some View {
    DocumentPicker(documentTypes: [.movie],
                   delegate: DocumentPicker.Delegate(onSelect: { print($0) },
                                                     onCancel: nil))
  }
}
