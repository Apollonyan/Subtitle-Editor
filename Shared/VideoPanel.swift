//
//  VideoPanel.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/20/20.
//

import SwiftUI
import AVKit

fileprivate struct SubtitleStyle: ViewModifier {
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

struct VideoPanel: View {

  @ObservedObject var videoSource: VideoSource
  @Binding var currentSubtitle: MutableSubtitle.Segment?

  func displaySubtitle(at index: Int) -> some View {
    let contents = currentSubtitle!.contents
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
    VideoPlayer(player: videoSource.avPlayer) {
      if let index = currentIndex {
        displaySubtitle(at: index)
      }
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
    .onTapGesture {
      withAnimation {
        videoSource.isPlaying.toggle()
      }
    }
    .contextMenu {
      chooseVideoButton
    }
  }

  @State private var jumpTarget: String = ""
  @Namespace var vcpSpace
  var videoControlPanel: some View {
    VStack(spacing: 8) {
      videoPlayer

      HStack(spacing: 8) {
        if videoSource.isPlaying {
          Text(videoSource.currentTime.seconds.hms)
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
                  videoSource.currentTime._seconds = subtitles.segments[index].startTime
                }
              case 2...:
                let desired = segments
                  .reversed().enumerated()
                  .reduce(0) { $0 + pow(60, Double($1.0)) * $1.1 }
                videoSource.currentTime._seconds = min(max(desired, 0), videoSource.duration)
              default:
                break
              }
              jumpTarget = videoSource.currentTime.seconds.hms
            })
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(PlainTextFieldStyle())
            .fixedSize()
            .accessibilityLabeledPair(role: .content, id: "curTime", in: vcpSpace)
            .onAppear {
              jumpTarget = videoSource.currentTime.seconds.hms
            }
          }
          .matchedGeometryEffect(id: "curTime", in: vcpSpace,
                                 anchor: .leading, isSource: false)
        }

        Text("\(videoSource.desiredPlaybackRate.hundredths)x")
          .contextMenu {
            ForEach([0.5 as Float, 1, 1.5, 1.75, 2], id: \.self) { rate in
              Button("\(rate.hundredths)x") {
                videoSource.desiredPlaybackRate = rate
              }
            }
          }

        Slider(value: $videoSource.currentTime._seconds, in: 0...videoSource.duration)

        Text(videoSource.duration.hms)
          .font(.system(.body, design: .monospaced))
      }

      HStack(spacing: 32) {
        Button {
          videoSource.currentTime._seconds = max(0, videoSource.currentTime.seconds - 15)
        } label: {
          Image(systemName: "gobackward.15")
            .font(.title)
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(videoSource.currentTime.seconds < 5)

        Button {
          withAnimation {
            videoSource.isPlaying.toggle()
          }
        } label: {
          Image(systemName: videoSource.isPlaying
                  ? "pause.rectangle.fill"
                  : "play.rectangle.fill")
            .font(.largeTitle)
        }
        .buttonStyle(BorderlessButtonStyle())

        Button {
          videoSource.currentTime._seconds = min(videoSource.duration, videoSource.currentTime.seconds + 15)
        } label: {
          Image(systemName: "goforward.15")
            .font(.title)
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(videoSource.currentTime.seconds + 5 > videoSource.duration)
      }
    }
  }

  var body: some View {
      Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
  }
}

struct VideoPanel_Previews: PreviewProvider {
    static var previews: some View {
        VideoPanel()
    }
}
