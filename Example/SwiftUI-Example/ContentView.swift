//
//  ContentView.swift
//  HCaptcha_SwiftUI_Example
//
//  Copyright © 2024 HCaptcha. MIT License.
//

import SwiftUI
import HCaptcha

// Wrapper-view to provide UIView instance
struct UIViewWrapperView: UIViewRepresentable {
    var uiView = UIView()

    func makeUIView(context: Context) -> UIView {
        uiView.backgroundColor = .gray
        return uiView
    }

    func updateUIView(_ view: UIView, context: Context) {
        // nothing to update
    }
}

class HCaptchaViewModel: ObservableObject {
    let hcaptcha: HCaptcha!

    init() {
        self.hcaptcha = try? HCaptcha()
    }

    func configure(_ hostView: UIViewWrapperView) {
        hcaptcha.configureWebView { webview in
            webview.frame = hostView.uiView.bounds
        }
        hcaptcha.onEvent { (event, _) in
            print("HCaptcha onEvent \(event.rawValue)")
        }
    }

    func validate(_ hostView: UIViewWrapperView) {
        hcaptcha.validate(on: hostView.uiView) { result in
            print("HCaptcha result \(try? result.dematerialize())")
        }
    }
}

// Example of hCaptcha usage
struct HCaptchaView: View {
    @StateObject var model = HCaptchaViewModel()
    let placeholder = UIViewWrapperView()

    var body: some View {
        VStack{
            placeholder.frame(width: 640, height: 640, alignment: .center)
            Button(
                "validate",
                action: { model.validate(placeholder) }
            ).padding()
        }
        .onAppear {
            model.configure(placeholder)
        }
    }
}
