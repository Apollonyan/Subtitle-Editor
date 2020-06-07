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
    var _contents: String
    
    var contents: [String] {
      return _contents.components(separatedBy: .newlines)
    }
  }
}

extension SubtitleSegment {
  func contains(_ timestamp: TimeInterval) -> Bool {
    return (startTime...endTime).contains(timestamp)
  }
}

extension Subtitle {
  func indexOf(_ timestamp: TimeInterval) -> Int? {
    var lowerBound = 0
    var upperBound = segments.count
    while lowerBound < upperBound {
      let midIndex = lowerBound + (upperBound - lowerBound) / 2
      if segments[midIndex].contains(timestamp) {
        return midIndex
      } else if segments[midIndex].endTime < timestamp {
        lowerBound = midIndex + 1
      } else {
        upperBound = midIndex
      }
    }
    return nil
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
      return Segment(
        id: i + 1,
        startTime: segment.startTime,
        endTime: segment.endTime,
        _contents: contents.joined(separator: "\n")
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
