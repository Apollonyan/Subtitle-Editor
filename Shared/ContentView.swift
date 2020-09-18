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


  var videoPanel: some View {
    #if os(iOS)
    return VideoPanel(videoSource: videoSource)
    #else
    return VideoPanel(videoSource: videoSource)
      .padding()
    #endif
  }

  var editorPanel: some View {
    #if os(iOS)
    return EditorPanel()
    #else
    return EditorPanel()
      .padding()
    #endif
  }

  #if os(iOS)
  @Environment(\.horizontalSizeClass) private var hSizeClass
  var body: some View {
    GeometryReader { geo in
      if geo.size.height > geo.size.width && hSizeClass == .compact {
        VStack(spacing: 8) {
          videoPanel
          editorPanel
        }
        .padding()
        .ignoresSafeArea(.container, edges: .bottom)
      } else {
        HStack(spacing: 16) {
          videoPanel
          Spacer()
          editorPanel
            .frame(idealWidth: min(max(500, geo.size.width * 0.3), geo.size.width * 0.5),
                   idealHeight: geo.size.height)
            .fixedSize()
        }
        .padding()
      }
    }
  }
  #else
  var body: some View {
    GeometryReader { geo in
      if geo.size.height > geo.size.width {
        VSplitView {
          videoPanel
          editorPanel
        }
      } else {
        HSplitView {
          videoPanel
          editorPanel
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
