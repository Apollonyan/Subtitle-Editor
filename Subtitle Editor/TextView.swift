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
  
  func makeUIView(context: Context) -> UITextView {
    let view = UITextView()
    view.delegate = context.coordinator
    view.isScrollEnabled = false
    view.font = UIFont.preferredFont(forTextStyle: .body)
    return view
  }
  
  func updateUIView(_ uiView: UITextView, context: Context) {
    if uiView.text != text {
      uiView.text = text
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
    TextView(text: .constant("Hello"))
  }
}
