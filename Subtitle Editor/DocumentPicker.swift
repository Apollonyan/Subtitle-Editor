//
//  DocumentPicker.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

#if targetEnvironment(macCatalyst)
private var coordinator: DocumentPicker.Coordinator! = nil
#endif
struct PickerButton<Label: View>: View {
  public let documentTypes: [UTType]
  public let onSelect: (URL) -> ()
  @State public var label: () -> Label
  @State private var isPresenting: Bool = false

  var body: some View {
    Button(action: {
      #if targetEnvironment(macCatalyst)
      var top = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
      while let presented = top?.presentedViewController { top = presented }
      coordinator = DocumentPicker.Coordinator(.init(
        onSelect: self.onSelect,
        onCancel: { self.isPresenting = false }
      ))
      top?.present(coordinator.makeForDocumentTypes(documentTypes), animated: true)
      #else
      self.isPresenting = true
      #endif
    }, label: label)
    .sheet(isPresented: $isPresenting) {
      DocumentPicker(
        documentTypes: documentTypes,
        delegate: .init(
          onSelect: self.onSelect,
          onCancel: { self.isPresenting = false }
        )
      )
      .ignoresSafeArea()
    }
  }
}

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
    return context.coordinator.makeForDocumentTypes(documentTypes)
  }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(delegate)
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    func makeForDocumentTypes(_ documentTypes: [UTType]) -> UIDocumentPickerViewController {
      let controller = UIDocumentPickerViewController(
        forOpeningContentTypes: documentTypes
      )
      controller.allowsMultipleSelection = false
      controller.delegate = self
      return controller
    }

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
