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
struct VideoTileView: View {
    var body: some View {
        Image("callkit-icon")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(8)
            .padding(.all, 3)
    }
}

@available(iOS 15.0, *)
struct MeetingView: View {
    @State private var selectedSegment: ActiveMode = .attendees
    @State private var items: [String] = ["aaa", "bbb", "ccc", "ddd"]
    private let meetingModel: MeetingModel?

    init(meetingModel: MeetingModel? = nil) {
        self.meetingModel = meetingModel
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
            GeometryReader { geometry in
                let columns: [GridItem] = items.count == 1
                ? [GridItem(.flexible())]
                : Array(repeating: GridItem(.flexible(), spacing: 0), count: 2)
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        VideoTileView()
                            .frame(
                                width: items.count == 1 ? geometry.size.width : geometry.size.width / 2,
                                height: items.count == 1 ? geometry.size.height : geometry.size.height / 2
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color.red)
            HStack {
                ForEach(BottomControl.allCases) { item in
                    Spacer()
                    Button {
                        switch item {
                        case .mic:
                            print("===: tapped mic")
                        case .speaker:
                            print("===: tapped speaker")
                        case .video:
                            print("===: tapped video")
                        case .phone:
                            print("===: tapped phone")
                            meetingModel?.endMeeting()
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
        .onAppear {
            guard let meetingModel else { return }
            configure(meetingModel: meetingModel)
            meetingModel.startMeeting()
        }
    }

    private func configure(meetingModel: MeetingModel) {
        meetingModel.isEndedHandler = { [weak meetingModel] in
            DispatchQueue.main.async {
                guard let meetingModel else { return }
                MeetingModule.shared().dismissMeeting(meetingModel)
            }
        }
    }
}

@available(iOS 15.0, *)
#Preview {
    MeetingView()
}
