//
//  TextView.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 6/7/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI

struct TextView: UIViewRepresentable {
  @Binding var text: String
  @State var textColor: (String) -> UIColor?

  func makeUIView(context: Context) -> UITextView {
    let uiView = UITextView()
    uiView.delegate = context.coordinator
    uiView.isScrollEnabled = false
    uiView.font = UIFont.preferredFont(forTextStyle: .body)
    uiView.backgroundColor = .clear
    return uiView
  }
  
  func updateUIView(_ uiView: UITextView, context: Context) {
    if uiView.text != text {
      uiView.text = text
    }
    let newColor = textColor(text) ?? UIColor.label
    if uiView.textColor != newColor {
      uiView.textColor = newColor
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }
  
  class Coordinator: NSObject, UITextViewDelegate {
    @Binding var text: String
    
    init(text: Binding<String>) {
      self._text = text
    }
    
    func textViewDidChange(_ textView: UITextView) {
      guard textView.markedTextRange == nil else { return }
      text = textView.text
    }
  }
}

struct TextView_Previews: PreviewProvider {
  static var previews: some View {
    TextView(text: .constant("Hello"), textColor: { _ in nil })
  }
}
