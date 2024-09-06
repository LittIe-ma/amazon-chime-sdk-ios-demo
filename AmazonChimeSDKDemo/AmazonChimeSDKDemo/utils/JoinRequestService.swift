//
//  JoinRequestService.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import AmazonChimeSDK
import Foundation

class JoinRequestService: NSObject {
    static let logger = ConsoleLogger(name: "JoiningRequestService")

    static func postJoinRequest(meetingId: String,
                                name: String,
                                overriddenEndpoint: String,
                                primaryExternalMeetingId: String,
                                completion: @escaping (JoinMeetingResponse?) -> Void) {
        var url = overriddenEndpoint.isEmpty ? AppConfiguration.url : overriddenEndpoint
        url = url.hasSuffix("/") ? url : "\(url)/"
//        let primaryExternalMeetingIdQueryParam = primaryExternalMeetingId.isEmpty ? "" : "&primaryExternalMeetingId=\(primaryExternalMeetingId)"
        let encodedURL = HttpUtils.encodeStrForURL(
            str: "\(url)join"
        )
//        print("=== encodedURL", encodedURL)
        let parameters: [String: Any] = [
            "title": meetingId,
            "attendeeName": name,
            "region": AppConfiguration.region,
            "ns_es": false
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)

        HttpUtils.postRequest(url: encodedURL, jsonData: jsonData, logger: logger) { data, error in
            print("=== HttpUtils.postRequest error", error as Any, "data", data as Any)
            let json = try! JSONSerialization.jsonObject(with: data ?? Data(), options: []) as! [String: Any]
            print("=== json", json)
            guard let data = data else {
                completion(nil)
                return
            }
            guard let joinMeetingResponse = self.processJson(data: data) else {
                completion(nil)
                return
            }
            print("=== completion", joinMeetingResponse)
            completion(joinMeetingResponse)
        }
    }

    private static func processJson(data: Data) -> JoinMeetingResponse? {
        let jsonDecoder = JSONDecoder()
        do {
            let joinMeetingResponse = try jsonDecoder.decode(JoinMeetingResponse.self, from: data)
            return joinMeetingResponse
        } catch let DecodingError.dataCorrupted(context) {
            logger.error(msg: "Data corrupted: \(context)")
            return nil
        } catch let DecodingError.keyNotFound(key, context) {
            logger.error(msg: "Key '\(key)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            return nil
        } catch let DecodingError.valueNotFound(value, context) {
            logger.error(msg: "Value '\(value)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            logger.error(msg: "Type '\(type)' mismatch: \(context.debugDescription), codingPath: \(context.codingPath)")
            return nil
        } catch {
            logger.error(msg: "Other decoding error: \(error)")
            return nil
        }
    }

    static func getCreateMeetingResponse(from joinMeetingResponse: JoinMeetingResponse) -> CreateMeetingResponse {
        let meeting = joinMeetingResponse.joinInfo.meeting
        let meetingResp = CreateMeetingResponse(meeting:
            Meeting(
                externalMeetingId: meeting.externalMeetingId,
                mediaPlacement: MediaPlacement(
                    audioFallbackUrl: meeting.mediaPlacement.audioFallbackUrl ?? "",
                    audioHostUrl: meeting.mediaPlacement.audioHostUrl,
                    signalingUrl: meeting.mediaPlacement.signalingUrl,
                    turnControlUrl: meeting.mediaPlacement.turnControlUrl ?? "",
                    eventIngestionUrl: meeting.mediaPlacement.eventIngestionUrl
                ),
                meetingFeatures: MeetingFeatures(
                    video: meeting.meetingFeatures?.video?.maxResolution,
                    content: meeting.meetingFeatures?.content?.maxResolution
                ),
                mediaRegion: meeting.mediaRegion,
                meetingId: meeting.meetingId,
                primaryMeetingId: meeting.primaryMeetingId
            )
        )
        return meetingResp
    }

    static func getCreateAttendeeResponse(from joinMeetingResponse: JoinMeetingResponse) -> CreateAttendeeResponse {
        let attendee = joinMeetingResponse.joinInfo.attendee
        let attendeeResp = CreateAttendeeResponse(attendee:
            Attendee(attendeeId: attendee.attendeeId,
                     externalUserId: attendee.externalUserId,
                     joinToken: attendee.joinToken)
        )
        return attendeeResp
    }
}
