//
//  VideoPanel.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/20/20.
//

import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct VideoPanel: View {
  @EnvironmentObject var appState: SubtitleEditorState
  @ObservedObject var videoSource: VideoSource

  @State var isChoosingVideo: Bool = false
  var chooseVideoButton: some View {
    Button {
      isChoosingVideo = true
    } label: {
      Label("Choose Video", systemImage: "folder")
    }
  }

  #if os(iOS)
  @State var isChoosingPhotosLibrary: Bool = false
  var chooseFromPhotosLibraryButton: some View {
    Button {
      isChoosingPhotosLibrary = true
    } label: {
      Label("Choose from Photos Library", systemImage: "photo.on.rectangle.angled")
    }
  }
  #endif

  var subtitle: some View {
    GeometryReader { geo in
      HStack {
        Spacer()
        VStack(spacing: 0) {
          Spacer()
          if let contents = appState.currentSegment?.contents.filter { !$0.isEmpty },
             !contents.isEmpty {
            ForEach(contents, id: \.self) {
              Text($0)
                .font(.system(size: geo.size.width / 1139 * 28))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.4))
                .cornerRadius(4)
            }
          }
        }
        Spacer()
      }
      .padding(.bottom, 20)
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
  }

  var crossPlatformVideoPlayer: some View {
    VideoPlayer(player: videoSource.avPlayer) {
      subtitle
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
    .onTapGesture {
      withAnimation {
        videoSource.isPlaying.toggle()
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        videoSource.isPlaying = true
      }
    }
    .onDisappear {
      videoSource.isPlaying = false
    }
    .fileImporter(isPresented: $isChoosingVideo, allowedContentTypes: [.movie]) { (result) in
      if let url = try? result.get() {
        videoSource.loadURL(url)
      }
    }
  }

  var videoPlayer: some View {
    #if os(iOS)
    return crossPlatformVideoPlayer
      .contextMenu {
        chooseFromPhotosLibraryButton
        chooseVideoButton
      }
      .sheet(isPresented: $isChoosingPhotosLibrary) {
        PhotosPicker(isPresented: $isChoosingPhotosLibrary) { url in
          DispatchQueue.main.async {
            videoSource.loadURL(url)
          }
        }
      }
    #else
    return crossPlatformVideoPlayer
      .contextMenu {
        chooseVideoButton
      }
    #endif
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

      Slider(value: $videoSource.currentTime._seconds, in: 0...videoSource.duration)

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

  var fullVideoControlPanel: some View {
    VStack(spacing: 8) {
      videoPlayer
      controlBar
      playbackBar
    }
  }

  #if os(iOS)
  @State var isShowingControls: Bool = true
  var videoControlPanel: some View {
    Group {
      if isShowingControls {
        fullVideoControlPanel
      } else {
        videoPlayer
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)) { _ in
      withAnimation {
        isShowingControls = false
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardDidHideNotification)) { _ in
      withAnimation {
        isShowingControls = true
      }
    }
  }
  #else
  var videoControlPanel: some View {
    fullVideoControlPanel
  }
  #endif

  var body: some View {
    VStack(spacing: 8) {
      Spacer()
      if videoSource.avPlayer != nil {
        videoControlPanel
          .onChange(of: videoSource.currentTime) { newValue in
            appState.currentTime = newValue
          }
      } else {
        #if os(iOS)
        HStack {
          Spacer()
          chooseFromPhotosLibraryButton
            .sheet(isPresented: $isChoosingPhotosLibrary) {
              PhotosPicker(isPresented: $isChoosingPhotosLibrary) { url in
                DispatchQueue.main.async {
                  videoSource.loadURL(url)
                }
              }
            }
          Spacer()
        }
        #endif
        HStack {
          Spacer()
          chooseVideoButton
            .fileImporter(isPresented: $isChoosingVideo, allowedContentTypes: [.movie]) { (result) in
              if let url = try? result.get() {
                videoSource.loadURL(url)
              }
            }
          Spacer()
        }
      }
      Spacer()
    }
    .onAppear {
      if let url = UserDefaults.standard
          .withSecurityScopedURL(forKey: "VIDEO_URL_BOOKMARK",
                                 autoScope: true, then: { $0 }) {
        videoSource.loadURL(url)
      }
    }
  }
}

struct VideoPanel_Previews: PreviewProvider {
  static var previews: some View {
    VideoPanel(videoSource: VideoSource())
  }
}
