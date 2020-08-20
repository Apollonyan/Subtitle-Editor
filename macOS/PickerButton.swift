//
//  PickerButton.swift
//  Subtitle Editor (macOS)
//
//  Created by Apollo Zhu on 8/20/20.
//

import SwiftUI
import UniformTypeIdentifiers

struct PickerButton<Label: View>: View {
  public let documentTypes: [UTType]
  public let onSelect: (URL) -> ()
  @State public var label: () -> Label

  var body: some View {
    Button(action: {
      let panel = NSOpenPanel()
      panel.allowedContentTypes = documentTypes
      panel.allowsMultipleSelection = false
      panel.begin { _ in
        if let url = panel.url {
          onSelect(url)
        }
      }
    }, label: label)
  }
}

struct PickerButton_Previews: PreviewProvider {
  static var previews: some View {
    PickerButton(documentTypes: [.text]) {
      print($0)
    } label: {
      Text("OwO")
    }
  }
}
