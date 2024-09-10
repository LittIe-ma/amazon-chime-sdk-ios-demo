//
//  AppConfiguration.swift
//  AmazonChimeSDKDemo
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AppConfiguration {
    // nglockだと毎回URL変わるから都度差し替える
    static let url = "https://c701-240f-c1-95ed-1-300e-a55e-bf4a-1544.ngrok-free.app/"
    static let region = "ap-northeast-1"
    static let broadcastBundleId = "YOUR_BROADCAST_BUNDLE_ID"
    static let appGroupId = "YOUR_APP_GROUP_ID"
}
