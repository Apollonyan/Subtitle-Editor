//
//  SubtitleEditorState.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/28/20.
//

import Combine
import SwiftUI
import AVFoundation

class SubtitleEditorState: ObservableObject {
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
  var _subtitles: Binding<MutableSubtitle> {
    return Binding(
      get: {
        self.config.document
      },
      set: { newValue in
        self.config.document = newValue
        self.objectWillChange.send()
      }
    )
  }

  private var config: FileDocumentConfiguration<MutableSubtitle>!

  func withSubtitle(_ document: FileDocumentConfiguration<MutableSubtitle>) -> Self {
    config = document
    return self
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
