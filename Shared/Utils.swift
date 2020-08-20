//
//  Utils.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import AVFoundation

let MSEC_PER_SEC = 1000

extension CMTime {
  /// Provides "write access" to the property `seconds`.
  var _seconds: TimeInterval {
    get {
      return seconds
    }
    set {
      self = CMTimeMakeWithSeconds(newValue,
                                   preferredTimescale: CMTimeScale(MSEC_PER_SEC))
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
                                autoScope: Bool = true,
                                then process: (URL?) throws -> T
  ) rethrows -> T {
    #if os(macOS)
    var isStale: Bool = false
    guard
      let data = data(forKey: key),
      let url = try? URL(
        resolvingBookmarkData: data, options: [.withoutUI, .withSecurityScope],
        bookmarkDataIsStale: &isStale),
      !isStale
      else { return try process(nil) }
    if autoScope {
      return try url.withSecurityScope(then: process)
    } else {
      return try process(url)
    }
    #else
    return try process(nil)
    #endif
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

extension NumberFormatter {
    static let hundredths: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

extension Float {
    var hundredths: String {
        return NumberFormatter.hundredths.string(from: self as NSNumber)!
    }
}
