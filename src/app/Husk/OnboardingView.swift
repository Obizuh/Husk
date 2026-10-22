// SPDX-License-Identifier: GPL-2.0-or-later
import SwiftUI

/// What Husk asks on a first install, and remembers.
///
/// Deliberately versioned rather than a plain "seen it" flag: a later build that
/// adds a question needs to be able to ask it, and existing installs must not be
/// dragged back through the whole flow for one new answer. Bumping
/// `Onboarding.version` is what re-opens it.
enum Onboarding {
    /// Raise this when a question is added that existing installs must answer.
    static let version = 2   // 3.0: everyone goes through the new setup once

    private static let key = "husk.onboardingVersion"

    static var needed: Bool {
        UserDefaults.standard.integer(forKey: key) < version
    }

    static func complete() {
        UserDefaults.standard.set(version, forKey: key)
    }

    /// What apps inside Husk are told about where you are, chosen in setup.
    // TODO: hand these to the guest (TL locale/time zone and Android's persist.sys.locale / TZ); stored only for now.
    static let languageKey = "husk.guest.language"
    static let regionKey = "husk.guest.region"
    static let timeZoneKey = "husk.guest.timeZone"

    /// Start the guest as soon as the app opens, when JIT is available.
    static var autoStart: Bool {
        UserDefaults.standard.bool(forKey: "husk.autoStart")
    }
}

/// First run: setup in the manner of the iPhone's own -- language, region, time zone, the
/// optional settings, JIT -- and an offer of a walkthrough. Shown once; people who set up an older Husk get What's New instead.
struct OnboardingView: View {
    let onDone: () -> Void

    private enum Step: Int, CaseIterable {
        case welcome, language, region, timeZone, options, jit, ask, tour
    }

    @State private var step: Step = .welcome
    @State private var forward = true
    @State private var tourPage = 0

    @State private var language = OnboardingView.defaultLanguage
    @State private var region = Locale.current.huskRegionCode ?? "US"
    @State private var timeZone = TimeZone.current.identifier
    @State private var query = ""

    @State private var autoStart = false
    @State private var landscape = UserDefaults.standard.bool(forKey: "husk.landscapeGuest")
    @State private var sound = UserDefaults.standard.bool(forKey: "husk.sound")
    @State private var autoSave = UserDefaults.standard.object(forKey: "husk.autoSave") as? Bool ?? true
    @AppStorage(Theme.Appearance.key) private var appearance = Theme.Appearance.system
    @ObservedObject private var theme = AppTheme.shared
    @ObservedObject private var jit = JITCoordinator.shared
    @State private var settingUpJIT = false

    var body: some View {
        ZStack {
            Theme.backdrop
            setup
        }
        .sheet(isPresented: $settingUpJIT) { JITSetupFlow() }
    }

    // MARK: frame

    private var setup: some View {
        VStack(spacing: 0) {
            HStack {
                if step != .welcome {
                    Button { go(back: true) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            Text("返回")
                        }
                    }
                    .accessibilityLabel("返回")
                }
                Spacer()
            }
            .frame(height: 44)
            .padding(.horizontal, 16)

            ZStack {
                page(step)
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                                            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            if step != .ask {
                VStack(spacing: 14) {
                    dots
                    Button(step == .tour && tourPage == Self.tour.count - 1 ? "开始使用 Husk" : "继续") { next() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: 560)
    }

    private var dots: some View {
        let count = step == .tour ? Self.tour.count : Step.ask.rawValue + 1
        let current = step == .tour ? tourPage : step.rawValue
        return HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Theme.text : Color.secondary.opacity(0.3))
                    .frame(width: i == current ? 18 : 6, height: 6)
            }
        }
        .animation(.snappy, value: current)
    }

