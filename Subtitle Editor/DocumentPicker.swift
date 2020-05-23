//
//  DocumentPicker.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI
import MobileCoreServices

struct PickerButton<Label: View>: View {
  public let documentTypes: [CFString]
  public let onSelect: (URL) -> ()
  @State public var label: () -> Label
  @State private var isPresenting: Bool = false

  var body: some View {
    Button(action: {
      #if targetEnvironment(macCatalyst)
      UIApplication.shared.windows[0].rootViewController!.present(DocumentPickerController(
        documentTypes: self.documentTypes,
        onSelect: self.onSelect,
        onCancel: { self.isPresenting = false }
      ), animated: true)
      #else
      self.isPresenting = true
      #endif
    }, label: label)
      .sheet(isPresented: $isPresenting, onDismiss: { self.isPresenting = false }) {
        DocumentPicker(
          documentTypes: [kUTTypeMovie],
          onSelect: self.onSelect,
          onCancel: { self.isPresenting = false }
        )
          .edgesIgnoringSafeArea(.all)
    }
  }
}

struct DocumentPicker: UIViewControllerRepresentable {
  let documentTypes: [CFString]
  var onSelect: (URL) -> ()
  var onCancel: (() -> ())?

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
      documentTypes: documentTypes as [String],
      in: .import
    )
    controller.allowsMultipleSelection = false
    controller.delegate = context.coordinator
    return controller
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    let parent: DocumentPicker

    init(_ picker: DocumentPicker) {
      self.parent = picker
    }

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentAt url: URL) {
      parent.onSelect(url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      parent.onCancel?()
    }
  }
}

struct DocumentPicker_Previews: PreviewProvider {
  static var previews: some View {
    DocumentPicker(documentTypes: [kUTTypeMovie], onSelect: { print($0) })
  }
}

#if targetEnvironment(macCatalyst)
class DocumentPickerController: UIDocumentPickerViewController, UIDocumentPickerDelegate {
  var onSelect: (URL) -> ()
  var onCancel: (() -> ())?

  init(documentTypes allowedUTIs: [CFString],
       onSelect: @escaping (URL) -> (),
       onCancel: (() -> ())? = nil) {
    self.onSelect = onSelect
    self.onCancel = onCancel
    super.init(documentTypes: allowedUTIs as [String], in: .import)
    self.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    onSelect(urls[0])
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    onCancel?()
  }
}
#endif
