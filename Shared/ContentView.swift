//
//  ContentView.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI
import AVKit
import AVFoundation
import srt
import tidysub

struct SubtitleStyle: ViewModifier {
  var containerSize: CGSize

  func body(content: Content) -> some View {
    content
      .font(.system(size: containerSize.width / 1139 * 28))
      .foregroundColor(.white)
      .padding(.horizontal, 16)
      .background(Color.black.opacity(0.4))
      .cornerRadius(4)
  }
}

struct ContentView: View {
  public init(subtitles: Binding<MutableSubtitle>) {
    _subtitles = subtitles
  }
  @Binding public var subtitles: MutableSubtitle

  @State private var isPlaying: Bool = true
  @State private var currentTime: CMTime = .zero
  @State private var playbackRate: Float = 1
  @State private var videoDuration: TimeInterval = 0
  @State private var videoURL: URL? = UserDefaults.standard
  .withSecurityScopedURL(forKey: "VIDEO_URL_BOOKMARK", autoScope: false, then: {
    _ = $0?.startAccessingSecurityScopedResource()
    return $0
  }) {
    didSet {
      oldValue?.stopAccessingSecurityScopedResource()
    }
  }
  @State private var jumpTarget: String = ""

  private var currentIndex: Int? {
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
      HStack {
        Spacer()
        VStack(spacing: 0) {
          Spacer()
          ForEach(contents, id: \.self) {
            Text($0)
              .modifier(SubtitleStyle(containerSize: geo.size))
          }
        }
        Spacer()
      }
      .padding(.bottom, 20)
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
  }

  var videoPlayer: some View {
    /*
     url: videoURL!,
     play: $isPlaying,
     time: $currentTime,
     rate: $playbackRate
     videoDuration = duration
     */
    VideoPlayer(player: AVPlayer(url: videoURL!)) {
      if let index = currentIndex {
        displaySubtitle(at: index)
      }
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
    .onTapGesture {
      withAnimation {
        isPlaying.toggle()
      }
    }
    .contextMenu {
      chooseVideoButton
    }
  }

  @Namespace var vcpSpace
  var videoControlPanel: some View {
    VStack(spacing: 8) {
      videoPlayer

      HStack(spacing: 8) {
        if isPlaying {
          Text(currentTime.seconds.hms)
            .font(.system(.body, design: .monospaced))
            .matchedGeometryEffect(id: "curTime", in: vcpSpace, isSource: false)
        } else {
          HStack {
            Image(systemName: "signpost.right.fill")
              .accessibilityLabel("Jump to")
              .accessibilityLabeledPair(role: .label, id: "curTime", in: vcpSpace)
            TextField("time/segment", text: $jumpTarget, onCommit: {
              let segments = jumpTarget
                .components(separatedBy: ":")
                .compactMap(Double.init)
              switch segments.count {
              case 1:
                let index = Int(segments[0]) - 1
                if subtitles.segments.indices.contains(index) {
                  currentTime._seconds = subtitles.segments[index].startTime
                }
              case 2...:
                let desired = segments
                  .reversed().enumerated()
                  .reduce(0) { $0 + pow(60, Double($1.0)) * $1.1 }
                currentTime._seconds = min(max(desired, 0), videoDuration)
              default:
                break
              }
              jumpTarget = currentTime.seconds.hms
            })
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(PlainTextFieldStyle())
            .fixedSize()
            .accessibilityLabeledPair(role: .content, id: "curTime", in: vcpSpace)
            .onAppear {
              jumpTarget = currentTime.seconds.hms
            }
          }
          .matchedGeometryEffect(id: "curTime", in: vcpSpace,
                                 anchor: .leading, isSource: false)
        }

        Text("\(playbackRate.hundredths)x")
          .contextMenu {
            ForEach([0.5 as Float, 1, 1.5, 1.75, 2], id: \.self) { rate in
              Button("\(rate.hundredths)x") {
                playbackRate = rate
              }
            }
          }

        Slider(value: $currentTime._seconds, in: 0...videoDuration)

        Text(videoDuration.hms)
          .font(.system(.body, design: .monospaced))
      }

      HStack(spacing: 32) {
        Button {
          currentTime._seconds = max(0, currentTime.seconds - 15)
        } label: {
          Image(systemName: "gobackward.15")
            .font(.title)
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(currentTime.seconds < 5)

        Button {
          withAnimation {
            isPlaying.toggle()
          }
        } label: {
          Image(systemName: isPlaying ? "pause.rectangle.fill" : "play.rectangle.fill")
            .font(.largeTitle)
        }
        .buttonStyle(BorderlessButtonStyle())

        Button {
          currentTime._seconds = min(videoDuration, currentTime.seconds + 15)
        } label: {
          Image(systemName: "goforward.15")
            .font(.title)
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(currentTime.seconds + 5 > videoDuration)
      }
    }
  }
  
  var subtitleEditorPanel: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if !subtitles.mutableSegments.isEmpty {
          LazyVStack {
            ForEach(subtitles.mutableSegments) { segment in
              HStack(spacing: 8) {
                HStack {
                  Text(String(format: "%-4d", segment.id))
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(currentIndex == segment.id - 1
                                      ? .white
                                      : .secondary)
                  /*
                   VStack {
                   Text(SRT.Segment.timestamp(from: segment.startTime))
                   .foregroundColor(.gray)
                   Text(SRT.Segment.timestamp(from: segment.endTime))
                   .foregroundColor(.gray)
                   }
                   */
                }
                .padding(.leading, 8)
                VStack {
                  TextEditor(text: $subtitles.mutableSegments[segment.id - 1]._contents)
                    .foregroundColor(segment.contents.reduce(segment.contents.count > 2 ? .red : nil) {
                      (previousColor, currentLine) in
                      switch format(currentLine).displayWidth {
                      case ...36:
                        return previousColor
                      case ..<40 where previousColor < .purple:
                        return .purple
                      case ..<46 where previousColor < .orange:
                        return .orange
                      default:
                        return .red
                      }
                    })
                    .fixedSize(horizontal: false, vertical: true)
                }
              }
              .onTapGesture {
                currentTime._seconds = segment.startTime
              }
              .background(currentIndex == segment.id - 1
                            ? Color.accentColor.cornerRadius(8)
                            : nil)
            }
          }
          .listStyle(PlainListStyle())
          .onChange(of: currentTime) { [oldIndex = currentIndex ?? 0] _ in
            guard let index = currentIndex, index != oldIndex else { return }
            let targetID = subtitles.mutableSegments[index].id
            if abs(index - oldIndex) < 10 {
              withAnimation(.easeOut) {
                proxy.scrollTo(targetID, anchor: .center)
              }
            } else {
              proxy.scrollTo(targetID, anchor: .center)
            }
          }
        }
      }
    }
  }

