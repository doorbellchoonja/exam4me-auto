import SwiftUI
import WebKit
import Network
import LocalAuthentication
import UniformTypeIdentifiers

@main
struct Exam4meApp: App {
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("customAccentColor") private var customAccentColorName = "blue"
    @State private var isLoading = true
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !networkMonitor.isConnected {
                    OfflineView()
                } else if !hasAgreedToTerms {
                    TermsView(hasAgreed: $hasAgreedToTerms)
                } else if isLoading {
                    LoadingView(isLoading: $isLoading)
                } else {
                    ContentView(networkMonitor: networkMonitor)
                }
            }
            .preferredColorScheme(useSystemTheme ? nil : (isDarkMode ? .dark : .light))
            .accentColor(customAccentColor)
        }
    }
    
    var customAccentColor: Color {
        switch customAccentColorName {
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        default: return .blue
        }
    }
}

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType = .other

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = .other
                }
            }
        }
        monitor.start(queue: queue)
    }
}

struct OfflineView: View {
    var isTestMode: Bool = false
    var onClose: (() -> Void)? = nil
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            if isTestMode {
                Color.black.opacity(0.4)
                    .background(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.all)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onClose?()
                    }
            } else {
                DynamicBackground()
            }
            
            VStack(spacing: 24) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    .onAppear { isAnimating = true }
                
                VStack(spacing: 8) {
                    Text("인터넷 연결 해제됨")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("인터넷 연결을 확인하고\n다시 시도해 주세요.")
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
            .padding(40)
            .liquidGlass()
            .padding(30)
        }
    }
}

struct OTAUpdateOverlayView: View {
    let latestVersion: String
    @Binding var isPresented: Bool
    var isTestMode: Bool = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isTestMode {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            
            VStack(spacing: 24) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    .onAppear { isAnimating = true }
                
                VStack(spacing: 8) {
                    Text("새로운 업데이트 발견")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("최신 버전(v\(latestVersion))이 출시되었습니다.\n지금 바로 OTA로 간편하게 업데이트하세요!")
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                Button(action: {
                    let manifestURL = "https://doorbellchoonja.github.io/exam4me-auto/manifest.plist"
                    if let otaURL = URL(string: "itms-services://?action=download-manifest&url=\(manifestURL)") {
                        UIApplication.shared.open(otaURL)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        exit(0)
                    }
                }) {
                    Text("업데이트 설치")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(12)
                        .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            }
            .padding(32)
            .liquidGlass()
            .padding(24)
        }
    }
}

struct SlowNetworkOverlayView: View {
    @Binding var isPresented: Bool
    var isTestMode: Bool = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isTestMode {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            
            VStack(spacing: 24) {
                Image(systemName: "tortoise.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    .onAppear { isAnimating = true }
                
                VStack(spacing: 8) {
                    Text("인터넷 속도 느림 안내")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("현재 사용하시는 기기의 인터넷 속도가 느립니다.\n듣기/쓰기를 하실때 사이트로딩이 느리면 자동화중에 오류가 발생할 수 있습니다.\n그래도 계속하시겠습니까?")
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        exit(0)
                    }) {
                        Text("나가기")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                    }
                    
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("확인")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .padding(32)
            .liquidGlass()
            .padding(24)
        }
    }
}

struct ServerDownOverlayView: View {
    @Binding var isPresented: Bool
    var isTestMode: Bool = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isTestMode {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    .onAppear { isAnimating = true }
                
                VStack(spacing: 8) {
                    Text("온라인 서버 접속 불가")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("온라인서버가 접속불가인 상태이기때문에\n앱도 온라인서버가 연결잘될때 복구됩니다.")
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
            .padding(40)
            .liquidGlass()
            .padding(30)
        }
    }
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("customThemeStyle") private var themeStyle = "blue"
    @Environment(\.colorScheme) var colorScheme
    @State private var animateGlow = false
    
    var effectiveDarkMode: Bool {
        useSystemTheme ? (colorScheme == .dark) : isDarkMode
    }
    
    var body: some View {
        ZStack {
            Color(effectiveDarkMode ? UIColor.systemBackground : UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            Circle()
                .fill(primaryGlowColor.opacity(effectiveDarkMode ? 0.35 : 0.45))
                .blur(radius: 90)
                .frame(width: 320, height: 320)
                .offset(x: animateGlow ? -130 : 110, y: animateGlow ? -220 : -180)
                .animation(Animation.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGlow)
            
            Circle()
                .fill(secondaryGlowColor.opacity(effectiveDarkMode ? 0.35 : 0.45))
                .blur(radius: 90)
                .frame(width: 320, height: 320)
                .offset(x: animateGlow ? 140 : -120, y: animateGlow ? 220 : 170)
                .animation(Animation.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateGlow)
                
            Circle()
                .fill(accentGlowColor.opacity(effectiveDarkMode ? 0.25 : 0.35))
                .blur(radius: 90)
                .frame(width: 280, height: 280)
                .offset(x: animateGlow ? -60 : 70, y: animateGlow ? 380 : 420)
                .animation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGlow)
        }
        .onAppear {
            animateGlow = true
        }
    }
    
    var primaryGlowColor: Color {
        switch themeStyle {
        case "purple": return .purple
        case "green": return .mint
        case "orange": return .orange
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var secondaryGlowColor: Color {
        switch themeStyle {
        case "purple": return .pink
        case "green": return .blue
        case "orange": return .red
        case "pink": return .purple
        default: return .purple
        }
    }
    
    var accentGlowColor: Color {
        switch themeStyle {
        case "purple": return .cyan
        case "green": return .green
        case "orange": return .yellow
        case "pink": return .orange
        default: return .cyan
        }
    }
}

struct VectorSpinnerView: View {
    @State private var isRotating = false
    @State private var outerTrim: CGFloat = 0.05
    @State private var innerTrim: CGFloat = 0.1

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: outerTrim)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 95, height: 95)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: isRotating)
            
            Circle()
                .trim(from: 0.2, to: innerTrim)
                .stroke(Color.accentColor.opacity(0.45), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(isRotating ? -360 : 0))
                .animation(Animation.linear(duration: 1.6).repeatForever(autoreverses: false), value: isRotating)
        }
        .onAppear {
            isRotating = true
            withAnimation(Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                outerTrim = 0.68
                innerTrim = 0.75
            }
        }
    }
}

struct LoadingView: View {
    @Binding var isLoading: Bool
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            DynamicBackground()
            
