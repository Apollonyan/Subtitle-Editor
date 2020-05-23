//
//  Utils.swift
//  Subtitle Editor
//
//  Created by Apollo Zhu on 5/23/20.
//  Copyright © 2020 Apollonyan. All rights reserved.
//

import AVFoundation

extension CMTime {
  var seconds: TimeInterval {
    get {
      return CMTimeGetSeconds(self)
    }
    set {
      self = CMTimeMakeWithSeconds(newValue,
                                   preferredTimescale: timescale)
    }
  }
}

import subtitle

extension TimeInterval {
  var hms: String {
    let (h, m, s, _) = timestamp(from: self)
    return String(format: "%02d:%02d:%02d", h, m, s)
  }
}
