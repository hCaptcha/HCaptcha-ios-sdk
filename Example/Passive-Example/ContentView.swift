//
//  ContentView.swift
//  HCaptcha_PassiveExample
//
//  Copyright © 2024 HCaptcha. MIT License.
//

import SwiftUI
import HCaptcha

struct ContentView: View {
    @State private var token: String?
    @State private var isLoading = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                Text(token ?? "no token")
            }

            Button("Validate", action: {
                isLoading = true
                Task {
                    token = await fetchHCaptchaToken()
                    isLoading = false
                }
            }).padding()
        }
    }

    func fetchHCaptchaToken() async -> String? {
        let config = HCaptchaConfig(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                    baseURL: URL(string: "http://localhost")!)
        config.passiveApiKey = true
        config.diagnosticLog = true

        guard let hcaptcha = try? HCaptcha(config: config) else { return "init error" }

        return await withCheckedContinuation { continuation in
            hcaptcha.validate { result in
                do {
                    let result = try result.dematerialize()
                    continuation.resume(returning: result)
                } catch let error {
                    continuation.resume(returning: error.localizedDescription)
                }
            }
        }
    }
}