            VStack(spacing: 32) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 10)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.8))
                        .frame(width: isAnimating ? 165 : 72, height: 10)
                        .offset(x: isAnimating ? 35 : -35)
                        .animation(
                            Animation.easeInOut(duration: 0.86)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .frame(width: 200, height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                
                Text("온라인 쓰기/단어 자동화시스템\n불러오는중..")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding(40)
            .liquidGlass()
            .scaleEffect(isLoading ? 1.0 : 0.95)
            .opacity(isLoading ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isLoading)
        }
        .onAppear {
            isAnimating = true
            let randomTime = Double.random(in: 3.0...5.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
    }
}

struct TermsView: View {
    @Binding var hasAgreed: Bool
    @State private var showFirstGuideAlert = false
    @State private var bounceAnim = false

    var body: some View {
        ZStack {
            DynamicBackground()
            
            VStack(spacing: 30) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .scaleEffect(bounceAnim ? 1.12 : 0.92)
                    .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: bounceAnim)
                    .onAppear { bounceAnim = true }
                
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
                .background(Color.primary.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    Button(action: {
                        showFirstGuideAlert = true
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
        .alert("안내", isPresented: $showFirstGuideAlert) {
            Button("확인") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    hasAgreed = true
                }
            }
        } message: {
            Text("처음 사용하시네요! 사용법 안부는 설정버튼 옆에 물음표모양 사용법버튼을 눌러주세요.")
        }
    }
}

struct GuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: GuideTab = .listening

    enum GuideTab {
        case listening, writing, faq
    }

    var body: some View {
        ZStack {
            DynamicBackground()
            
            VStack(spacing: 20) {
                HStack {
                    Text("사용법 안내")
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

                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.snappy) { selectedTab = .listening }
                    }) {
                        Text("🎧 듣기")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(selectedTab == .listening ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == .listening ? Color.accentColor : Color.primary.opacity(0.05))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        withAnimation(.snappy) { selectedTab = .writing }
                    }) {
                        Text("📝 쓰기")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(selectedTab == .writing ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == .writing ? Color.accentColor : Color.primary.opacity(0.05))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        withAnimation(.snappy) { selectedTab = .faq }
                    }) {
                        Text("❓ FAQ")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(selectedTab == .faq ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == .faq ? Color.accentColor : Color.primary.opacity(0.05))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                
                ScrollView {
                    if selectedTab == .listening {
                        VStack(alignment: .leading, spacing: 24) {
                            GuideStep(num: "1", title: "로그인", desc: "Exam4me 계정으로 로그인합니다.")
                            
                            GuideStep(num: "2", title: "답지 붙여넣기", desc: "시작할 듣기의 답지를 텍스트 그대로 복사하여 입력칸에 붙여넣습니다.")
                            
                            VStack(alignment: .leading, spacing: 12) {
                                GuideStep(num: "3", title: "학습시작", desc: "밑에 사이트에서 학습시작을 눌러서 이화면이 뜨고 화면에서 닫기 버튼을 누릅니다.")
                                
                                AsyncImage(url: URL(string: "https://hc1.checker.in/file2link/photos/file_607170.jpg/file_607170.jpg")) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(maxWidth: .infinity, minHeight: 180)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                    case .failure(_):
                                        Text("이미지를 불러올 수 없습니다.")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .padding(.leading, 40)
                            }
                            
                            GuideStep(num: "4", title: "시작 버튼 누르기", desc: "앱 상단의 답지 입력칸 옆에 있는 시작버튼을 누르고 듣기-학습1순으로 누릅니다. 그리고 '저장에 실패했습니다' 라는 알림창이 뜨면 뒤에 온라인창이 멈추기까지 기다리세요. 온라인창이 멈추기까지 기다린 후 확인버튼을 누르고 다시 시작버튼-듣기-학습2를 눌러주세요.")
                            
                            GuideStep(num: "5", title: "완료", desc: "그 이후는 안내에 따라 하시면 됩니다.")
                        }
                        .padding(20)
                        .liquidGlass()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    } else if selectedTab == .writing {
                        VStack(alignment: .leading, spacing: 24) {
                            GuideStep(num: "1", title: "쓰기/단어장 기능", desc: "파일 앱에서 .txt 단어장을 추가하고 범위를 지정하여 자동화를 진행할 수 있습니다.")
                        }
                        .padding(20)
                        .liquidGlass()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 28) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Q: 듣기자동화중에 튕기거나 나가졌는데 시작하기가 아니고 이어하기로 떠요 어떻게 해야하나요?")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("A: 이어하기를 눌러서 학습을 시작한 후에 아래 화면에서 닫기 버튼을 누르고 [시작] -> [듣기] -> [학습시작2]를 눌러주세요.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                
                                AsyncImage(url: URL(string: "https://hc1.checker.in/file2link/photos/file_607875.jpg/file_607875.jpg")) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView().frame(maxWidth: .infinity, minHeight: 150)
                                    case .success(let image):
                                        image.resizable().scaledToFit().cornerRadius(10)
                                    case .failure(_):
                                        Text("이미지 로드 실패").font(.system(size: 12)).foregroundColor(.secondary)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .padding(.top, 4)
                                
                                AsyncImage(url: URL(string: "https://hc1.checker.in/file2link/photos/file_607876.jpg/file_607876.jpg")) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView().frame(maxWidth: .infinity, minHeight: 150)
                                    case .success(let image):
                                        image.resizable().scaledToFit().cornerRadius(10)
                                    case .failure(_):
                                        Text("이미지 로드 실패").font(.system(size: 12)).foregroundColor(.secondary)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            Divider().background(Color.primary.opacity(0.1))
                            
                            Text("상단에 없거나 모르는 질문들은 디엠으로 부탁드립니다.")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.accentColor)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                        }
                        .padding(20)
                        .liquidGlass()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

struct GuideStep: View {
    let num: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(num)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
    }
}

class ServerStatusManager: ObservableObject {
    @Published var isServerOnline: Bool = true
    @Published var showServerDownAlert: Bool = false
    @Published var isSlowNetwork: Bool = false
    @Published var showSlowNetworkAlert: Bool = false
    @Published var currentSpeedText: String = "0.0 KB/s"
    
    private var speedTimer: Timer?
    private var hasAlertedSlowNetwork = false
    
    func checkServerStatus(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://ssdasa.exam4me.com") else {
            DispatchQueue.main.async {
                self.isServerOnline = false
                completion(false)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let isOnline = (error == nil && (response as? HTTPURLResponse)?.statusCode ?? 500 < 500)
            DispatchQueue.main.async {
                self.isServerOnline = isOnline
                completion(isOnline)
            }
        }.resume()
    }
    
