//
//  Utils.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import AVFoundation

extension CMTime {
  var seconds: TimeInterval {
    get {
      return CMTimeGetSeconds(self)
    }
    set {
      self = CMTimeMakeWithSeconds(newValue,
                                   preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
  }
}

import subtitle

extension TimeInterval {
  var hms: String {
    let (h, m, s, _) = timestamp(from: self)
    return String(format: "%02d:%02d:%02d", h, m, s)
  }
}

class IntRef {
  var intValue: Int
  
  init(_ intValue: Int) {
    self.intValue = intValue
  }
}

import Foundation

extension UserDefaults {
  func withSecurityScopedURL<T>(forKey key: String,
                                then process: (URL?) throws -> T
  ) rethrows -> T {
    var isStale: Bool = false
    guard
      let data = data(forKey: key),
      let url = try? URL(
        resolvingBookmarkData: data, options: [.withoutUI, .withSecurityScope],
        bookmarkDataIsStale: &isStale),
      !isStale
      else { return try process(nil) }
    return try url.withSecurityScope(then: process)
  }
}

extension URL {
  func withSecurityScope<T>(then process: (URL?) throws -> T) rethrows -> T {
    guard startAccessingSecurityScopedResource()
      else { return try process(nil) }
    defer { stopAccessingSecurityScopedResource() }
    return try process(self)
  }
}