  var chooseVideoButton: some View {
    PickerButton(documentTypes: [.movie]) { url in
      #if os(macOS)
      UserDefaults.standard
        .set(try? url.bookmarkData(options: .withSecurityScope),
             forKey: "VIDEO_URL_BOOKMARK")
      #endif
      DispatchQueue.main.async {
        videoURL = url
      }
    } label: {
      Text("Choose Video")
    }
  }

  var videoArea: some View {
    VStack {
      Spacer()
      if videoURL != nil {
        videoControlPanel
      } else {
        HStack {
          Spacer()
          chooseVideoButton
          Spacer()
        }
      }
      Spacer()
    }
  }

  #if os(iOS)
  @Environment(\.horizontalSizeClass) private var hSizeClass
  var body: some View {
    GeometryReader { geo in
      if hSizeClass == .compact || geo.size.height > geo.size.width {
        VStack(spacing: 8) {
          videoArea
          subtitleEditorPanel
        }
        .padding()
      } else {
        HStack(spacing: 16) {
          videoArea
          subtitleEditorPanel
            .frame(idealWidth: max(geo.size.width * 0.3, 500),
                   idealHeight: geo.size.height)
            .fixedSize()
        }
        .padding()
      }
    }
  }
  #else
  var body: some View {
    GeometryReader { geo in
      if geo.size.height > geo.size.width {
        VSplitView {
          videoArea
            .padding()
          subtitleEditorPanel
            .padding()
        }
      } else {
        HSplitView {
          videoArea
            .padding()
          subtitleEditorPanel
            .padding()
        }
      }
    }
  }
  #endif
}

extension Color: Comparable {
  public static func < (lhs: Color, rhs: Color) -> Bool {
    switch (lhs, rhs) {
    case let (x, y) where x == y:
      return false
    case (_, .red):
      return true
    case (_, .orange):
      return true
    case (_, .purple):
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
    ContentView(
      subtitles: .constant(
        MutableSubtitle(mutableSegments: [
          .init(id: 1, startTime: 0, endTime: 0, _contents: "Hello"),
          .init(id: 1234, startTime: 0, endTime: 0, _contents: """
              Very Long
              Very good
              """
          )
        ])
      )
    )
  }
}
