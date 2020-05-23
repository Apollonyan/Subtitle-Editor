//
//  MutableSubtitle.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import Foundation
import subtitle
import srt

struct MutableSubtitle {
  public var mutableSegments: [Segment]

  struct Segment: SubtitleSegment, Identifiable {
    let id: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
    var contents: [String]
  }
}

extension MutableSubtitle: Subtitle {
  var segments: [SubtitleSegment] {
    return mutableSegments
  }

  init(url: URL) throws {
    self.init(segments: try SRT(url: url).segments)
  }

  init(segments: [SubtitleSegment]) {
    self.mutableSegments = segments.enumerated().map { (i, segment) in
      var contents = segment.contents
      contents += [String](repeating: "", count: 2 - segment.contents.count)
      return Segment(
        id: i + 1,
        startTime: segment.startTime,
        endTime: segment.endTime,
        contents: contents
      )
    }
  }

  func write(to url: URL) throws {
    try SRT(segments: mutableSegments.map { segment in
      let contents = segment.contents
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
      precondition(!contents.isEmpty, "Segment \(segment.id) has no content")
      return SRT.Segment(
        index: segment.id,
        from: segment.startTime,
        to: segment.endTime,
        contents: contents
      )
    }).write(to: url)
  }
}