    func startRealtimeSpeedTracking() {
        speedTimer?.invalidate()
        speedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let url = URL(string: "https://ssdasa.exam4me.com") else { return }
            let startTime = Date()
            
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                let elapsedTime = Date().timeIntervalSince(startTime)
                if let data = data, error == nil, elapsedTime > 0 {
                    let bytesLoaded = Double(data.count)
                    let speedBytesPerSec = bytesLoaded / elapsedTime
                    let speedKBPerSec = speedBytesPerSec / 1024
                    
                    DispatchQueue.main.async {
                        if speedBytesPerSec >= 1024 * 1024 {
                            let speedMB = speedBytesPerSec / (1024 * 1024)
                            self.currentSpeedText = String(format: "%.2f MB/s", speedMB)
                        } else {
                            self.currentSpeedText = String(format: "%.1f KB/s", speedKBPerSec)
                        }
                        
                        if speedKBPerSec < 100.0 && !self.hasAlertedSlowNetwork {
                            self.hasAlertedSlowNetwork = true
                            self.isSlowNetwork = true
                            self.showSlowNetworkAlert = true
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.currentSpeedText = "0.0 KB/s"
                    }
                }
            }
            task.resume()
        }
    }
    
    func stopRealtimeSpeedTracking() {
        speedTimer?.invalidate()
        speedTimer = nil
    }
}

class StudyStatsManager: ObservableObject {
    @AppStorage("todayListeningCount") var todayListeningCount: Int = 0
    @AppStorage("todayWritingCount") var todayWritingCount: Int = 0
    @AppStorage("todayStudySeconds") var todayStudySeconds: Int = 0
    @AppStorage("lastRecordDate") var lastRecordDate: String = ""
    
    @AppStorage("targetListeningCount") var targetListeningCount: Int = 5
    @AppStorage("targetWritingCount") var targetWritingCount: Int = 5

    init() {
        checkAndResetDailyStats()
    }

    func addListening() {
        checkAndResetDailyStats()
        todayListeningCount += 1
    }

    func addWriting() {
        checkAndResetDailyStats()
        todayWritingCount += 1
    }

    func addStudyTime(seconds: Int) {
        checkAndResetDailyStats()
        todayStudySeconds += seconds
    }

    private func checkAndResetDailyStats() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())

        if lastRecordDate != todayStr {
            todayListeningCount = 0
            todayWritingCount = 0
            todayStudySeconds = 0
            lastRecordDate = todayStr
        }
    }

    var formattedStudyTime: String {
        let hours = todayStudySeconds / 3600
        let minutes = (todayStudySeconds % 3600) / 60
        let seconds = todayStudySeconds % 60
        if hours > 0 {
            return String(format: "%d시간 %d분", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d분 %d초", minutes, seconds)
        } else {
            return String(format: "%d초", seconds)
        }
    }
    
    var listeningProgress: Double {
        guard targetListeningCount > 0 else { return 0 }
        return min(Double(todayListeningCount) / Double(targetListeningCount), 1.0)
    }

    var writingProgress: Double {
        guard targetWritingCount > 0 else { return 0 }
        return min(Double(todayWritingCount) / Double(targetWritingCount), 1.0)
    }
}

struct VocabItem: Codable, Identifiable, Hashable {
    var id = UUID()
    let number: String
    let category: String
    let word: String
    let meaning: String
}

struct VocabBook: Codable, Identifiable, Hashable {
    var id = UUID()
    let title: String
    let items: [VocabItem]
}

class VocabManager: ObservableObject {
    @AppStorage("savedVocabBooksData") var savedVocabBooksData: String = "[]"

    var books: [VocabBook] {
        get {
            guard let data = savedVocabBooksData.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([VocabBook].self, from: data) else {
                return [VocabBook(title: "기본 능률보카 어원", items: [
                    VocabItem(number: "1", category: "1", word: "progress", meaning: "전진(하다); 진보(하다)"),
                    VocabItem(number: "2", category: "2", word: "propose", meaning: "제안하다; 제시하다"),
                    VocabItem(number: "31", category: "31", word: "overseas", meaning: "해외로, 해외에 있는"),
                    VocabItem(number: "60", category: "60", word: "depress", meaning: "낙담시키다; 불경기로 만들다")
                ])]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: encoded, encoding: .utf8) {
                savedVocabBooksData = jsonString
                objectWillChange.send()
            }
        }
    }

    func addBook(title: String, content: String) {
        let lines = content.components(separatedBy: .newlines)
        var items: [VocabItem] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            let comps = line.components(separatedBy: "\t")
            if comps.count >= 4 {
                let num = comps[0].trimmingCharacters(in: .whitespaces)
                let cat = comps[1].trimmingCharacters(in: .whitespaces)
                let word = comps[2].trimmingCharacters(in: .whitespaces)
                let meaning = comps[3].trimmingCharacters(in: .whitespaces)
                if index == 0 && (num.contains("번호") || word.contains("단어")) { continue }
                items.append(VocabItem(number: num, category: cat, word: word, meaning: meaning))
            }
        }
        
        if !items.isEmpty {
            var current = books
            current.append(VocabBook(title: title, items: items))
            books = current
        }
    }

    func removeBook(id: UUID) {
        var current = books
        current.removeAll { $0.id == id }
        books = current
    }
}

class JSMacroManager: ObservableObject {
    @AppStorage("savedJSMacros") var savedMacrosData: String = "[]"

    struct JSMacro: Codable, Identifiable, Hashable {
        var id = UUID()
        let name: String
        let code: String
    }

    var macros: [JSMacro] {
        get {
            guard let data = savedMacrosData.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([JSMacro].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: encoded, encoding: .utf8) {
                savedMacrosData = jsonString
                objectWillChange.send()
            }
        }
    }

    func addMacro(name: String, code: String) {
        var current = macros
        current.append(JSMacro(name: name, code: code))
        macros = current
    }

