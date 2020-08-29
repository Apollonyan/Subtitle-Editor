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
  @Published var avPlayer: AVPlayer?
  @Published var desiredPlaybackRate: Float = 1 {
    didSet {
      if isPlaying {
        avPlayer?.playImmediately(atRate: desiredPlaybackRate)
      }
    }
  }
  @Published var isPlaying: Bool = false {
    didSet {
      guard isPlaying != oldValue,
            avPlayer?.status == .readyToPlay
      else { return }
      if isPlaying {
        avPlayer?.playImmediately(atRate: desiredPlaybackRate)
      } else {
        avPlayer?.pause()
      }
    }
  }
  private var actualCurrentTime: CMTime = .zero
  @Published var currentTime: CMTime = .zero {
    didSet {
      if actualCurrentTime != currentTime {
        avPlayer?.seek(to: currentTime)
      }
    }
  }
  @Published var duration: TimeInterval = 0

  private var currentTimeObservation: Any!
  private var statusObservation: AnyCancellable!
  private var durationObservation: AnyCancellable!

  deinit {
    invalidate()
  }

  func loadURL(_ url: URL) {
    invalidate()
    #if os(macOS)
    UserDefaults.standard
      .set(try? url.bookmarkData(options: .withSecurityScope),
           forKey: "VIDEO_URL_BOOKMARK")
    #endif
    print(url.startAccessingSecurityScopedResource())
    avPlayer = AVPlayer(url: url)
    let interval = CMTime(seconds: 0.25, preferredTimescale: 50)
    currentTimeObservation = avPlayer!
      .addPeriodicTimeObserver(forInterval: interval, queue: nil) {
        [weak self] time in
        self?.actualCurrentTime = time
        self?.currentTime = time
      }
    statusObservation = avPlayer!.publisher(for: \.timeControlStatus)
      .map { $0 != .paused }
      .assign(to: \.isPlaying, on: self)
    durationObservation = avPlayer!.publisher(for: \.currentItem?.duration)
      .map { $0.flatMap { $0 == .indefinite ? 0 : $0.seconds } ?? 0}
      .assign(to: \.duration, on: self)
  }

  func invalidate() {
    guard let avPlayer = avPlayer else { return }
    avPlayer.pause()
    avPlayer.removeTimeObserver(currentTimeObservation!)
    statusObservation.cancel()
    durationObservation.cancel()
    (avPlayer.currentItem!.asset as! AVURLAsset).url
      .stopAccessingSecurityScopedResource()
  }
}
