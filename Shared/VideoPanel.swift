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
    VideoPlayer(player: appState.avPlayer) {
      subtitle
    }
    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
    .onTapGesture {
      withAnimation {
        appState.isPlaying.toggle()
      }
    }
    .fileImporter(isPresented: $isChoosingVideo, allowedContentTypes: [.movie]) { (result) in
      if let url = try? result.get() {
        appState.loadURL(url)
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
            appState.loadURL(url)
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
  var jumpControl: some View {
    HStack {
      Image(systemName: "signpost.right.fill")
        .accessibilityLabel("Jump to")
        .accessibilityLabeledPair(role: .label, id: "curTime", in: vcpSpace)
      TextField("time/segment", text: $jumpTarget, onCommit: {
        guard let target = appState.timeInterval(for: jumpTarget) else { return }
        appState.currentTime._seconds = min(max(target, 0), appState.duration)
        jumpTarget = appState.currentTime.seconds.hms
      })
      .font(.system(.body, design: .monospaced))
      .textFieldStyle(PlainTextFieldStyle())
      .fixedSize()
      .accessibilityLabeledPair(role: .content, id: "curTime", in: vcpSpace)
      .onAppear {
        jumpTarget = appState.currentTime.seconds.hms
      }
    }
    .matchedGeometryEffect(id: "curTime", in: vcpSpace,
                           anchor: .leading)
  }

  @Namespace var vcpSpace
  var controlBar: some View {
    HStack(spacing: 8) {
      if appState.isPlaying {
        Text(appState.currentTime.seconds.hms)
          .font(.system(.body, design: .monospaced))
          .lineLimit(1)
          .matchedGeometryEffect(id: "curTime", in: vcpSpace, isSource: false)
      } else {
        jumpControl
      }

      Text("\(appState.desiredPlaybackRate.hundredths)x")
        .contextMenu {
          ForEach([0.5 as Float, 1, 1.5, 1.75, 2], id: \.self) { rate in
            Button("\(rate.hundredths)x") {
              appState.desiredPlaybackRate = rate
            }
          }
        }

      Slider(value: $appState.currentTime._seconds, in: 0...appState.duration)

      Text(appState.duration.hms)
        .font(.system(.body, design: .monospaced))
        .lineLimit(1)
        .layoutPriority(1)
    }
  }

  var playbackBar: some View {
    HStack(spacing: 32) {
      Button {
        appState.currentTime._seconds = max(0, appState.currentTime.seconds - 15)
      } label: {
        Image(systemName: "gobackward.15")
          .font(.title)
      }
      .buttonStyle(BorderlessButtonStyle())
      .disabled(appState.currentTime.seconds < 5)

      Button {
        withAnimation {
          appState.isPlaying.toggle()
        }
      } label: {
        Image(systemName: appState.isPlaying
                ? "pause.rectangle.fill"
                : "play.rectangle.fill")
          .font(.largeTitle)
      }
      .buttonStyle(BorderlessButtonStyle())

      Button {
        appState.currentTime._seconds = min(appState.duration, appState.currentTime.seconds + 15)
      } label: {
        Image(systemName: "goforward.15")
          .font(.title)
      }
      .buttonStyle(BorderlessButtonStyle())
      .disabled(appState.currentTime.seconds + 5 > appState.duration)
    }
  }

  var fullVideoControlPanel: some View {
    VStack(spacing: 8) {
      videoPlayer
      controlBar
      playbackBar
    }
  }

  /*
  #if os(iOS)
  @State var isShowingControls: Bool = true
  var videoControlPanel: some View {
    Group {
      if isShowingControls {
        fullVideoControlPanel
      } else {
        VStack(spacing: 8) {
          videoPlayer
          jumpControl
        }
      }
    }
    .onReceive(NotificationCenter.default
                .publisher(for: UIApplication.keyboardWillShowNotification)) { _ in
      withAnimation {
        isShowingControls = false
      }
    }
    .onReceive(NotificationCenter.default
                .publisher(for: UIApplication.keyboardDidHideNotification)) { _ in
      withAnimation {
        isShowingControls = true
      }
    }
  }
  #else
 */
  var videoControlPanel: some View {
    fullVideoControlPanel
  }
//  #endif

  var body: some View {
    VStack(spacing: 8) {
      Spacer()
      if appState.avPlayer != nil {
        videoControlPanel
      } else {
        #if os(iOS)
        HStack {
          Spacer()
          chooseFromPhotosLibraryButton
            .sheet(isPresented: $isChoosingPhotosLibrary) {
              PhotosPicker(isPresented: $isChoosingPhotosLibrary) { url in
                DispatchQueue.main.async {
                  appState.loadURL(url)
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
                appState.loadURL(url)
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
        appState.loadURL(url)
      }
    }
  }
}

struct VideoPanel_Previews: PreviewProvider {
  static var previews: some View {
    VideoPanel()
      .environmentObject(SubtitleEditorState())
  }
}
