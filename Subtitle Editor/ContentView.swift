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
import MobileCoreServices

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
    return GeometryReader { geo in
      VStack(spacing: 0) {
        Spacer()
        if !contents[0].isEmpty {
          Text(contents[0])
            .subtitleInContainer(ofSize: geo.size)
        }
        if !contents[1].isEmpty {
          Text(contents[1])
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
          .onStateChanged({ (state) in
            switch state {
            case .playing(totalDuration: let duration):
              self.videoDuration = duration
            default:
              break
            }
          })
          .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
        
        if currentIndex != nil {
          displaySubtitle(at: currentIndex!)
        }
      }
      
      HStack(spacing: 16) {
        Text(currentTime.seconds.hms)
        
        Slider(value: $currentTime.seconds, in: 0...videoDuration)
        
        Text(videoDuration.hms)
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
          .onTapGesture {
            self.isPlaying.toggle()
        }
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
              TextView(text: self.$subtitles.mutableSegments[segment.id - 1]._contents)
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
          tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: true)
        }
      }
      
      PickerButton(documentTypes: [kUTTypeData], onSelect: {
        if let subtitles = try? MutableSubtitle(url: $0) {
          self.subtitles = subtitles
          UserDefaults.standard.set($0, forKey: "SUB_URL")
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
      try? self.subtitles.write(to: UserDefaults.standard.url(forKey: "SUB_URL")!)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
