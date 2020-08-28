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
  @EnvironmentObject var appState: SubtitleEditorState
  @ObservedObject var videoSource = VideoSource()

  var chooseVideoButton: some View {
      PickerButton(documentTypes: [.movie]) { url in
        videoSource.loadURL(url)
      } label: {
        Text("Choose Video")
      }
    }

  var videoPlayer: some View {
    VideoPlayer(player: videoSource.avPlayer) {
      GeometryReader { geo in
        HStack {
          Spacer()
          VStack(spacing: 0) {
            Spacer()
            if let contents = appState.currentSegment?.contents.filter { !$0.isEmpty },
               !contents.isEmpty {
              ForEach(contents, id: \.self) {
                Text($0)
                  .modifier(SubtitleStyle(containerSize: geo.size))
              }
            }
          }
          Spacer()
        }
        .padding(.bottom, 20)
      }
      .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
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
  var controlBar: some View {
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
            guard let target = appState.timeInterval(for: jumpTarget) else { return }
            videoSource.currentTime._seconds = min(max(target, 0), videoSource.duration)
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

      Text(videoSource.duration.hms)
        .font(.system(.body, design: .monospaced))
    }
  }

  var playbackBar: some View {
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

  var videoControlPanel: some View {
    VStack(spacing: 8) {
      videoPlayer
      controlBar
      playbackBar
    }
  }

  var body: some View {
    VStack {
      Spacer()
      if videoSource.avPlayer != nil {
        videoControlPanel
          .onChange(of: videoSource.currentTime) { newValue in
            appState.currentTime = newValue
          }
      } else {
        HStack {
          Spacer()
          chooseVideoButton
          Spacer()
        }
      }
      Spacer()
    }
    .onAppear {
      if let url = UserDefaults.standard
          .withSecurityScopedURL(forKey: "VIDEO_URL_BOOKMARK",
                                 autoScope: false, then: { $0 }) {
        videoSource.loadURL(url)
      }
    }
  }
}

struct VideoPanel_Previews: PreviewProvider {
    static var previews: some View {
        VideoPanel()
    }
}
