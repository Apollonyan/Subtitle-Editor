//
//  EditorPanel.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/20/20.
//

import SwiftUI
import func tidysub.format

struct EditorPanel: View {
  @EnvironmentObject var appState: SubtitleEditorState

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if !appState.subtitles.mutableSegments.isEmpty {
          LazyVStack {
            ForEach(appState.subtitles.mutableSegments) { segment in
              HStack(spacing: 8) {
                HStack {
                  Text(String(format: "%-4d", segment.id))
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(appState.currentIndex == segment.id - 1
                                      ? .white
                                      : .secondary)
                  /*
                   VStack {
                   Text(SRT.Segment.timestamp(from: segment.startTime))
                   .foregroundColor(.gray)
                   Text(SRT.Segment.timestamp(from: segment.endTime))
                   .foregroundColor(.gray)
                   }
                   */
                }
                .padding(.leading, 8)
                VStack {
                  TextEditor(text: appState._subtitles.mutableSegments[segment.id - 1]._contents)
                    .foregroundColor(segment.contents.reduce(segment.contents.count > 2 ? .red : nil) {
                      (previousColor, currentLine) in
                      switch format(currentLine).displayWidth {
                      case ...36:
                        return previousColor
                      case ..<40 where previousColor < .purple:
                        return .purple
                      case ..<46 where previousColor < .orange:
                        return .orange
                      default:
                        return .red
                      }
                    })
                    .fixedSize(horizontal: false, vertical: true)
                }
              }
              .onTapGesture {
                appState.currentTime._seconds = segment.startTime
              }
              .background(appState.currentIndex == segment.id - 1
                            ? Color.accentColor.cornerRadius(8)
                            : nil)
            }
          }
          .listStyle(PlainListStyle())
          .onChange(of: appState.currentTime) { [oldIndex = appState.currentIndex ?? 0] _ in
            guard let index = appState.currentIndex, index != oldIndex else {
              return
            }
            let targetID = appState.currentSegment!.id
            if abs(index - oldIndex) < 10 {
              withAnimation(.easeOut) {
                proxy.scrollTo(targetID, anchor: .center)
              }
            } else {
              proxy.scrollTo(targetID, anchor: .center)
            }
          }
        }
      }
    }
  }
}

struct EditorPanel_Previews: PreviewProvider {
  static var previews: some View {
    EditorPanel()
  }
}
