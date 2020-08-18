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
    ZStack {
      VideoPlayer(url: videoURL!, play: $isPlaying, time: $currentTime, rate: $playbackRate)
        .onStateChanged { (state) in
          switch state {
          case .playing(totalDuration: let duration):
            videoDuration = duration
          case .error(let error):
            dump(error)
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
      isPlaying.toggle()
    }
  }
  
  var videoControlPanel: some View {
    VStack {
      videoPlayer

      HStack(spacing: 16) {
        Text(currentTime.seconds.hms)

        Text("\(playbackRate.hundredths)x")
          .contextMenu {
            ForEach(Array(stride(from: 0.5, through: Float(2), by: 0.5)), id: \.self) { rate in
              Button(action: { playbackRate = rate }) {
                Text("\(rate.hundredths)x")
              }
            }
          }

        Slider(value: $currentTime.seconds, in: 0...videoDuration)

        Text(videoDuration.hms)
      }

      HStack {
        Text("Jump to: ")
        TextField("time/segment", text: $jumpTarget) {
          let segments = jumpTarget
            .components(separatedBy: ":")
            .compactMap(Double.init)
          switch segments.count {
          case 1:
            let index = Int(segments[0]) - 1
            if subtitles.segments.indices.contains(index) {
              currentTime.seconds = subtitles.segments[index].startTime
            }
          case 2...:
            let desired = segments
              .reversed().enumerated()
              .reduce(0) { $0 + pow(60, Double($1.0)) * $1.1 }
            currentTime.seconds = min(max(desired, 0), videoDuration)
          default:
            break
          }
          jumpTarget = ""
        }
      }

      HStack(alignment: .lastTextBaseline, spacing: 32) {
        Button(action: {
          currentTime.seconds = max(0, currentTime.seconds - 15)
        }) {
          Image(systemName: "gobackward.15")
            .font(.title)
        }
        .disabled(currentTime.seconds < 5)

        Button(action: {
          isPlaying.toggle()
        }) {
          Image(systemName: isPlaying ? "pause.rectangle.fill" : "play.rectangle.fill")
            .font(.largeTitle)
        }

        Button(action: {
          currentTime.seconds = min(videoDuration, currentTime.seconds + 15)
        }) {
          Image(systemName: "goforward.15")
            .font(.title)
        }
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
                    text: $subtitles.mutableSegments[segment.id - 1]._contents,
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
                currentTime.seconds = segment.startTime
              }
              .background(currentIndex == segment.id - 1 ? Color.yellow.opacity(0.5) : nil)
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

  var videoArea: some View {
    Group {
      if videoURL != nil {
        videoControlPanel
      } else {
        VStack {
          Spacer()
          HStack {
            Spacer()
            PickerButton(documentTypes: [.movie], onSelect: { url in
              UserDefaults.standard
                .set(try? url.bookmarkData(options: .withSecurityScope),
                     forKey: "VIDEO_URL_BOOKMARK")
              DispatchQueue.main.async {
                videoURL = url
              }
            }, label: {
              Text("Choose Video")
            })
            Spacer()
          }
          Spacer()
        }
      }
    }
  }

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  var body: some View {
    Group {
      if horizontalSizeClass == .compact {
        VStack {
          videoArea
          subtitleEditorPanel
        }
      } else {
        GeometryReader { geo in
          HStack {
            videoArea
            subtitleEditorPanel
              .frame(idealWidth: max(geo.size.width * 0.3, 500), idealHeight: geo.size.height)
              .fixedSize()
          }
        }
        .padding()
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
    ContentView(subtitles: .constant(MutableSubtitle(segments: [])))
  }
}
