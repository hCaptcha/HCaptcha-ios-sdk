//
//  ContentView.swift
//  HCaptcha_SwiftUI_Example
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

import SwiftUI
import HCaptcha

// Wrapper-view to provide UIView instance
struct UIViewWrapperView: UIViewRepresentable {
    var uiview = UIView()

    func makeUIView(context: Context) -> UIView {
        uiview.backgroundColor = .gray
        return uiview
    }

    func updateUIView(_ view: UIView, context: Context) {
    }
}

// Example of hCaptcha usage
struct HCaptchaView: View {
    private(set) var hcaptcha: HCaptcha!

    let placeholder = UIViewWrapperView()

    var body: some View {
        VStack{
            placeholder.frame(width: 640, height: 640, alignment: .center)
            Button(
                "validate",
                action: {
                    hcaptcha.validate(on: placeholder.uiview) { result in
                        print(result)
                    }
                }
            ).padding()
        }
    }


    init() {
        hcaptcha = try? HCaptcha()
        let hostView = self.placeholder.uiview
        hcaptcha.configureWebView { webview in
            webview.frame = hostView.bounds
        }
    }
}
