//
//  TamaraWebView.swift
//  Wishy
//
//  Created by Karim OTHMAN on 5.05.2025.
//

import SwiftUI
import WebKit

struct TamaraWebView: UIViewRepresentable {
    @ObservedObject var viewModel: TamaraWebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.webView
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false

        if let requestURL = URL(string: viewModel.url) {
            let request = URLRequest(url: requestURL)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var viewModel: TamaraWebViewModel

        init(viewModel: TamaraWebViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.isLoading = false

            guard let currentURL = webView.url?.absoluteString else { return }
            print("FINISHED: \(currentURL)")

            webView.evaluateJavaScript("window.location.href") { (result, error) in
                if let urlString = result as? String {
                    print("Evaluated JS URL: \(urlString)")
                }
            }

            if currentURL.contains("wishy.sa/tamara/success") {
                viewModel.result = .success
            } else if currentURL.contains("wishy.sa/tamara/failure") {
                viewModel.result = .failure
            } else if currentURL.contains("wishy.sa/tamara/cancel") {
                viewModel.result = .cancelled
            }
        }

//        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//            guard let url = navigationAction.request.url else {
//                decisionHandler(.allow)
//                return
//            }
//
//            let urlStr = url.absoluteString
//            print("Navigated to: \(urlStr)")
//
//            if urlStr.contains(viewModel.merchantURL.success) {
//                viewModel.result = .success
//                decisionHandler(.cancel)
//                return
//            }
//
//            if urlStr.contains(viewModel.merchantURL.failure) {
//                viewModel.result = .failure
//                decisionHandler(.cancel)
//                return
//            }
//
//            if urlStr.contains(viewModel.merchantURL.cancel) {
//                viewModel.result = .cancelled
//                decisionHandler(.cancel)
//                return
//            }
//
//            if urlStr.contains(viewModel.merchantURL.notification) {
//                viewModel.result = .notification
//                decisionHandler(.cancel)
//                return
//            }
//
//            decisionHandler(.allow)
//        }
    }
}
