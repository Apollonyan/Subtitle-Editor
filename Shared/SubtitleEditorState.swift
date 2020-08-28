//
//  SubtitleEditorState.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/28/20.
//

import Combine
import SwiftUI
import struct AVFoundation.CMTime

class SubtitleEditorState: ObservableObject {
  @Published var currentTime: CMTime = .zero
  private var _currentIndex: Int = 0
  var currentIndex: Int? {
    let index = _currentIndex
    let currentTimeSec = currentTime.seconds
    quickCheck: if index < subtitles.segments.count {
      let nextIndex = index + 1
      if nextIndex == subtitles.segments.count {
        if subtitles.segments[index].contains(currentTimeSec) {
          return index
        }
        break quickCheck
      }
      if abs(currentTimeSec - subtitles.segments[nextIndex].startTime) < 0.001 {
        _currentIndex = nextIndex
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
        _currentIndex = nextIndex
        return nextIndex
      }
    }
    if let actualIndex = subtitles.indexOf(currentTimeSec) {
      _currentIndex = actualIndex
      return actualIndex
    } else {
      return nil
    }
  }
  var currentSegment: MutableSubtitle.Segment? {
    currentIndex.map { subtitles.mutableSegments[$0] }
  }
  var subtitles: MutableSubtitle { config.document }
  var _subtitles: Binding<MutableSubtitle> { config.$document }

  private let config: FileDocumentConfiguration<MutableSubtitle>
  init(document: FileDocumentConfiguration<MutableSubtitle>) {
    self.config = document
  }

  func timeInterval(for jumpTarget: String) -> TimeInterval? {
    let segments = jumpTarget
      .components(separatedBy: ":")
      .compactMap(Double.init)
    switch segments.count {
    case 1:
      let index = Int(segments[0]) - 1
      if subtitles.segments.indices.contains(index) {
        return subtitles.segments[index].startTime
      }
    case 2...:
      return segments
        .reversed().enumerated()
        .reduce(0) { $0 + pow(60, Double($1.0)) * $1.1 }
    default:
      break
    }
    return nil
  }
}
