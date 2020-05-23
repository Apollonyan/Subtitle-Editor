//
//  ContentView.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI
import VideoPlayer
import AVFoundation
import srt
import Introspect

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
  @State private var totalDuration: TimeInterval = 0
  @State private var videoURL: URL? = UserDefaults.standard.url(forKey: "VIDEO_URL") {
    didSet {
      UserDefaults.standard.set(videoURL, forKey: "VIDEO_URL")
    }
  }
  @State private var subtitles: MutableSubtitle =
    UserDefaults.standard.url(forKey: "SUB_URL")
      .flatMap { try? MutableSubtitle.init(url: $0) }
      ?? MutableSubtitle.init(segments: [])

  var currentIndex: Int? {
    let index = _currentIndex.intValue
    let currentTimeSec = currentTime.seconds

    quickCheck: if index < subtitles.segments.count {
      if subtitles.segments[index].contains(currentTimeSec) {
        return index
      }
      let nextIndex = index + 1
      if nextIndex == subtitles.segments.count {
        break quickCheck
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
    return subtitles.indexOf(currentTimeSec)
  }
  private var _currentIndex = IntRef(0)


  func displaySubtitle(at index: Int) -> some View {
    GeometryReader { geo in
      VStack(spacing: 0) {
        Spacer()
        Text(self.subtitles.segments[index].contents[0])
          .subtitleInContainer(ofSize: geo.size)
        Text(self.subtitles.segments[index].contents[1])
          .subtitleInContainer(ofSize: geo.size)
      }
      .padding(.bottom, 20)
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
  }

  var videoPlayer: some View {
    VStack {
      ZStack {
        VideoPlayer(url: videoURL!, play: $isPlaying, time: $currentTime)
          .onStateChanged({ (state) in
            switch state {
            case .playing(totalDuration: let totalDuration):
              self.totalDuration = totalDuration
            default:
              break
            }
          })
          .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)

        if currentIndex != nil {
          displaySubtitle(at: currentIndex!)
        }
      }
      HStack {
        Text(currentTime.seconds.hms)
        Slider(value: $currentTime.seconds, in: 0...totalDuration)
        Text(totalDuration.hms)
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
                .font(.system(.title))
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
              TextField("", text: self.$subtitles.mutableSegments[segment.id - 1].contents[0])
              TextField("", text: self.$subtitles.mutableSegments[segment.id - 1].contents[1])
            }
          }
          .padding(.vertical, 8)
          .background(self.currentIndex == segment.id - 1 ? Color.yellow.opacity(0.5) : nil)
        }
        .introspectTableView { (tableView) in
          tableView.separatorStyle = .none
          guard let row = self.currentIndex else { return }
          tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: true)
        }
      }

      PickerButton(documentTypes: [kUTTypeData], onSelect: {
        if let subtitles = try? MutableSubtitle(url: $0) {
          self.subtitles = subtitles
          UserDefaults.standard.set($0, forKey: "SUB_URL")
        }
      }, label: {
        Text("Choose Subtitle")
      })
    }
  }

  var body: some View {
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

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
