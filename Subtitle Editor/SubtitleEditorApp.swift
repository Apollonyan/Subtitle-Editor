//
//  SubtitleEditorApp.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 8/18/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import SwiftUI

@main
struct SubtitleEditorApp: App {
  var body: some Scene {
    DocumentGroup(viewing: MutableSubtitle.self) { subtitle in
      ContentView(subtitles: subtitle.$document)
    }
  }
}

//
//let save = UIMenu(
//  title: "Save", identifier: .init(rawValue: "Save"),
//  options: .displayInline,
//  children: [
//    UIKeyCommand(title: "Save", image: nil, action: #selector(postSave), input: "S", modifierFlags: .command)
//])
