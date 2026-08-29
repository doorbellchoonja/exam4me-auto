import SwiftUI
import WebKit

@main
struct ExamAutoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var vm = WebViewModel()
    @State private var answerInput: String = "(L4) 13514 22421 43554 42152"
    @State private var delayMinutes: Int = 10
    @State private var remainingSeconds: Int = 0
    @State private var isDelaying: Bool = false
    @State private var showDelayAlert: Bool = false
    @State private var showActionTypeDialog: Bool = false
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
                            Button(action: { vm.webView.reload() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(7)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }

                            Button(action: { vm.webView.goBack() }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "chevron.left")
                                    Text("뒤로")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(20)
                            }
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
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 6)

                // 웹뷰 컨테이너
                WebViewContainer(vm: vm)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
            }

            // 뻐기기 타이머 오버레이
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
                        Text("자동 뻐기는 중...")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)

                        Text("화면을 닫거나 나가면 실패할 수 있습니다.\n잠시만 대기해 주세요.")
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
                        .background(Material.ultraThinMaterial)
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
        .confirmationDialog("진행할 학습 유형을 선택하세요", isPresented: $showActionTypeDialog, titleVisibility: .visible) {
            Button("🎧 듣기평가 (Listening)") {
                showDelayAlert = true
            }
            Button("✍️ 쓰기평가 (Writing)", role: .cancel) {}
        }
        .alert("몇 분을 뻐길건지 설정하세요.", isPresented: $showDelayAlert) {
            TextField("설정 시간(분 단위)", value: $delayMinutes, format: .number)
            Button("시작") {
                let (target, answers) = parseAnswer(answerInput)
                if !answers.isEmpty {
                    vm.executeRoutine(target: target, answers: answers) {
                        startDelay(minutes: delayMinutes)
                    }
                }
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
        let alert = UIAlertController(title: "학습 완료", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        root.present(alert, animated: true)
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
    let webView: WKWebView

    override init() {
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true // 팝업창 자동 열기 활성화

        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self // 팝업 가로채기 델리게이트 연결
        
        if let url = URL(string: "https://ssdasa.exam4me.com") {
            self.webView.load(URLRequest(url: url))
        }
    }

    // 1. window.open() 및 target="_blank" 팝업을 현재 창에서 직접 로드하도록 처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    // 2. Alert 경고창 자동 지원
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            completionHandler()
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in completionHandler() }))
        root.present(alert, animated: true)
    }

    // 3. Confirm 확인창 자동 지원
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            completionHandler(false)
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in completionHandler(true) }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in completionHandler(false) }))
        root.present(alert, animated: true)
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
        let total = answers.count

        let script = """
        (async function() {
            function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
            
            var rows = Array.from(document.querySelectorAll('tr, div, li'));
            var targetRow = rows.find(r => r.innerText.includes('\(target)'));
            if (targetRow) {
                var btn = targetRow.querySelector('button, a, input[type="button"]');
                if (btn) btn.click();
            }
            await sleep(1000);

            var clickTxt = (txt) => {
                var el = Array.from(document.querySelectorAll('button, a, div, span, input[type="button"]'))
                              .find(e => e.innerText.trim() === txt || e.value === txt);
                if (el) el.click();
            };

            clickTxt('시작하기'); await sleep(800);
            clickTxt('닫기'); await sleep(800);
            clickTxt('START'); await sleep(800);
            clickTxt('학습시작'); await sleep(1000);

            var answers = \(answersJSON);
            var total = \(total);

            for (var i = 0; i < total; i++) {
                var ans = answers[i];
                var opts = document.querySelectorAll('.answer-item, input[type="radio"], .num' + ans);
                if (opts.length >= ans) { opts[ans - 1].click(); }
                await sleep(400);

                if (i < total - 1) {
                    if (typeof goStep0101_answer === 'function') goStep0101_answer();
                } else {
                    if (typeof goStep0101_finish === 'function') goStep0101_finish();
                }
                await sleep(600);
            }

            if (typeof goStep === 'function') goStep('info02'); await sleep(600);
            if (typeof goStep === 'function') goStep('step0201'); await sleep(600);

            for (var k = 0; k < total - 1; k++) {
                if (typeof goStep0201_step === 'function') goStep0201_step('next');
                await sleep(400);
            }

            if (typeof goStep === 'function') goStep('info03'); await sleep(600);
            if (typeof goStep0301 === 'function') goStep0301(); await sleep(600);
            if (typeof goStep04 === 'function') goStep04('Y');

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
