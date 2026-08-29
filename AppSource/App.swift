import SwiftUI
import WebKit

@main
struct ExamAutoApp: App {
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

// 1. 초기 로딩 (스플래시) 화면
struct LoadingView: View {
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("온라인 쓰기/단어 자동화시스템\n불러오는중..")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            // 5초 ~ 10초 사이 랜덤 딜레이
            let randomTime = Double.random(in: 5.0...10.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
    }
}

// 2. 최초 실행 시 이용약관 동의 화면
struct TermsView: View {
    @Binding var hasAgreed: Bool

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                VStack(spacing: 12) {
                    Text("이용약관 동의")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("앱을 사용하기 전 아래 약관에 동의해야 합니다.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("저는 이 앱으로 인해 나중에 들키거나 그때 이 앱 제작자에게 책임을 물지 않겠습니다.")
                        .font(.system(size: 15, weight: .medium))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(20)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation { hasAgreed = true }
                    }) {
                        Text("동의합니다")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(14)
                    }
                    
                    Button(action: {
                        // 동의 거부 시 앱 강제 종료
                        exit(0)
                    }) {
                        Text("동의하지 않습니다 (앱 종료)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// 3. 메인 콘텐츠 뷰
struct ContentView: View {
    @StateObject private var vm = WebViewModel()
    @State private var answerInput: String = "(L4) 13514 22421 43554 42152"
    @State private var delayMinutes: Int = 10
    @State private var remainingSeconds: Int = 0
    @State private var isDelaying: Bool = false
    @State private var showDelayAlert: Bool = false
    @State private var showActionTypeDialog: Bool = false
    @State private var showSettings: Bool = false
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // 상단 네비게이션 & 컨트롤 카드
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(vm.listeningCount > 0 ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Exam4Me Auto")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(7)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }

                            Button(action: { vm.webView.reload() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(7)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }

                            Button(action: { 
                                if vm.webView.canGoBack {
                                    vm.webView.goBack() 
                                }
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "chevron.left")
                                    Text("뒤로")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(vm.canGoBack ? .primary : .secondary.opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(20)
                            }
                            .disabled(!vm.canGoBack)
                        }
                    }

                    HStack(spacing: 10) {
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

                    HStack(spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            TextField("답지 입력: (L4) 13514...", text: $answerInput)
                                .font(.system(size: 13))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                        Button(action: {
                            hideKeyboard()
                            showActionTypeDialog = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                Text("학습시작")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        // 뻐기기(시간 채우기) 전용 버튼
                        Button(action: {
                            hideKeyboard()
                            showDelayAlert = true
                        }) {
                            Image(systemName: "timer")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(Color.orange)
                                .cornerRadius(12)
                                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 6)

                WebViewContainer(vm: vm)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
            }

            if isDelaying {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 8)
                            .frame(width: 140, height: 140)

                        Circle()
                            .trim(from: 0, to: 0.85)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.orange, .yellow, .orange]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(Double(remainingSeconds) * 6))
                            .animation(.linear(duration: 1), value: remainingSeconds)

                        VStack(spacing: 2) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                            Text(String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60))
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(spacing: 6) {
                        Text("뻐기는중입니다!")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)

                        Text("앱을 닫으면 뻐기기에 실패하니\n앱을 열고있어주세요!")
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(3)
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor.darkGray).opacity(0.85))
                        .cornerRadius(24)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(30)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
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
            Button("✍️ 쓰기평가 (Writing)", role: .cancel) {}
        }
        .alert("앱에서 몇분을 뻐길건지 설정하세요.", isPresented: $showDelayAlert) {
            TextField("설정 시간(분 단위)", value: $delayMinutes, format: .number)
            Button("시작") {
                startDelay(minutes: delayMinutes)
            }
            Button("취소", role: .cancel) {}
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
        withAnimation { isDelaying = true }
        UIApplication.shared.isIdleTimerDisabled = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                timer?.invalidate()
                withAnimation { isDelaying = false }
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

// 심플한 카드형 설정 화면
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showCopyToast = false
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("설정")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                VStack {
                    HStack {
                        Text("앱 버전")
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        Text(appVersion)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("개발자 후원")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SC제일은행")
                                .font(.system(size: 14, weight: .medium))
                            Text("560-20-234696")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
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
                            .foregroundColor(showCopyToast ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(showCopyToast ? Color.green : Color.gray.opacity(0.12))
                            .cornerRadius(12)
                        }
                    }
                    
                    Text("서버 유지 및 업데이트에 큰 힘이 됩니다. ☕️")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct StatusBadge: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text("\(count)개 미수행")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .cornerRadius(10)
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
