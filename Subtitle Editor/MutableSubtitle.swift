//
//  MutableSubtitle.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import Foundation
import srt
import func tidysub.format

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
    guard upperBound > 0 else { return nil }
    while lowerBound < upperBound {
      let midIndex = lowerBound + (upperBound - lowerBound) / 2
      if segments[midIndex].contains(timestamp) {
        let nextIndex = midIndex + 1
        if segments.indices.contains(nextIndex),
           abs(segments[nextIndex].startTime - timestamp) < 0.001 {
          return nextIndex
        } else {
          return midIndex
        }
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
  init(data: Data) throws {
    self.init(segments: try SRT(data: data).segments)
  }

  func asData() throws -> Data {
    try SRT(segments: mutableSegments.map { segment in
      let contents = segment.contents
        .map(format)
        .filter { !$0.isEmpty }
      precondition(!contents.isEmpty, "Segment \(segment.id) has no content")
      return SRT.Segment(
        index: segment.id,
        from: segment.startTime,
        to: segment.endTime,
        contents: contents
      )
    }).asData()
  }

  var segments: [SubtitleSegment] {
    return mutableSegments
  }
  
  init(segments: [SubtitleSegment]) {
    self.mutableSegments = segments.enumerated().map { (i, segment) in
      return Segment(
        id: i + 1,
        startTime: segment.startTime,
        endTime: segment.endTime,
        _contents: segment.contents.joined(separator: "\n")
      )
    }
  }
}

import protocol SwiftUI.FileDocument
import UniformTypeIdentifiers

extension UTType {
  static let srt = UTType(filenameExtension: "srt")!
}

extension MutableSubtitle: FileDocument {
  static var readableContentTypes: [UTType] = [.srt]

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    try self.init(data: data)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    return try FileWrapper(regularFileWithContents: asData())
  }
}
