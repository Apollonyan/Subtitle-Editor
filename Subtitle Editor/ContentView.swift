//
//  ContentView.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI
import Introspect
import VideoPlayer
import AVFoundation
import MobileCoreServices
import srt
import tidysub

extension View {
  func subtitleInContainer(ofSize size: CGSize) -> some View {
    self.font(.system(size: size.width / 1139 * 28))
      .foregroundColor(.white)
      .padding(.horizontal, 16)
      .background(Color.black.opacity(0.4))
      .cornerRadius(4)
  }
}

struct ContentView: View {
  @State private var isPlaying: Bool = true
  @State private var currentTime: CMTime = .zero
  @State private var videoDuration: TimeInterval = 0
  @State private var videoURL: URL? = UserDefaults.standard.url(forKey: "VIDEO_URL") {
    didSet {
      UserDefaults.standard.set(videoURL, forKey: "VIDEO_URL")
    }
  }
  @State private var subtitles: MutableSubtitle
    = UserDefaults.standard.withSecurityScopedURL(forKey: "SUB_URL_BOOKMARK") {
      $0.flatMap { try? MutableSubtitle(url: $0) }
    } ?? MutableSubtitle(segments: [])
  @State private var jumpTarget: String = ""
  
  var currentIndex: Int? {
    let index = _currentIndex.intValue
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
        _currentIndex.intValue = nextIndex
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
        _currentIndex.intValue = nextIndex
        return nextIndex
      }
    }
    if let actualIndex = subtitles.indexOf(currentTimeSec) {
      _currentIndex.intValue = actualIndex
      return actualIndex
    } else {
      return nil
    }
  }
  private var _currentIndex = IntRef(0)
  
  
  func displaySubtitle(at index: Int) -> some View {
    let contents = subtitles.segments[index].contents
      .filter { !$0.isEmpty }
    return GeometryReader { geo in
      VStack(spacing: 0) {
        Spacer()
        ForEach(contents, id: \.self) {
          Text($0)
            .subtitleInContainer(ofSize: geo.size)
        }
      }
      .padding(.bottom, 20)
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
  }
  
  var videoPlayer: some View {
    VStack {
      ZStack {
        VideoPlayer(url: videoURL!, play: $isPlaying, time: $currentTime)
          .onStateChanged { (state) in
            switch state {
            case .playing(totalDuration: let duration):
              self.videoDuration = duration
            default:
              break
            }
        }
        .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
        
        if currentIndex != nil {
          displaySubtitle(at: currentIndex!)
        }
      }
      .onTapGesture {
        self.isPlaying.toggle()
      }
      
      HStack(spacing: 16) {
        Text(currentTime.seconds.hms)
        
        Slider(value: $currentTime.seconds, in: 0...videoDuration)
        
        Text(videoDuration.hms)
      }

      HStack {
        Text("Jump to: ")
        TextField("time/segment", text: $jumpTarget) {
          let segments = self.jumpTarget
            .components(separatedBy: ":")
            .compactMap(Double.init)
          switch segments.count {
          case 1:
            let index = Int(segments[0]) - 1
            if self.subtitles.segments.indices.contains(index) {
              self.currentTime.seconds
                = self.subtitles.segments[index].startTime
            }
          case 2...:
            let desired = segments
              .reversed().enumerated()
              .reduce(0) { $0 + pow(60, Double($1.0)) * $1.1 }
            self.currentTime.seconds = min(max(desired, 0), self.videoDuration)
          default:
            break
          }
          self.jumpTarget = ""
        }
      }
      
      HStack(alignment: .lastTextBaseline, spacing: 32) {
        Button(action: {
          self.currentTime.seconds = max(0, self.currentTime.seconds - 15)
        }) {
          Image(systemName: "gobackward.15")
            .font(.title)
        }
        .disabled(currentTime.seconds < 5)
        
        Button(action: {
          self.isPlaying.toggle()
        }) {
          Image(systemName: isPlaying ? "pause.rectangle.fill" : "play.rectangle.fill")
            .font(.largeTitle)
        }
        
        Button(action: {
          self.currentTime.seconds = min(self.videoDuration, self.currentTime.seconds + 15)
        }) {
          Image(systemName: "goforward.15")
            .font(.title)
        }
        .disabled(currentTime.seconds + 5 > videoDuration)
      }
    }
  }
  
  var videoControlPanel: some View {
    VStack {
      Spacer()
      if videoURL != nil {
        videoPlayer
      }
      Spacer()
      PickerButton(documentTypes: [kUTTypeMovie], onSelect: {
        self.videoURL = $0
      }, label: {
        Text("Choose Video")
      })
    }
  }
  
  var subtitleEditorPanel: some View {
    VStack {
      if !subtitles.mutableSegments.isEmpty {
        List(subtitles.mutableSegments) { segment in
          HStack(spacing: 16) {
            HStack {
              Text(String(format: "%4d", segment.id))
                .font(.system(.title, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.gray)
              /*
               VStack {
               Text(SRT.Segment.timestamp(from: segment.startTime))
               .foregroundColor(.gray)
               Text(SRT.Segment.timestamp(from: segment.endTime))
               .foregroundColor(.gray)
               }
               */
            }
            VStack {
              TextView(
                text: self.$subtitles.mutableSegments[segment.id - 1]._contents,
                textColor: { subtitle in
                  let lines = subtitle.components(separatedBy: .newlines)
                  let initial: UIColor? = lines.count > 2 ? .systemRed : nil
                  return lines.reduce(initial) { (previousColor, currentLine) in
                    switch format(currentLine).displayWidth {
                    case ...36:
                      return previousColor
                    case ..<40 where previousColor < UIColor.systemIndigo:
                      return UIColor.systemIndigo
                    case ..<46 where previousColor < UIColor.systemOrange:
                      return UIColor.systemOrange
                    default:
                      return UIColor.systemRed
                    }
                  }
                }
              )
            }
          }
          .onTapGesture {
            self.currentTime.seconds = segment.startTime
          }
          .padding(8)
          .background(self.currentIndex == segment.id - 1 ? Color.yellow.opacity(0.5) : nil)
        }
        .introspectTableView { (tableView) in
          tableView.separatorStyle = .none
          guard let row = self.currentIndex else { return }
          let target = IndexPath(row: row, section: 0)
          let animated = tableView.indexPathsForVisibleRows?.contains(target) ?? false
          tableView.scrollToRow(at: target, at: .middle, animated: animated)
        }
      }
      
      PickerButton(documentTypes: [kUTTypeData], onSelect: {
        $0.withSecurityScope {
          if let url = $0,
            let subtitles = try? MutableSubtitle(url: url) {
            self.subtitles = subtitles
            UserDefaults.standard.set(
              try? url.bookmarkData(options: .withSecurityScope),
              forKey: "SUB_URL_BOOKMARK"
            )
          }
        }
      }) {
        Text("Choose Subtitle")
      }
    }
  }
  
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  
  var body: some View {
    Group {
      if horizontalSizeClass == .compact {
        VStack {
          self.videoControlPanel
          self.subtitleEditorPanel
        }
      } else {
        GeometryReader { geo in
          HStack {
            self.videoControlPanel
            self.subtitleEditorPanel
              .frame(idealWidth: max(geo.size.width * 0.3, 500), idealHeight: geo.size.height)
              .fixedSize()
          }
        }
        .padding()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .saveFile)) { _ in
      UserDefaults.standard.withSecurityScopedURL(forKey: "SUB_URL_BOOKMARK") {
        $0.map { try? self.subtitles.write(to: $0) }
      }
    }
  }
}

extension UIColor: Comparable {
  public static func < (lhs: UIColor, rhs: UIColor) -> Bool {
    switch (lhs, rhs) {
    case let (x, y) where x == y:
      return false
    case (_, .systemRed):
      return true
    case (_, .systemOrange):
      return true
    case (_, .systemIndigo):
      return true
    default:
      return false
    }
  }
}

extension Optional: Comparable where Wrapped: Comparable {
  public static func < (lhs: Optional<Wrapped>, rhs: Optional<Wrapped>) -> Bool {
    switch (lhs, rhs) {
    case let (.some(lhsWrapped), .some(rhsWrapped)):
      return lhsWrapped < rhsWrapped
    case (nil, .some):
      return true
    default:
      return false
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