    private func next() {
        if step == .tour {
            if tourPage < Self.tour.count - 1 { withAnimation(.snappy) { tourPage += 1 } } else { finish() }
            return
        }
        query = ""
        forward = true
        withAnimation(.snappy) { step = Step(rawValue: step.rawValue + 1) ?? .ask }
    }

    private func go(back: Bool) {
        query = ""
        forward = false
        withAnimation(.snappy) {
            if step == .tour, tourPage > 0 { tourPage -= 1; return }
            step = Step(rawValue: step.rawValue - 1) ?? .welcome
        }
    }

    private func finish() {
        let d = UserDefaults.standard
        d.set(autoStart, forKey: "husk.autoStart")
        d.set(landscape, forKey: "husk.landscapeGuest")
        d.set(sound, forKey: "husk.sound")
        d.set(autoSave, forKey: "husk.autoSave")
        d.set(language, forKey: Onboarding.languageKey)
        d.set(region, forKey: Onboarding.regionKey)
        d.set(timeZone, forKey: Onboarding.timeZoneKey)
        Onboarding.complete()
        WhatsNew.markSeen()
        HuskLog.log("ui", "setup complete: language=\(language) region=\(region) timeZone=\(timeZone) autoStart=\(autoStart) "
                        + "landscape=\(landscape) sound=\(sound) autoSave=\(autoSave)")
        onDone()
    }

    // MARK: pages

    @ViewBuilder
    private func page(_ step: Step) -> some View {
        switch step {
        case .welcome: welcome
        case .language:
            picker(symbol: "globe", title: "系统语言",
                   subtitle: "Husk 内部应用与游戏所识别的语言。Husk 自身界面跟随您的 iPhone 系统语言。",
                   rows: Self.languages, selection: $language)
        case .region:
            picker(symbol: "map.fill", title: "国家与地区",
                   subtitle: "提供给需要检测国家/地区信息的应用与游戏使用。",
                   rows: Self.regions, selection: $region)
        case .timeZone:
            picker(symbol: "clock.fill", title: "时区设置",
                   subtitle: "提供给需要显示准确本地时间的应用使用。",
                   rows: Self.timeZones, selection: $timeZone)
        case .options: options
        case .jit: jitPage
        case .ask: ask
        case .tour: tourCard(Self.tour[tourPage]).id(tourPage)
        }
    }