    func removeMacro(id: UUID) {
        var current = macros
        current.removeAll { $0.id == id }
        macros = current
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
        .background(Color.primary.opacity(0.05))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }
}

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var vm: WebViewModel
    func makeUIView(context: Context) -> WKWebView { vm.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

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

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var listeningCount: Int = 0
    @Published var vocabCount: Int = 0
    @Published var canGoBack: Bool = false
    @Published var isLoadingWeb: Bool = true
    @Published var consoleLogs: [String] = []
    let webView: WKWebView
    private var backForwardObserver: NSKeyValueObservation?

    override init() {
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true

        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let userContentController = WKUserContentController()
        let consoleScript = """
        (function() {
            var oldLog = console.log;
            var oldError = console.error;
            var oldWarn = console.warn;
            
            console.log = function(message) {
                window.webkit.messageHandlers.consoleHandler.postMessage('LOG: ' + Array.from(arguments).join(' '));
                oldLog.apply(console, arguments);
            };
            console.error = function(message) {
                window.webkit.messageHandlers.consoleHandler.postMessage('ERROR: ' + Array.from(arguments).join(' '));
                oldError.apply(console, arguments);
            };
            console.warn = function(message) {
                window.webkit.messageHandlers.consoleHandler.postMessage('WARN: ' + Array.from(arguments).join(' '));
                oldWarn.apply(console, arguments);
            };
        })();
        """
        let userScript = WKUserScript(source: consoleScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)

        let webViewTemp = WKWebView(frame: .zero, configuration: config)
        self.webView = webViewTemp
        super.init()
        
        class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
            weak var parent: WebViewModel?
            init(parent: WebViewModel) { self.parent = parent }
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                if message.name == "consoleHandler", let body = message.body as? String {
                    DispatchQueue.main.async {
                        self.parent?.consoleLogs.append(body)
                    }
                }
            }
        }
        
        let messageHandler = ScriptMessageHandler(parent: self)
        userContentController.add(messageHandler, name: "consoleHandler")
        config.userContentController = userContentController

        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self 
        
        backForwardObserver = self.webView.observe(\.canGoBack, options: .new) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.canGoBack = webView.canGoBack
            }
        }
        
        loadInitialURL()
    }

    deinit {
        backForwardObserver?.invalidate()
    }

    func loadInitialURL() {
        if let url = URL(string: "https://ssdasa.exam4me.com") {
            self.webView.load(URLRequest(url: url))
        }
    }

    func loadSpecificURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            self.webView.load(URLRequest(url: url))
        }
    }

    func closePopup() {
        if let url = URL(string: "https://ssdasa.exam4me.com/_student/studentHome2.jsp") {
            self.webView.load(URLRequest(url: url))
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async { self.isLoadingWeb = true }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { self.isLoadingWeb = false }
        
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

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { self.isLoadingWeb = false }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { self.isLoadingWeb = false }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame {
            return nil
        }
        webView.load(navigationAction.request)
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else {
                completionHandler()
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in completionHandler() }))
            
            var topController = root
            while let presented = topController.presentedViewController {
                guard let nextPresented = presented.presentedViewController else { break }
                topController = nextPresented
            }
            topController.present(alert, animated: true)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
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
                guard let nextPresented = presented.presentedViewController else { break }
                topController = nextPresented
            }
            topController.present(alert, animated: true)
        }
    }

    func executeRoutine1(target: String, answers: [Int], completion: @escaping () -> Void) {
        let answersJSON = answers.description

        let script = """
        (async function() {
            function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
            
            var e = new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13, bubbles: true });
            document.dispatchEvent(e);
            await sleep(10);

            if (typeof goNext === 'function') goNext(); await sleep(20);
            if (typeof goNextInfo === 'function') goNextInfo(); await sleep(20);
            if (typeof goStep01 === 'function') goStep01(); await sleep(30);

            var answers = \(answersJSON);
            var total = answers.length;

            for (var i = 0; i < total; i++) {
                var ans = answers[i];
                
                if (typeof goStep01_sel === 'function') {
                    goStep01_sel(i, 2, ans);
                }
                await sleep(10);

                if (i < total - 1) {
                    if (typeof goStep0101_answer === 'function') goStep0101_answer();
                } else {
                    if (typeof goStep0101_finish === 'function') goStep0101_finish();
                }
                await sleep(20);
            }

            if (typeof goStep === 'function') goStep('info02'); await sleep(20);
            if (typeof goStep === 'function') goStep('step0201'); await sleep(20);

            for (var k = 0; k < total - 1; k++) {
                if (typeof goStep0201_step === 'function') goStep0201_step('next');
                await sleep(10);
            }

            if (typeof goStep === 'function') goStep('info03'); await sleep(20);
            if (typeof goStep0301 === 'function') goStep0301(); await sleep(20);
            if (typeof goStep04 === 'function') goStep04('Y'); await sleep(20);

            location.reload();
            await sleep(1000);

            return true;
        })();
        """
        
        webView.evaluateJavaScript(script, completionHandler: { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        })
    }

    func executeRoutine2(completion: @escaping () -> Void) {
        let script = """
        (async function() {
            function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
            
            if (typeof goNext === 'function') goNext(); await sleep(30);
            if (typeof goNextInfo === 'function') goNextInfo(); await sleep(30);

            return true;
        })();
        """
        
        webView.evaluateJavaScript(script, completionHandler: { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        })
    }

    func executeStep04() {
        let script = """
        (async function() {
            if (typeof goStep04 === 'function') goStep04('Y');
            return true;
        })();
        """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}

