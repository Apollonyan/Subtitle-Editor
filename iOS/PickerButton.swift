//
//  PickerButton.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/20/20.
//

import SwiftUI
import UniformTypeIdentifiers

struct PickerButton<Label: View>: View {
  public let documentTypes: [UTType]
  public let onSelect: (URL) -> ()
  @State public var label: () -> Label
  @State private var isPresenting: Bool = false

  var body: some View {
    Button(action: {
      self.isPresenting = true
    }, label: label)
    .sheet(isPresented: $isPresenting) {
      DocumentPicker(
        documentTypes: documentTypes,
        delegate: DocumentPicker.Delegate(
          onSelect: self.onSelect,
          onCancel: { self.isPresenting = false }
        )
      )
      .ignoresSafeArea()
    }
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
