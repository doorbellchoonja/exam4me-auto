import SwiftUI
import WebKit

@main
struct Exam4meApp: App {
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            if !hasAgreedToTerms {
                TermsView(hasAgreed: $hasAgreedToTerms)
            } else if isLoading {
                LoadingView(isLoading: $isLoading)
            } else {
                ContentView()
            }
        }
    }
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.15))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}

struct DynamicBackground: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            Circle()
                .fill(Color.blue.opacity(0.4))
                .blur(radius: 80)
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.4))
                .blur(radius: 80)
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 200)
                
            Circle()
                .fill(Color.cyan.opacity(0.3))
                .blur(radius: 80)
                .frame(width: 250, height: 250)
                .offset(x: -50, y: 400)
        }
    }
}

struct LoadingView: View {
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
            DynamicBackground()
            
            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("온라인 쓰기/단어 자동화시스템\n불러오는중..")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding(40)
            .liquidGlass()
        }
        .onAppear {
            let randomTime = Double.random(in: 5.0...10.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isLoading = false
                }
            }
        }
    }
}

struct TermsView: View {
    @Binding var hasAgreed: Bool

    var body: some View {
        ZStack {
            DynamicBackground()
            
            VStack(spacing: 30) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                VStack(spacing: 12) {
                    Text("이용약관 동의")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("앱을 사용하기 전 아래 약관에 동의해야 합니다.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("저는 이 앱으로 인해 나중에 들키거나 그때 이 앱 제작자에게 책임을 물지 않겠습니다.")
                        .font(.system(size: 15, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(24)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation { hasAgreed = true }
                    }) {
                        Text("동의합니다")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        exit(0)
                    }) {
                        Text("동의하지 않습니다 (앱 종료)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 40)
            .liquidGlass()
            .padding(20)
        }
    }
}

struct ContentView: View {
    @StateObject private var vm = WebViewModel()
    @State private var answerInput: String = ""
    @State private var delayMinutes: Int = 10
    @State private var remainingSeconds: Int = 0
    @State private var isDelaying: Bool = false
    @State private var showDelayAlert: Bool = false
    @State private var showActionTypeDialog: Bool = false
    @State private var showSettings: Bool = false
    @State private var showIdkAnswerAlert: Bool = false
    @State private var timer: Timer? = nil
    
    // 유튜브 상태 관리 변수
    @State private var showYouTube: Bool = false
    @State private var isYouTubeMinimized: Bool = false

    var body: some View {
        ZStack {
            DynamicBackground()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(vm.listeningCount > 0 ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                                .shadow(color: vm.listeningCount > 0 ? .green : .orange, radius: 4)
                            Text("Exam4me")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }

                            Button(action: { vm.webView.reload() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }

                            Button(action: { 
                                if vm.webView.canGoBack {
                                    vm.webView.goBack() 
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("뒤로")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(vm.canGoBack ? .primary : .secondary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                            }
                            .disabled(!vm.canGoBack)
                        }
                    }

                    HStack(spacing: 12) {
                        StatusBadge(
                            title: "Listening",
                            count: vm.listeningCount,
                            icon: "headphones",
                            color: Color.blue
                        )
                        StatusBadge(
                            title: "Vocabulary",
                            count: vm.vocabCount,
                            icon: "character.book.closed.fill",
                            color: Color.purple
                        )
                    }

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                                TextField("답지 입력...", text: $answerInput)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.3), lineWidth: 1))

                            Button(action: {
                                hideKeyboard()
                                showActionTypeDialog = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.fill")
                                    Text("시작")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(14)
                                .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 3)
                            }
                            
                            Button(action: {
                                hideKeyboard()
                                showDelayAlert = true
                            }) {
                                Image(systemName: "timer")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(colors: [Color.orange, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: Color.orange.opacity(0.4), radius: 6, x: 0, y: 3)
                            }
                        }
                        
                        HStack {
                            Button(action: {
                                showIdkAnswerAlert = true
                            }) {
                                Text("답지를 모르겠나요?")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .underline()
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(18)
                .liquidGlass()
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                WebViewContainer(vm: vm)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            // 뻐기기(타이머 대기) & 유튜브 오버레이 로직
            if isDelaying {
                Color.black.opacity(showYouTube && !isYouTubeMinimized ? 0.9 : 0.5)
                    .background(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                if showYouTube && !isYouTubeMinimized {
                    // 전체화면 유튜브 모드
                    ZStack {
                        YouTubeWebViewContainer(urlString: "https://www.youtube.com")
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            HStack {
                                // 좌측 상단 실시간 타이머
                                Text(String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                
                                Spacer()
                                
                                // 우측 상단 최소화 버튼
                                Button(action: {
                                    withAnimation { isYouTubeMinimized = true }
                                }) {
                                    Image(systemName: "minus.rectangle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            Spacer()
                        }
                    }
                    .transition(.move(edge: .bottom))
                } else {
                    // 기본 뻐기기 화면 (또는 유튜브 최소화 상태)
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 10)
                                .frame(width: 150, height: 150)

                            Circle()
                                .trim(from: 0, to: 0.85)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.cyan, .blue, .purple, .cyan]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(Double(remainingSeconds) * 6))
                                .animation(.linear(duration: 1), value: remainingSeconds)

                            VStack(spacing: 4) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 26))
                                    .foregroundColor(.cyan)
                                Text(String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60))
                                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(spacing: 8) {
                            Text("뻐기는중입니다!")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("앱을 닫으면 뻐기기에 실패하니\n앱을 열고있어주세요!")
                                .font(.system(size: 14, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(4)
                        }
                        
                        // 유튜브 진입 / 열기 버튼
                        Button(action: {
                            withAnimation {
                                showYouTube = true
                                isYouTubeMinimized = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                Text(showYouTube && isYouTubeMinimized ? "유튜브 다시 열기" : "시간뻐기면서 유튜브보기")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(14)
                            .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 10)
                    }
                    .padding(40)
                    .liquidGlass()
                    .padding(30)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .confirmationDialog("진행할 학습 유형을 선택하세요", isPresented: $showActionTypeDialog, titleVisibility: .visible) {
            Button("🎧 듣기평가 (Listening)") {
                let (target, answers) = parseAnswer(answerInput)
                if !answers.isEmpty {
                    vm.executeRoutine(target: target, answers: answers) {}
                }
            }
            Button("취소", role: .cancel) {}
        }
        .alert("앱에서 몇분을 뻐길건지 설정하세요.", isPresented: $showDelayAlert) {
            TextField("설정 시간(분 단위)", value: $delayMinutes, format: .number)
            Button("시작") {
                startDelay(minutes: delayMinutes)
            }
            Button("취소", role: .cancel) {}
        }
        .alert("안내", isPresented: $showIdkAnswerAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("장하현한테 물어보세요.")
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func parseAnswer(_ input: String) -> (String, [Int]) {
        var target = "L4"
        if let start = input.range(of: "(")?.upperBound, let end = input.range(of: ")")?.lowerBound {
            target = String(input[start..<end])
        }
        let digits = input.components(separatedBy: ")").last?.filter { $0.isNumber }.compactMap { Int(String($0)) } ?? []
        return (target, digits)
    }

    private func startDelay(minutes: Int) {
        remainingSeconds = minutes * 60
        withAnimation { 
            isDelaying = true 
            showYouTube = false
            isYouTubeMinimized = false
        }
        UIApplication.shared.isIdleTimerDisabled = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                timer?.invalidate()
                withAnimation { 
                    isDelaying = false 
                    showYouTube = false
                    isYouTubeMinimized = false
                }
                UIApplication.shared.isIdleTimerDisabled = false
                showAlert("이제 저장해도 좋습니다.")
            }
        }
    }

    private func showAlert(_ msg: String) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }
        topController.present(alert, animated: true)
    }
}

// 유튜브 전용 독립 웹뷰 래퍼
struct YouTubeWebViewContainer: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true
        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showCopyToast = false
    @State private var showBugReportAlert = false
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    var body: some View {
        ZStack {
            DynamicBackground()
            
            VStack(spacing: 24) {
                HStack {
                    Text("설정")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("정보")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            
                            HStack {
                                Text("앱 버전")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Text(appVersion)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            Button(action: { shareApp() }) {
                                HStack {
                                    Text("앱 공유하기")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            Button(action: { showBugReportAlert = true }) {
                                HStack {
                                    Text("앱 버그 및 신고")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .liquidGlass()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("업데이트 예정이력")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            Text("곧 쓰기자동화도 넣을예정입니다.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .liquidGlass()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text("개발자 후원")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SC제일은행")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("560-20-234696")
                                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                }
                                Spacer()
                                
                                Button(action: {
                                    UIPasteboard.general.string = "56020234696"
                                    withAnimation { showCopyToast = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation { showCopyToast = false }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: showCopyToast ? "checkmark" : "doc.on.clipboard")
                                        Text(showCopyToast ? "복사됨" : "복사")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        showCopyToast ? Color.green : Color.blue
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: (showCopyToast ? Color.green : Color.blue).opacity(0.3), radius: 5)
                                }
                            }
                            
                            Text("서버 유지 및 업데이트에 큰 힘이 됩니다. ☕️")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .liquidGlass()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("안내", isPresented: $showBugReportAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("제작자한테 디엠하세요.")
        }
    }
    
    private func shareApp() {
        let repoURL = "https://doorbellchoonja.github.io/exam4me-auto"
        guard let url = URL(string: repoURL) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            var topController = root
            while let presented = topController.presentedViewController {
                topController = presented
            }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            topController.present(activityVC, animated: true)
        }
    }
}

struct StatusBadge: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("\(count)개 미수행")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.2))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var vm: WebViewModel
    func makeUIView(context: Context) -> WKWebView { vm.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var listeningCount: Int = 0
    @Published var vocabCount: Int = 0
    @Published var canGoBack: Bool = false
    let webView: WKWebView
    private var backForwardObserver: NSKeyValueObservation?

    override init() {
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true

        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self 
        
        backForwardObserver = self.webView.observe(\.canGoBack, options: .new) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.canGoBack = webView.canGoBack
            }
        }
        
        if let url = URL(string: "https://ssdasa.exam4me.com") {
            self.webView.load(URLRequest(url: url))
        }
    }

    deinit {
        backForwardObserver?.invalidate()
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            completionHandler()
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in completionHandler() }))
        
        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }
        topController.present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            completionHandler(false)
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in completionHandler(true) }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in completionHandler(false) }))
        
        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }
        topController.present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let detectScript = """
        (function() {
            var text = document.body.innerText;
            var l = (text.match(/Listening/gi) || []).length;
            var v = (text.match(/Vocabulary/gi) || []).length;
            return { listening: l, vocab: v };
        })();
        """
        webView.evaluateJavaScript(detectScript) { [weak self] res, _ in
            if let dict = res as? [String: Any] {
                DispatchQueue.main.async {
                    self?.listeningCount = dict["listening"] as? Int ?? 0
                    self?.vocabCount = dict["vocab"] as? Int ?? 0
                }
            }
        }
    }

    func executeRoutine(target: String, answers: [Int], completion: @escaping () -> Void) {
        let answersJSON = answers.description

        let script = """
        (async function() {
            function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
            
            var e = new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13, bubbles: true });
            document.dispatchEvent(e);
            await sleep(500);

            if (typeof goNext === 'function') goNext(); await sleep(800);
            if (typeof goNextInfo === 'function') goNextInfo(); await sleep(800);
            if (typeof goStep01 === 'function') goStep01(); await sleep(1000);

            var answers = \(answersJSON);
            var total = answers.length;

            for (var i = 0; i < total; i++) {
                var ans = answers[i];
                
                if (typeof goStep01_sel === 'function') {
                    goStep01_sel(i, 2, ans);
                }
                await sleep(500);

                if (i < total - 1) {
                    if (typeof goStep0101_answer === 'function') goStep0101_answer();
                } else {
                    if (typeof goStep0101_finish === 'function') goStep0101_finish();
                }
                await sleep(800);
            }

            if (typeof goStep === 'function') goStep('info02'); await sleep(800);
            if (typeof goStep === 'function') goStep('step0201'); await sleep(800);

            for (var k = 0; k < total - 1; k++) {
                if (typeof goStep0201_step === 'function') goStep0201_step('next');
                await sleep(500);
            }

            if (typeof goStep === 'function') goStep('info03'); await sleep(800);
            if (typeof goStep0301 === 'function') goStep0301(); await sleep(800);
            if (typeof goStep04 === 'function') goStep04('Y'); await sleep(800);

            location.reload();
            await sleep(2000); 
            if (typeof goNext === 'function') goNext(); await sleep(800);
            if (typeof goNextInfo === 'function') goNextInfo(); await sleep(800);
            
            alert('지금부터 학습시작 버튼 옆의 시계모양 시간 채우기 버튼을 눌러서 시간을 채울수 있습니다.');

            return true;
        })();
        """
        
        webView.evaluateJavaScript(script) { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