    private func header(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 50, weight: .regular))
                .foregroundStyle(Theme.accent)
                .frame(height: 60)
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            Spacer()
            HuskMark(size: 110)
            Text("欢迎使用 Husk")
                .font(.system(size: 34, weight: .bold))
            Text("在 iPhone 上畅玩 Android 与 PS4 游戏。")
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("在开始之前只需简单设置几项，稍后可在“设置”中随时更改。")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    /// A list to choose one from, searchable, with the choice ticked.
    private func picker(symbol: String, title: String, subtitle: String, rows: [SetupChoice],
                        selection: Binding<String>) -> some View {
        let shown = rows.filter { matches(query, $0.name, $0.id) }
        return VStack(spacing: 16) {
            header(symbol, title, subtitle)
            SearchField(text: $query, prompt: "搜索")
                .padding(.horizontal, 20)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(shown) { row in
                            Button { selection.wrappedValue = row.id } label: {
                                HStack {
                                    Text(row.name).foregroundStyle(Theme.text)
                                    Spacer()
                                    if selection.wrappedValue == row.id {
                                        Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(Theme.accent)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 46)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(row.id)
                            if row.id != shown.last?.id { RowDivider().padding(.leading, -46) }
                        }
                    }
                    .huskCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .huskDismissKeyboardOnScroll()
                .onAppear { proxy.scrollTo(selection.wrappedValue, anchor: .center) }
            }
        }
    }

    private var options: some View {
        ScrollView {
            VStack(spacing: 16) {
                header("slider.horizontal.3", "个性化配置", "均为可选设置。稍后可随时在“设置”中修改。")

                VStack(alignment: .leading, spacing: 12) {
                    Text("外观模式").font(.headline)
                    Picker("外观模式", selection: $appearance) {
                        ForEach(Theme.Appearance.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appearance) { Theme.apply($0) }
                    Text("主题强调色").font(.headline).padding(.top, 4)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(AppTheme.presets) { preset in
                            let selected = preset.color.themeHex == theme.accentColor.themeHex
                            Button { theme.accentColor = preset.color } label: {
                                Circle().fill(preset.color)
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(Theme.text, lineWidth: selected ? 2.5 : 0).padding(-4))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(preset.name)
                        }
                    }
                }
                .padding(16)
                .huskCard()

                choice(icon: "bolt.fill", title: "打开 Husk 时自动启动 Android",
                       detail: "默认关闭。完整 Android 模拟器属于实验性功能，启动较慢并可能发生卡顿或闪退。绝大多数游戏直接在翻译层运行，无需启动该虚拟机。",
                       isOn: $autoStart, caution: true)
                choice(icon: "rectangle.landscape.rotate", title: "Android 屏幕默认横屏",
                       detail: "针对 Android 模拟器：横屏游戏将铺满屏幕，竖屏应用左右两侧留黑边。",
                       isOn: $landscape)
                choice(icon: "speaker.wave.2.fill", title: "Android 模拟器音频输出",
                       detail: "为模拟器添加虚拟声卡设备。开启时由于 QEMU 限制无法保存快照，每次启动均为冷启动。",
                       isOn: $sound)
                choice(icon: "externaldrive.badge.checkmark", title: "自动保存 Android 虚拟机快照",
                       detail: "在模拟器稳定后自动保存快照存档，后续启动只需数秒即可秒开。",
                       isOn: $autoSave)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private func choice(icon: String, title: String, detail: String, isOn: Binding<Bool>, caution: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: caution ? "exclamationmark.triangle.fill" : icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(caution ? Color.orange : Theme.accent)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(caution ? Color.orange : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn).labelsHidden().tint(Theme.accent)
        }
        .padding(16)
        .huskCard()
    }

    /// What the JIT page says is already in place, if anything.
    private var jitState: String? {
        if JITBootstrap.ready { return "JIT 已开启。" }
        if jit.method == .stikDebug { return "Husk 将使用 StikDebug。" }
        if jit.method == .trollStore { return "Husk 将使用 TrollStore。" }
        switch jit.pairingSource {
        case .onDevice: return "已在本机完成配对。"
        case .imported: return "已导入配对文件。"
        case nil: return nil
        }
    }

    private var jitPage: some View {
        VStack(spacing: 18) {
            header("bolt.fill", "开启 JIT 支持",
                   "游戏需要 JIT 可执行内存支持，iOS 仅在附加调试器时才允许此权限。Husk 内置的 StikJIT 可在应用内直接免电脑开启。同时也支持 StikDebug 和 TrollStore。")
            if let state = jitState {
                Label(state, systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.medium)).foregroundStyle(.green)
            }
            Button(jitState == nil ? "立即配置 StikJIT" : "修改 JIT 配置") { settingUpJIT = true }
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text("现在可以先跳过：当启动游戏需要 JIT 时 Husk 会再次提醒，您也可以随时在“设置 › JIT 与侧载”中配置。")
                .font(.footnote).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private var ask: some View {
        VStack(spacing: 18) {
            Spacer()
            header("map.circle.fill", "是否需要新手引导？", "快速了解 Husk 的核心功能：如何管理游戏、如何添加游戏，以及各项设置的位置。")
            Spacer()
            VStack(spacing: 12) {
                Button("带我了解") {
                    forward = true
                    tourPage = 0
                    withAnimation(.snappy) { step = .tour }
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("暂不需要") { finish() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }

    private struct TourCard { let symbol: String; let title: String; let text: String }

    private static let tour: [TourCard] = [
        TourCard(symbol: "house.fill", title: "首页",
                 text: "书架风格的游戏主页，最后游玩的游戏排在首位。点击选中游戏全屏展示海报，再次点击或点击“开始游戏”即可启动。点击 ⋯ 按钮可打开游戏专属设置。"),
        TourCard(symbol: "square.grid.2x2.fill", title: "游戏库",
                 text: "按平台分类展示所有已添加的应用与游戏。可按全部、Android、PS4 快速筛选，支持拼音与英文搜索，长按可弹出操作菜单。状态圆点标明兼容性：绿色完美、橙色可运行、红色有异常。"),
        TourCard(symbol: "plus.circle.fill", title: "添加游戏",
                 text: "点击 + 按钮添加 Android APK 或包含数据包的合包 (.xapk, .apkm, .apks)，或添加 PS4 假包 (.pkg) 与解压目录。也支持从“文件”应用或 Safari 直接分享文件至 Husk。"),
        TourCard(symbol: "cart.fill", title: "应用商店",
                 text: "在商店中浏览并下载 Android 应用，支持游客身份或登录自有账号，并实时查看社区兼容性运行报告。"),
        TourCard(symbol: "bolt.fill", title: "设置与 JIT",
                 text: "运行游戏必须依赖 JIT。可在首页或“设置 › JIT 与侧载”中一键开启。设置中还包含性能、外观、屏幕方向及完整 Android 模拟器管理。"),
        TourCard(symbol: "questionmark.circle.fill", title: "帮助与支持",
                 text: "遇到问题？“设置 › 帮助”提供了详尽的常见问题解答。游戏发生闪退时会自动生成诊断报告，方便一键分享求助。"),
    ]

    private func tourCard(_ card: TourCard) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: card.symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 96, height: 96)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            Text(card.title).font(.system(size: 32, weight: .bold))
            Text(card.text)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: lists

    private static var defaultLanguage: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") || preferred.hasPrefix("zh-HK") { return "zh-Hant" }
        if preferred.hasPrefix("zh") { return "zh-Hans" }
        if preferred.hasPrefix("pt-BR") { return "pt-BR" }
        let code = Locale.current.huskLanguageCode ?? "en"
        return languages.contains { $0.id == code } ? code : "en"
    }

    private static let languages: [SetupChoice] = {
        let codes = ["en", "es", "fr", "de", "it", "pt", "pt-BR", "ru", "uk", "pl", "nl", "sv", "da", "nb", "fi", "tr", "el",
                     "cs", "hu", "ro", "ar", "he", "hi", "th", "vi", "id", "ms", "ja", "ko", "zh-Hans", "zh-Hant"]
        return codes.map { code in
            let native = Locale(identifier: code).localizedString(forIdentifier: code) ?? code
            let here = Locale.current.localizedString(forIdentifier: code) ?? code
            return SetupChoice(id: code, name: native == here ? native.capitalized : "\(native.capitalized) – \(here)")
        }
    }()

    private static let regions: [SetupChoice] = {
        Locale.isoRegionCodes
            .compactMap { code in Locale.current.localizedString(forRegionCode: code).map { SetupChoice(id: code, name: $0) } }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()

    private static let timeZones: [SetupChoice] = {
        TimeZone.knownTimeZoneIdentifiers.map { id in
            let city = id.split(separator: "/").last.map { $0.replacingOccurrences(of: "_", with: " ") } ?? id
            let tz = TimeZone(identifier: id)
            let offset = tz.map { z -> String in
                let s = z.secondsFromGMT()
                return String(format: "GMT%@%d:%02d", s >= 0 ? "+" : "-", abs(s) / 3600, abs(s) % 3600 / 60)
            } ?? ""
            return SetupChoice(id: id, name: "\(city) (\(offset)) · \(id)")
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()
}

/// One row of a setup list: what is stored, and what is shown.
struct SetupChoice: Identifiable { let id: String; let name: String }