struct ContentView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @StateObject private var vm = WebViewModel()
    @StateObject private var serverManager = ServerStatusManager()
    @StateObject private var statsManager = StudyStatsManager()
    @StateObject private var macroManager = JSMacroManager()
    
    @State private var answerInput: String = ""
    @State private var delayMinutes: Int = 10
    @State private var remainingSeconds: Int = 0
    @State private var isDelaying: Bool = false
    @State private var showDelayAlert: Bool = false
    
    @State private var showTaskTypeDialog: Bool = false
    @State private var showListeningActionDialog: Bool = false
    @State private var showWritingSetupSheet: Bool = false
    
    @State private var showSettings: Bool = false
    @State private var showGuide: Bool = false
    @State private var showIdkAnswerAlert: Bool = false
    @State private var timer: Timer? = nil
    
    @State private var isAutomating: Bool = false
    
    @State private var showYouTube: Bool = false
    @State private var isYouTubeMinimized: Bool = false
    @State private var showCancelDelayConfirm: Bool = false

    @State private var isDarkSleepMode: Bool = false

    @AppStorage("isDeveloperMode") private var isDeveloperMode = false
    @AppStorage("enableFloatingJSButton") private var enableFloatingJSButton = false
    @AppStorage("enableSpeedViewer") private var enableSpeedViewer = false
    
    @State private var testOfflineAlert = false
    @State private var testServerDownAlert = false
    @State private var testSlowNetworkAlert = false
    @State private var testAutoUpdateAlert = false

    @State private var showAutoUpdateModal = false
    @State private var latestVersionFound = ""

    @State private var floatingButtonOffset = CGSize(width: 120, height: 250)
    @State private var showJSSheet = false
    @State private var customJSInput = ""

    var body: some View {
        ZStack {
            if testOfflineAlert {
                OfflineView(isTestMode: true, onClose: {
                    withAnimation { testOfflineAlert = false }
                })
            } else {
                DynamicBackground()

                VStack(spacing: 0) {
                    if isDeveloperMode && enableSpeedViewer {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.with.needle.fill")
                                .foregroundColor(.accentColor)
                            Text("실시간 속도:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(serverManager.currentSpeedText)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .liquidGlass()
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    }

                    VStack(spacing: 14) {
                        HStack(spacing: 6) {
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    vm.loadInitialURL()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(vm.listeningCount > 0 ? Color.green : Color.orange)
                                        .frame(width: 7, height: 7)
                                        .shadow(color: vm.listeningCount > 0 ? .green : .orange, radius: 4)
                                    Text("Exam4me")
                                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)

                            Spacer(minLength: 2)

                            HStack(spacing: 6) {
                                Button(action: { showGuide = true }) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                
                                Button(action: { showSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }

                                Button(action: { vm.webView.reload() }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }

                                Button(action: { 
                                    if vm.webView.canGoBack {
                                        vm.webView.goBack() 
                                    }
                                }) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "chevron.left")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(vm.canGoBack ? .primary : .secondary.opacity(0.5))
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                }
                                .disabled(!vm.canGoBack)

                                Button(action: {
                                    vm.closePopup()
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.red)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                QuickMenuButton(title: "홈", icon: "house.fill") {
                                    vm.loadSpecificURL("https://ssdasa.exam4me.com")
                                }
                                QuickMenuButton(title: "학생 홈", icon: "person.fill") {
                                    vm.loadSpecificURL("https://ssdasa.exam4me.com/_student/studentHome2.jsp")
                                }
                                QuickMenuButton(title: "미수행 목록", icon: "list.bullet.clipboard.fill") {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy-MM"
                                    let yearMonthStr = formatter.string(from: Date())
                                    vm.loadSpecificURL("https://ssdasa.exam4me.com/_student/hwDoList2.jsp?yearMonth=\(yearMonthStr)&doYn=N")
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            StatusBadge(
                                title: "Listening",
                                count: vm.listeningCount,
                                icon: "headphones",
                                color: Color.accentColor
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
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.1), lineWidth: 1))

                                Button(action: {
                                    hideKeyboard()
                                    showTaskTypeDialog = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                        Text("시작")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor)
                                    .cornerRadius(14)
                                    .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
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

                    ZStack {
                        WebViewContainer(vm: vm)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        
                        if vm.isLoadingWeb {
                            LoadingView(isLoading: .constant(true))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
            }

            if isDeveloperMode && enableFloatingJSButton {
                Button(action: {
                    showJSSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("JS실행")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(LinearGradient(colors: [.purple, Color.accentColor], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .offset(floatingButtonOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            floatingButtonOffset = value.translation
                        }
                )
            }

            if isAutomating {
                ZStack {
                    Color.black.opacity(0.65)
                        .background(.ultraThinMaterial)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 24) {
                        VectorSpinnerView()

                        VStack(spacing: 8) {
                            Text("자동화를 진행하고 있습니다!")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("잠시만 기다려주세요.\n작업이 완료되면 자동으로 종료됩니다.")
                                .font(.system(size: 14, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(4)
                        }
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .padding(30)
                }
                .transition(.opacity)
            }

            if isDelaying {
                ZStack {
                    Color.black.opacity(showYouTube && !isYouTubeMinimized ? 0.9 : 0.6)
                        .background(.ultraThinMaterial)
                        .edgesIgnoringSafeArea(.all)

                    if isDarkSleepMode {
                        ZStack {
                            Color.black.edgesIgnoringSafeArea(.all)
                            VStack(spacing: 12) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                                Text("다크 슬립 모드 작동 중")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("남은 시간: \(remainingSeconds / 60)분 \(remainingSeconds % 60)초")
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.cyan)
                                
                                Button(action: {
                                    withAnimation { isDarkSleepMode = false }
                                }) {
                                    Text("화면 켜기")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.purple.opacity(0.6))
                                        .cornerRadius(10)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .zIndex(10)
                    }

                    if showYouTube {
                        VStack(spacing: 0) {
                            HStack {
                                Text(String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                
                                Spacer()
                                
                                HStack(spacing: 10) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { 
                                            isYouTubeMinimized.toggle() 
                                        }
                                    }) {
                                        Image(systemName: isYouTubeMinimized ? "arrow.up.left.and.arrow.down.right" : "minus.rectangle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    Button(action: {
                                        showCancelDelayConfirm = true
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 50)
                            .padding(.bottom, 8)

                            YouTubeWebViewContainer(urlString: "https://www.youtube.com")
                                .opacity(isYouTubeMinimized ? 0 : 1)
                                .allowsHitTesting(!isYouTubeMinimized)
                        }
                    }

                    if (isYouTubeMinimized || !showYouTube) && !isDarkSleepMode {
                        VStack(spacing: 24) {
                            HStack {
                                Button(action: {
                                    withAnimation { isDarkSleepMode = true }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "moon.zzz")
                                        Text("다크 슬립 모드")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.7))
                                    .cornerRadius(10)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showCancelDelayConfirm = true
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white.opacity(0.8))
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 8)

                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                                    .frame(width: 150, height: 150)

                                Circle()
                                    .trim(from: 0, to: 0.85)
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: [.cyan, Color.accentColor, .purple, .cyan]),
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
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showYouTube = true
                                    isYouTubeMinimized = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: "play.rectangle.fill")
                                    Text("시간뻐기면서 유튜브보기")
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
                        .padding(30)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .padding(20)
                    }
                }
                .transition(.opacity)
            }

            if serverManager.showServerDownAlert && !testServerDownAlert {
                ServerDownOverlayView(isPresented: $serverManager.showServerDownAlert, isTestMode: false)
            }
            if testServerDownAlert {
                ServerDownOverlayView(isPresented: $testServerDownAlert, isTestMode: true)
            }

            if serverManager.showSlowNetworkAlert && !testSlowNetworkAlert {
                SlowNetworkOverlayView(isPresented: $serverManager.showSlowNetworkAlert, isTestMode: false)
            }
            if testSlowNetworkAlert {
                SlowNetworkOverlayView(isPresented: $testSlowNetworkAlert, isTestMode: true)
            }

            if showAutoUpdateModal && !testAutoUpdateAlert {
                OTAUpdateOverlayView(latestVersion: latestVersionFound, isPresented: $showAutoUpdateModal, isTestMode: false)
            }
            if testAutoUpdateAlert {
                OTAUpdateOverlayView(latestVersion: "9.9.9", isPresented: $testAutoUpdateAlert, isTestMode: true)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(serverManager: serverManager, statsManager: statsManager, testOfflineAlert: $testOfflineAlert, testServerDownAlert: $testServerDownAlert, testSlowNetworkAlert: $testSlowNetworkAlert, testAutoUpdateAlert: $testAutoUpdateAlert)
        }
        .sheet(isPresented: $showGuide) {
            GuideView()
        }
        .sheet(isPresented: $showJSSheet) {
            JSExecutionView(vm: vm, customJSInput: $customJSInput, showJSSheet: $showJSSheet, macroManager: macroManager)
        }
        .sheet(isPresented: $showWritingSetupSheet) {
            WritingSetupView(vm: vm, statsManager: statsManager, isPresented: $showWritingSetupSheet)
        }
        .confirmationDialog("진행할 학습 유형을 선택하세요", isPresented: $showTaskTypeDialog, titleVisibility: .visible) {
            Button("🎧 듣기 (Listening)") {
                showListeningActionDialog = true
            }
            Button("📝 쓰기 (Vocabulary)") {
                showWritingSetupSheet = true
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("듣기 평가 자동화 모드를 선택하세요", isPresented: $showListeningActionDialog, titleVisibility: .visible) {
            Button("학습시작 1") {
                let (target, answers) = parseAnswer(answerInput)
                if !answers.isEmpty {
                    statsManager.addListening()
                    statsManager.addStudyTime(seconds: 30)
                    withAnimation { isAutomating = true }
                    vm.executeRoutine1(target: target, answers: answers) {
                        withAnimation { isAutomating = false }
                        showTopMostAlert(message: "저장에 실패했습니다.")
                    }
                }
            }
            Button("학습시작 2") {
                statsManager.addWriting()
                statsManager.addStudyTime(seconds: 20)
                withAnimation { isAutomating = true }
                vm.executeRoutine2 {
                    withAnimation { isAutomating = false }
                    showTopMostAlert(message: "이제부터 학습시작2 버튼 오른쪽에 있는 시계모양 시간뻐기기버튼을 눌러서 시간을 뻐기세요.")
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
        .alert("시간 뻐기기 취소", isPresented: $showCancelDelayConfirm) {
            Button("확인", role: .destructive) {
                timer?.invalidate()
                withAnimation {
                    isDelaying = false
                    showYouTube = false
                    isYouTubeMinimized = false
                    isDarkSleepMode = false
                }
                UIApplication.shared.isIdleTimerDisabled = false
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("시간을 그만 뻐기겠습니까?")
        }
        .onAppear {
            serverManager.startRealtimeSpeedTracking()
            
            if !testServerDownAlert {
                serverManager.checkServerStatus { isOnline in
                    if !isOnline {
                        serverManager.showServerDownAlert = true
                    }
                }
            }
            checkStartupUpdate()
        }
        .onChange(of: networkMonitor.connectionType) { _ in
            if !isAutomating && networkMonitor.isConnected {
                vm.webView.reload()
            }
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if !isAutomating && isConnected {
                vm.webView.reload()
            }
        }
    }

    private func checkStartupUpdate() {
        guard let url = URL(string: "https://api.github.com/repos/doorbellchoonja/exam4me-auto/releases/latest") else { return }
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    let cleanTag = tagName.replacingOccurrences(of: "v", with: "")
                    if cleanTag != currentVersion {
                        DispatchQueue.main.async {
                            latestVersionFound = cleanTag
                            showAutoUpdateModal = true
                        }
                    }
                }
            } catch {}
        }.resume()
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
            isDarkSleepMode = false
        }
        UIApplication.shared.isIdleTimerDisabled = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                statsManager.addStudyTime(seconds: 1)
            } else {
                t.invalidate()
                withAnimation { 
                    isDelaying = false 
                    showYouTube = false
                    isYouTubeMinimized = false
                    isDarkSleepMode = false
                }
                UIApplication.shared.isIdleTimerDisabled = false
                
                showTopMostAlert(message: "이제 저장해도 좋습니다. 저장하고 나서 설정버튼에서 가장 오른쪽에 있는 빨간색 닫기 버튼을 누르면 미수행학습목록으로 이동합니다.") {
                    vm.executeStep04()
                }
            }
        }
    }

    private func showTopMostAlert(message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                completion?()
            }))
            
            var topController = root
            while let presented = topController.presentedViewController {
                guard let nextPresented = presented.presentedViewController else { break }
                topController = nextPresented
            }
            topController.present(alert, animated: true)
        }
    }
}

struct WritingSetupView: View {
    @ObservedObject var vm: WebViewModel
    @ObservedObject var statsManager: StudyStatsManager
    @Binding var isPresented: Bool
    
    @StateObject private var vocabManager = VocabManager()
    @State private var selectedBookID: UUID? = nil
    @State private var rangeInput: String = "31-60"
    @State private var showFileImporter = false

    var body: some View {
        ZStack {
            DynamicBackground()
            VStack(spacing: 20) {
                HStack {
                    Text("쓰기 자동화 & 복습 범위 설정")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button("닫기") { isPresented = false }
                }
                .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("단어장 선택 및 추가")
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack {
                        Picker("단어장", selection: $selectedBookID) {
                            ForEach(vocabManager.books) { book in
                                Text(book.title).tag(Optional(book.id))
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Spacer()
                        
                        Button(action: { showFileImporter = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text(".txt 파일 추가")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(16)
                .liquidGlass()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("복습하기 범위 입력")
                        .font(.system(size: 14, weight: .semibold))
                    
                    TextField("예: 31-60", text: $rangeInput)
                        .padding(12)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(10)
                        .font(.system(size: 15))
                    
                    Text("범위는 31-60 이런 형식으로 입력해주세요.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .liquidGlass()
                
                Button(action: {
                    executeWritingAutomation()
                }) {
                    Text("쓰기 자동화 시작")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .cornerRadius(14)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                Spacer()
            }
            .padding(20)
        }
        .onAppear {
            if selectedBookID == nil, let first = vocabManager.books.first {
                selectedBookID = first.id
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.plainText, UTType.text, UTType.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let gotAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if gotAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                do {
                    var content = ""
                    if let utf8String = try? String(contentsOf: url, encoding: .utf8) {
                        content = utf8String
                    } else if let koreanString = try? String(contentsOf: url, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR))) {
                        content = koreanString
                    } else {
                        content = try String(contentsOf: url, encoding: .default)
                    }
                    
                    let title = url.deletingPathExtension().lastPathComponent
                    vocabManager.addBook(title: title, content: content)
                    if let added = vocabManager.books.last {
                        selectedBookID = added.id
                    }
                } catch {
                    print("파일 읽기 오류: \(error)")
                }
            case .failure(let error):
                print("파일 가져오기 실패: \(error)")
            }
        }
    }

    private func executeWritingAutomation() {
        let script = """
        (async function() {
            function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
            if (typeof goNext === 'function') { goNext(); }
            return true;
        })();
        """
        
        statsManager.addWriting()
        statsManager.addStudyTime(seconds: 30)
        isPresented = false
        
        vm.webView.evaluateJavaScript(script, completionHandler: { _, _ in
            print("쓰기 자동화 시작: goNext() 실행 완료")
        })
    }
}

struct JSExecutionView: View {
    @ObservedObject var vm: WebViewModel
    @Binding var customJSInput: String
    @Binding var showJSSheet: Bool
    @ObservedObject var macroManager: JSMacroManager
    
    @State private var macroNameInput: String = ""
    @State private var showSaveAlert: Bool = false

    var body: some View {
        ZStack {
            DynamicBackground()
            VStack(spacing: 16) {
                HStack {
                    Text("JS 매크로 저장소 & 콘솔")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button("닫기") { showJSSheet = false }
                }
                
                TextEditor(text: $customJSInput)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                    .frame(height: 100)
                
                HStack(spacing: 10) {
                    Button(action: {
                        vm.webView.evaluateJavaScript(customJSInput, completionHandler: nil)
                        customJSInput = ""
                    }) {
                        Text("실행하기")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        if !customJSInput.isEmpty {
                            showSaveAlert = true
                        }
                    }) {
                        Text("매크로 저장")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("⭐ 즐겨찾는 매크로 템플릿")
                        .font(.system(size: 13, weight: .bold))
                    
                    ScrollView {
                        VStack(spacing: 6) {
                            if macroManager.macros.isEmpty {
                                Text("저장된 매크로가 없습니다.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 10)
                            } else {
                                ForEach(macroManager.macros) { macro in
                                    HStack {
                                        Button(action: {
                                            customJSInput = macro.code
                                        }) {
                                            Text(macro.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        
                                        Button(action: {
                                            macroManager.removeMacro(id: macro.id)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .padding(10)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .frame(height: 110)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("💻 웹뷰 개발자 콘솔 & 오류 리포트")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Button(action: {
                            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                            let allLogs = vm.consoleLogs.joined(separator: "\n")
                            let reportText = "[ExamAuto 오류 리포트]\n- 앱 버전: v\(appVersion)\n- 콘솔 로그:\n\(allLogs.isEmpty ? "기록 없음" : allLogs)"
                            UIPasteboard.general.string = reportText
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.clipboard")
                                Text("원클릭 리포트 복사")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if vm.consoleLogs.isEmpty {
                                Text("수집된 콘솔 로그가 없습니다.")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 10)
                            } else {
                                ForEach(vm.consoleLogs, id: \.self) { log in
                                    Text(log)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(log.contains("ERROR") ? .red : (log.contains("WARN") ? .orange : .primary))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(10)
                    .frame(height: 120)
                }
                
                Spacer()
            }
            .padding(20)
            .alert("매크로 이름 입력", isPresented: $showSaveAlert) {
                TextField("매크로 이름", text: $macroNameInput)
                Button("저장") {
                    if !macroNameInput.isEmpty {
                        macroManager.addMacro(name: macroNameInput, code: customJSInput)
                        macroNameInput = ""
                    }
                }
                Button("취소", role: .cancel) {
                    macroNameInput = ""
                }
            } message: {
                Text("현재 입력된 자바스크립트 코드를 저장할 이름을 입력하세요.")
            }
        }
    }
}

struct QuickMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var serverManager: ServerStatusManager
    @ObservedObject var statsManager: StudyStatsManager
    @Binding var testOfflineAlert: Bool
    @Binding var testServerDownAlert: Bool
    @Binding var testSlowNetworkAlert: Bool
    @Binding var testAutoUpdateAlert: Bool
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("isDeveloperMode") private var isDeveloperMode = false
    @AppStorage("enableFloatingJSButton") private var enableFloatingJSButton = false
    @AppStorage("enableSpeedViewer") private var enableSpeedViewer = false
    @AppStorage("customThemeStyle") private var themeStyle = "blue"

    @State private var showCopyToast = false
    @State private var showBugReportAlert = false
    @State private var showSecretMeaningAlert = false
    @State private var updateCheckMessage: String = ""
    @State private var isCheckingUpdate: Bool = false
    
    @State private var creatorTapCount = 0
    @State private var showDevModeChangeAlert = false
    @State private var devModeAlertMessage = ""

    let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let creatorHash = "MFG9PlaS0OqGqprd52Hj2aRCvViotKNeNR8Rot64EhQ="

    var body: some View {
        ZStack {
            DynamicBackground()
            
            VStack(spacing: 24) {
                HStack {
                    Text("설정 & 통계")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.accentColor)
                                Text("학습 통계 및 수행 목표 설정")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("듣기 달성률 (\(statsManager.todayListeningCount)/\(statsManager.targetListeningCount)회)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    ProgressView(value: statsManager.listeningProgress)
                                        .accentColor(.blue)
                                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("쓰기 달성률 (\(statsManager.todayWritingCount)/\(statsManager.targetWritingCount)회)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    ProgressView(value: statsManager.writingProgress)
                                        .accentColor(.purple)
                                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                VStack(spacing: 4) {
                                    Text("총 학습 시간")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Text(statsManager.formattedStudyTime)
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(10)
                            }
                        }
                        .padding(20)
                        .liquidGlass()

                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .foregroundColor(.pink)
                                Text("커스텀 테마 & 분위기 설정")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                ThemeButton(title: "블루", color: .blue, currentTheme: $themeStyle, themeKey: "blue")
                                ThemeButton(title: "퍼플", color: .purple, currentTheme: $themeStyle, themeKey: "purple")
                                ThemeButton(title: "민트", color: .mint, currentTheme: $themeStyle, themeKey: "green")
                                ThemeButton(title: "오렌지", color: .orange, currentTheme: $themeStyle, themeKey: "orange")
                                ThemeButton(title: "핑크", color: .pink, currentTheme: $themeStyle, themeKey: "pink")
                            }
                        }
                        .padding(20)
                        .liquidGlass()

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(serverManager.isServerOnline ? .green : .red)
                                Text("온라인 서버 상태")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(serverManager.isServerOnline ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    Text(serverManager.isServerOnline ? "정상 연결됨" : "접속 불가")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(serverManager.isServerOnline ? .green : .red)
                                }
                            }
                        }
                        .padding(20)
                        .liquidGlass()

                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $useSystemTheme) {
                                HStack {
                                    Image(systemName: "iphone")
                                        .foregroundColor(.blue)
                                    Text("시스템 설정 테마 연동")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .tint(.accentColor)
                            
                            if !useSystemTheme {
                                Divider().background(Color.primary.opacity(0.1))
                                
                                Toggle(isOn: $isDarkMode) {
                                    HStack {
                                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                            .foregroundColor(isDarkMode ? .yellow : .orange)
                                        Text(isDarkMode ? "다크 모드" : "라이트 모드")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                                .tint(.accentColor)
                            }
                        }
                        .padding(20)
                        .liquidGlass()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                    .foregroundColor(.purple)
                                Text("제작자 정보 (Face ID 보안)")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(creatorHash)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .textSelection(.enabled)
                                    .onTapGesture {
                                        creatorTapCount += 1
                                        if creatorTapCount >= 5 {
                                            creatorTapCount = 0
                                            if isDeveloperMode {
                                                authenticateWithFaceID { success in
                                                    if success {
                                                        isDeveloperMode = false
                                                        enableFloatingJSButton = false
                                                        enableSpeedViewer = false
                                                        testOfflineAlert = false
                                                        testServerDownAlert = false
                                                        testSlowNetworkAlert = false
                                                        testAutoUpdateAlert = false
                                                        devModeAlertMessage = "개발자모드 비활성화됨"
                                                        showDevModeChangeAlert = true
                                                    }
                                                }
                                            } else {
                                                authenticateWithFaceID { success in
                                                    if success {
                                                        isDeveloperMode = true
                                                        devModeAlertMessage = "개발자모드 활성화됨"
                                                        showDevModeChangeAlert = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                
                                Button(action: {
                                    showSecretMeaningAlert = true
                                }) {
                                    Text("이게 뭔가요?")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.purple)
                                        .cornerRadius(10)
                                        .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(20)
                        .liquidGlass()

                        if isDeveloperMode {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "hammer.fill")
                                        .foregroundColor(.orange)
                                    Text("개발자모드 설정 (Face ID 연동)")
                                        .font(.system(size: 16, weight: .bold))
                                    Spacer()
                                }
                                
                                Toggle(isOn: Binding(
                                    get: { enableFloatingJSButton },
                                    set: { newValue in
                                        authenticateWithFaceID { success in
                                            if success { enableFloatingJSButton = newValue }
                                        }
                                    }
                                )) {
                                    HStack {
                                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                                            .foregroundColor(.blue)
                                        Text("자바스크립트 실행버튼 추가")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                }
                                .tint(.accentColor)
                                
                                Divider().background(Color.primary.opacity(0.1))
                                
                                Toggle(isOn: Binding(
                                    get: { enableSpeedViewer },
                                    set: { newValue in
                                        authenticateWithFaceID { success in
                                            if success { enableSpeedViewer = newValue }
                                        }
                                    }
                                )) {
                                    HStack {
                                        Image(systemName: "gauge.with.needle.fill")
                                            .foregroundColor(.cyan)
                                        Text("실시간 인터넷 속도 뷰어 추가")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                }
                                .tint(.cyan)
                                
                                Divider().background(Color.primary.opacity(0.1))
                                
                                Toggle(isOn: $testOfflineAlert) {
                                    HStack {
                                        Image(systemName: "wifi.slash")
                                            .foregroundColor(.orange)
                                        Text("인터넷 연결 해제 알림 테스트")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                }
                                .tint(.orange)
                                
                                Divider().background(Color.primary.opacity(0.1))
                                
                                Toggle(isOn: $testServerDownAlert) {
                                    HStack {
                                        Image(systemName: "exclamationmark.octagon.fill")
                                            .foregroundColor(.red)
                                        Text("온라인서버 접속 불가 알림 테스트")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                }
                                .tint(.red)
                                
                                Divider().background(Color.primary.opacity(0.1))
                                
                                Toggle(isOn: $testSlowNetworkAlert) {
                                    HStack {
                                        Image(systemName: "tortoise.fill")
                                            .foregroundColor(.orange)
                                        Text("인터넷 속도 느림 안내 테스트")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                }
                                .tint(.orange)

                                Divider().background(Color.primary.opacity(0.1))
                                
                                Toggle(isOn: $testAutoUpdateAlert) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(.green)
                                        Text("앱 자동 업데이트 안내 테스트")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                }
                                .tint(.green)
                            }
                            .padding(20)
                            .liquidGlass()
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .foregroundColor(.blue)
                                Text("수동 업데이트 관리")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            
                            HStack {
                                Text("현재 버전")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Text("v\(currentAppVersion)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            
                            if !updateCheckMessage.isEmpty {
                                Text(updateCheckMessage)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 4)
                            }
                            
                            Button(action: {
                                checkForUpdatesManual()
                            }) {
                                HStack {
                                    Text(isCheckingUpdate ? "업데이트 확인 중..." : "업데이트 체크")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if isCheckingUpdate {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .disabled(isCheckingUpdate)
                        }
                        .padding(20)
                        .liquidGlass()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("정보")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                            
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
                            
                            Divider().background(Color.primary.opacity(0.1))
                            
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
                            Text("쓰기/단어장 자동화 기능 연동 완료.")
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
                                        showCopyToast ? Color.green : Color.accentColor
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: Color.accentColor.opacity(0.3), radius: 5)
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
        .preferredColorScheme(useSystemTheme ? nil : (isDarkMode ? .dark : .light))
        .alert("개발자 모드", isPresented: $showDevModeChangeAlert) {
            Button("확인") {
                exit(0)
            }
        } message: {
            Text("\(devModeAlertMessage)\n확인 버튼을 누르면 앱이 종료됩니다. 다시 실행해 주세요.")
        }
        .alert("안내", isPresented: $showSecretMeaningAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("알아서 암호화한거 푸세요.")
        }
        .alert("안내", isPresented: $showBugReportAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("제작자한테 디엠하세요.")
        }
    }
    
    private func authenticateWithFaceID(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "개발자 설정을 변경하려면 Face ID 또는 기기 암호 인증이 필요합니다."
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "개발자 설정 변경을 위해 기기 암호 인증이 필요합니다.") { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }

    private func checkForUpdatesManual() {
        isCheckingUpdate = true
        updateCheckMessage = ""
        guard let url = URL(string: "https://api.github.com/repos/doorbellchoonja/exam4me-auto/releases/latest") else {
            isCheckingUpdate = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isCheckingUpdate = false
                guard let data = data, error == nil else {
                    updateCheckMessage = "업데이트 확인 실패"
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let tagName = json["tag_name"] as? String {
                        let cleanTag = tagName.replacingOccurrences(of: "v", with: "")
                        if cleanTag == currentAppVersion {
                            updateCheckMessage = "이미 최신 버전입니다."
                        } else {
                            let manifestURL = "https://doorbellchoonja.github.io/exam4me-auto/manifest.plist"
                            if let otaURL = URL(string: "itms-services://?action=download-manifest&url=\(manifestURL)") {
                                UIApplication.shared.open(otaURL)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                exit(0)
                            }
                        }
                    } else {
                        updateCheckMessage = "이미 최신 버전입니다."
                    }
                } catch {
                    updateCheckMessage = "이미 최신 버전입니다."
                }
            }
        }.resume()
    }
    
    private func shareApp() {
        let repoURL = "https://doorbellchoonja.github.io/exam4me-auto"
        guard let url = URL(string: repoURL) else { return }
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
            
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topController.present(activityVC, animated: true, completion: nil)
        }
    }
}

struct ThemeButton: View {
    let title: String
    let color: Color
    @Binding var currentTheme: String
    let themeKey: String
    
    var body: some View {
        Button(action: {
            withAnimation {
                currentTheme = themeKey
            }
        }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: currentTheme == themeKey ? 3 : 0)
                    )
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(currentTheme == themeKey ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(currentTheme == themeKey ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(currentTheme == themeKey ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
    }
}
