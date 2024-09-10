//
//  MeetingView.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import AmazonChimeSDK
import VideoToolbox

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
    @State private var videoViews: Array<VideoRenderViewRepresentable> = []
    @State private var videoRenderView: DefaultVideoRenderView = .init()
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
//            CustomRenderView(defaultRenderView: videoRenderView, meetingModel: meetingModel)
//            videoViews.first
            RenderViewWrapper(meetingModel: meetingModel)
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

//            videoViews.append(VideoRenderViewRepresentable(meetinModel: meetingModel))

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
//        meetingModel.bind(videoRenderView: videoViews.first?.makeUIView(context: ), tileId: 0)
    }
}

@available(iOS 15.0, *)
#Preview {
    MeetingView()
}

@available(iOS 15.0, *)
struct VideoRenderViewRepresentable: UIViewRepresentable {
    let imageView: UIImageView = UIImageView()
    let meetinModel: MeetingModel

    func makeUIView(context: Context) -> UIImageView {
        imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VideoRenderView {
        var parent: VideoRenderViewRepresentable

        init(_ parent: VideoRenderViewRepresentable) {
            self.parent = parent
//            self.parent.meetinModel.bind(videoRenderView: , tileId: 100)
        }

        func onVideoFrameReceived(frame: VideoFrame) {
            print("=== onVideoFrameReceived", frame)
            if Thread.isMainThread {
                renderFrame(frame: frame)
            } else {
                DispatchQueue.main.async {
                    self.renderFrame(frame: frame)
                }
            }
        }

        private func renderFrame(frame: VideoFrame) {
            guard let buffer = (frame.buffer as? VideoFramePixelBuffer)?.pixelBuffer else { return }
            var cgImage: CGImage?
            VTCreateCGImageFromCVPixelBuffer(buffer, options: nil, imageOut: &cgImage)
            guard let image = cgImage else { return }
            parent.imageView.image = UIImage(cgImage: image)
        }
    }
}

@available(iOS 15.0, *)
struct CustomRenderView: UIViewRepresentable {
    let defaultRenderView: DefaultVideoRenderView
    let meetingModel: MeetingModel?

    func updateUIView(_ uiView: UIView, context: Context) {
        print("=== CustomRenderView updateUIView")
    }

    func makeUIView(context: Context) -> UIView {
        print("=== CustomRenderView makeUIView")
        defaultRenderView.frame = CGRect(origin: .zero, size: .init(width: 200, height: 300))
        return defaultRenderView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject {
        let parent: CustomRenderView

        init(_ parent: CustomRenderView) {
            self.parent = parent
            parent.meetingModel?.bind(videoRenderView: parent.defaultRenderView, tileId: 1)
        }
    }
}

@available(iOS 15.0, *)
struct RenderViewWrapper: UIViewRepresentable {
    let meetingModel: MeetingModel?
    let renderView: DefaultVideoRenderView = .init()

    func updateUIView(_ uiView: UIViewType, context: Context) {
        meetingModel?.bind(videoRenderView: renderView, tileId: 200)
    }

    func makeUIView(context: Context) -> some UIView {
        renderView
    }
}


final class CustomMeetingViewController: UIViewController {
    var meetingModel: MeetingModel?

    // MARK: component
    private lazy var videoRenderView: DefaultVideoRenderView = {
        let view = DefaultVideoRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var endCallButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 20, y: 50, width: 100, height: 50)
        button.backgroundColor = .red
        button.setTitle("通話終了", for: .normal)
        button.addTarget(self, action: #selector(endCallButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var videoActiveButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 200, y: 50, width: 100, height: 50)
        button.backgroundColor = .red
        button.setTitle("Video", for: .normal)
        button.addTarget(self, action: #selector(videoActiveButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: Button action
    @objc private func endCallButtonTapped() {
        meetingModel?.endMeeting()
    }

    @objc private func videoActiveButtonTapped() {
        guard let meetingModel else { return }
        meetingModel.activeMode = .video
        meetingModel.videoModel.isLocalVideoActive = true
        videoRenderView.mirror = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let meetingModel else {
            dismiss(animated: true)
            return
        }
        configure(meetingModel: meetingModel)
        setupUI()
        meetingModel.startMeeting()
    }

    private func configure(meetingModel: MeetingModel) {
        meetingModel.isEndedHandler = { [weak meetingModel] in
            DispatchQueue.main.async {
                guard let meetingModel else { return }
                MeetingModule.shared().dismissMeeting(meetingModel)
            }
        }
        meetingModel.bind(videoRenderView: videoRenderView, tileId: 100)
    }

    private func setupUI() {
        view.addSubview(videoRenderView)
        view.addSubview(endCallButton)
        view.addSubview(videoActiveButton)
        videoRenderView.frame = view.frame
        NSLayoutConstraint.activate([
            videoRenderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoRenderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoRenderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoRenderView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        print("=== videoRenderView.frame", videoRenderView.frame)
        print("=== videoRenderView.isHidden", videoRenderView.isHidden)
    }
}
