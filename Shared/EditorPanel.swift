//
//  EditorPanel.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/20/20.
//

import SwiftUI

struct EditorPanel: View {
  @Binding public var subtitles: MutableSubtitle

  private var currentIndex: Int? {
    let index = _currentIndex.intValue
    let currentTimeSec = videoSource.currentTime.seconds
    quickCheck: if index < subtitles.segments.count {
      let nextIndex = index + 1
      if nextIndex == subtitles.segments.count {
        if subtitles.segments[index].contains(currentTimeSec) {
          return index
        }
        break quickCheck
      }
      if abs(currentTimeSec - subtitles.segments[nextIndex].startTime) < 0.001 {
        _currentIndex.intValue = nextIndex
        return nextIndex
      }
      if subtitles.segments[index].contains(currentTimeSec) {
        return index
      }
      if (subtitles.segments[index].endTime...subtitles.segments[nextIndex].startTime)
          .contains(currentTimeSec) {
        return nil
      }
      if subtitles.segments[nextIndex].contains(currentTimeSec) {
        _currentIndex.intValue = nextIndex
        return nextIndex
      }
    }
    if let actualIndex = subtitles.indexOf(currentTimeSec) {
      _currentIndex.intValue = actualIndex
      return actualIndex
    } else {
      return nil
    }
  }
  private var _currentIndex = IntRef(0)

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if !subtitles.mutableSegments.isEmpty {
          LazyVStack {
            ForEach(subtitles.mutableSegments) { segment in
              HStack(spacing: 8) {
                HStack {
                  Text(String(format: "%-4d", segment.id))
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(currentIndex == segment.id - 1
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
                  TextEditor(text: $subtitles.mutableSegments[segment.id - 1]._contents)
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
                videoSource.currentTime._seconds = segment.startTime
              }
              .background(currentIndex == segment.id - 1
                            ? Color.accentColor.cornerRadius(8)
                            : nil)
            }
          }
          .listStyle(PlainListStyle())
          .onChange(of: videoSource.currentTime) { [oldIndex = currentIndex ?? 0] _ in
            guard let index = currentIndex, index != oldIndex else { return }
            let targetID = subtitles.mutableSegments[index].id
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
