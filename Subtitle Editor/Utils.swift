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
  var seconds: TimeInterval {
    get {
      return CMTimeGetSeconds(self)
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

extension Notification.Name {
  static let reloadSubtitle = Notification.Name("Reload Please")
}

import Combine

class Monitor {
  public let key: String
  public let onChange: () -> Void
  private var descriptor: Int32 = -1
  private var observer: DispatchSourceFileSystemObject? = nil
  private var cancellable: NSObjectProtocol?
  
  public init(_ key: String, onChange: @escaping () -> Void) {
    self.onChange = onChange
    self.key = key
    self.newURL()
    NotificationCenter.default
      .addObserver(self, selector: #selector(newURL),
                   name: UserDefaults.didChangeNotification,
                   object: nil)
  }
  
  @objc private func newURL() {
    cancelMonitor()
    UserDefaults.standard.withSecurityScopedURL(forKey: key, autoScope: false)
    { [weak self] in
      guard let url = $0,
        url.startAccessingSecurityScopedResource()
        else { return }
      descriptor = open(url.path, O_EVTONLY)
      observer = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: self!.descriptor,
        eventMask: .write,
        queue: .global(qos: .userInteractive)
      )
      observer!.setEventHandler(handler: onChange)
      observer!.setCancelHandler {
        guard let self = self else { return }
        if self.descriptor != -1 {
          close(self.descriptor)
          self.descriptor = -1
        }
      }
      observer!.activate()
      onChange()
    }
  }
  
  private func cancelMonitor() {
    observer?.cancel()
  }
  
  deinit {
    cancelMonitor()
    UserDefaults.standard.withSecurityScopedURL(forKey: key, autoScope: false) {
      $0?.stopAccessingSecurityScopedResource()
    }
    NotificationCenter.default.removeObserver(self)
  }
}
