//
//  ContentView.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI
import AVKit
import AVFoundation
import srt
import tidysub

struct ContentView: View {
  @EnvironmentObject var state: SubtitleEditorState
  @StateObject var videoSource = VideoSource()

  #if os(iOS)
  @Environment(\.horizontalSizeClass) private var hSizeClass
  var body: some View {
    GeometryReader { geo in
      if geo.size.height > geo.size.width && hSizeClass == .compact {
        VStack(spacing: 8) {
          VideoPanel(videoSource: videoSource)
          EditorPanel()
        }
        .padding()
        .ignoresSafeArea(.container, edges: .bottom)
      } else {
        HStack(spacing: 16) {
          VideoPanel(videoSource: videoSource)
          EditorPanel()
            .frame(idealWidth: max(geo.size.width * 0.3, 500),
                   idealHeight: geo.size.height)
            .fixedSize()
        }
      }
    }
  }
  #else
  var body: some View {
    GeometryReader { geo in
      if geo.size.height > geo.size.width {
        VSplitView {
          VideoPanel()
            .padding()
          EditorPanel()
            .padding()
        }
      } else {
        HSplitView {
          VideoPanel()
            .padding()
          EditorPanel()
            .padding()
        }
      }
    }
  }
  #endif
}

extension Color: Comparable {
  public static func < (lhs: Color, rhs: Color) -> Bool {
    switch (lhs, rhs) {
    case let (x, y) where x == y:
      return false
    case (_, .red):
      return true
    case (_, .orange):
      return true
    case (_, .purple):
      return true
    default:
      return false
    }
  }
}

extension Optional: Comparable where Wrapped: Comparable {
  public static func < (lhs: Optional<Wrapped>, rhs: Optional<Wrapped>) -> Bool {
    switch (lhs, rhs) {
    case let (.some(lhsWrapped), .some(rhsWrapped)):
      return lhsWrapped < rhsWrapped
    case (nil, .some):
      return true
    default:
      return false
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
    /**
     MutableSubtitle(mutableSegments: [
       .init(id: 1, startTime: 0, endTime: 0, _contents: "Hello"),
       .init(id: 1234, startTime: 0, endTime: 0, _contents: """
           Very Long
           Very good
           """
       )
     ])
     */
  }
}
