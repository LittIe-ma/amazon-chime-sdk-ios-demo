//
//  MeetingView.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

enum ActiveMode: String, CaseIterable, Identifiable {
  var id: String { rawValue }

  case attendees, chat, video
}

@available(iOS 15.0, *)
enum BottomControl: CaseIterable, Identifiable {
  var id: Self { self }

  case mic, speaker, video, phone

  var symbolName: String {
    switch self {
    case .mic: return "mic"
    case .speaker: return "speaker.wave.2"
    case .video: return "video"
    case .phone: return "phone.down"
    }
  }
}

@available(iOS 15.0, *)
struct MeetingView: View {
  @State private var selectedSegment: ActiveMode = .attendees

  init() {
    let appearance = UISegmentedControl.appearance()
    let font = UIFont.boldSystemFont(ofSize: 12)
    appearance.selectedSegmentTintColor = .gray
    appearance.backgroundColor = .darkGray.withAlphaComponent(0.75)
    appearance.setTitleTextAttributes([.font: font, .foregroundColor: UIColor.white], for: .normal)
    appearance.setTitleTextAttributes([.font: font, .foregroundColor: UIColor.white], for: .selected)
  }

  var body: some View {
    VStack {
      Picker("", selection: $selectedSegment) {
        ForEach(ActiveMode.allCases) {
          Text($0.rawValue).tag($0)
        }
      }
      .pickerStyle(.segmented)
      .padding()
      Spacer()
      HStack {
        ForEach(BottomControl.allCases) { item in
          Spacer()
          Button {
            switch item {
            case .mic:
              print("debugprint: tapped mic")
            case .speaker:
              print("debugprint: tapped speaker")
            case .video:
              print("debugprint: tapped video")
            case .phone:
              print("debugprint: tapped phone")
            }
          } label: {
            Image(systemName: item.symbolName)
              .resizable()
              .frame(width: 24, height: 24)
              .foregroundColor(.white)
          }
          Spacer()
        }
      }
    }
    .background(Color.black)
  }
}

@available(iOS 15.0, *)
#Preview {
  MeetingView()
}
