//
//  VideoSource.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/20/20.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

class VideoSource: ObservableObject {
  let avPlayer: AVPlayer
  @Published var desiredPlaybackRate: Float = 1 {
    didSet {
      if isPlaying {
        avPlayer.playImmediately(atRate: desiredPlaybackRate)
      }
    }
  }
  @Published var isPlaying: Bool = true {
    didSet {
      if isPlaying {
        avPlayer.playImmediately(atRate: desiredPlaybackRate)
      } else {
        avPlayer.pause()
      }
    }
  }
  private var actualCurrentTime: CMTime = .zero
  @Published var currentTime: CMTime = .zero {
    didSet {
      if actualCurrentTime != currentTime {
        avPlayer.seek(to: currentTime)
      }
    }
  }
  @Published var duration: TimeInterval = 0

  private var currentTimeObservation: Any!
  private var durationObservation: NSKeyValueObservation!
  init?(url: URL? = UserDefaults.standard
          .withSecurityScopedURL(forKey: "VIDEO_URL_BOOKMARK", autoScope: false) {
            _ = $0?.startAccessingSecurityScopedResource()
            return $0
          }) {
    guard let url = url else {
      return nil
    }
    #if os(macOS)
    UserDefaults.standard
      .set(try? url.bookmarkData(options: .withSecurityScope),
           forKey: "VIDEO_URL_BOOKMARK")
    #endif
    avPlayer = AVPlayer(url: url)
    let interval = CMTime(seconds: 0.25, preferredTimescale: 50)
    currentTimeObservation = avPlayer
      .addPeriodicTimeObserver(forInterval: interval, queue: nil) {
        [weak self] time in
        self?.actualCurrentTime = time
        self?.currentTime = time
      }
    durationObservation = avPlayer.currentItem!
      .observe(\.duration, options: [.initial, .new]) {
        [weak self] (item, change) in
        guard let self = self, let newValue = change.newValue else { return }
        self.duration = newValue == .indefinite ? 0 : newValue.seconds
      }
  }

  deinit {
    avPlayer.pause()
    avPlayer.removeTimeObserver(currentTimeObservation!)
    durationObservation.invalidate()
    (avPlayer.currentItem?.asset as? AVURLAsset)?.url
      .stopAccessingSecurityScopedResource()
  }
}
