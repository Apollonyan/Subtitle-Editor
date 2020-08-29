//
//  fileImporter.swift
//  Subtitle Editor (macOS)
//
//  Created by Apollo Zhu on 8/28/20.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
extension View {
  @available(macOS, deprecated: 11.0, message: "beta 6")
  public func fileImporter(
    isPresented: Binding<Bool>,
    allowedContentTypes: [UTType],
    onCompletion: @escaping (Result<URL, Error>) -> Void
  ) -> some View {
    self.fileImporter(
      isPresented: isPresented,
      allowedContentTypes: allowedContentTypes,
      allowsMultipleSelection: false
    ) { (result) in
      onCompletion(result.flatMap {
        if let url = $0.first {
          return .success(url)
        } else {
          return .failure(CocoaError(.userCancelled))
        }
      })
    }
  }

  @available(macOS, deprecated: 11.0, message: "beta 6")
  public func fileImporter(
    isPresented: Binding<Bool>,
    allowedContentTypes: [UTType],
    allowsMultipleSelection: Bool,
    onCompletion: @escaping (Result<[URL], Error>) -> Void
  ) -> some View {
    self.onChange(of: isPresented.wrappedValue) { isPresenting in
      if isPresenting {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedContentTypes
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.begin { response in
          guard response != .cancel else { return }
          onCompletion(.success(panel.urls))
        }
      }
    }
  }
}
#endif
