// SPDX-License-Identifier: GPL-2.0-or-later
import SwiftUI

/// Settings, as the iOS Settings app lays them out: a card for the app up top, then groups of rows that each
/// push a page of their own. What belongs to the app, what belongs to the emulator, and what the thing is.
struct SettingsTab: View {
    @AppStorage(AppWindows.defaultKey) private var multitask = false
    @AppStorage(CompatibilityStore.askKey) private var askCompat = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { AboutSettings() } label: { appCard }
                }

                Section {
                    row(JITSettings(), "bolt.fill", .yellow, "JIT 与侧载", "内置 StikJIT — 推荐方式")
                } header: {
                    Text("JIT")
                } footer: {
                    Text("Android 模拟器与翻译层游戏需要 JIT 支持。Husk 内置的 StikJIT 无需电脑即可开启。")
                }

                Section("通用") {
                    row(DiscoverView(), "sparkle.magnifyingglass", .mint, "探索", "在 F-Droid 及其他仓库中查找应用")
                    row(LibrarySettings(), "square.grid.2x2.fill", .blue, "游戏库", "管理你的应用与图标")
                    row(PerformanceSettings(), "speedometer", .orange, "性能", "渲染器、音频输出")
                    row(AppearanceSettings(), "paintbrush.fill", .pink, "外观", "深浅模式、主题强调色、应用图标")
                    row(FontSettings(), "textformat", .indigo, "字体", "中日韩文字体下载与配置")
                    row(FAQTab(), "questionmark.circle.fill", .teal, "帮助与常见问题", "常见问题解答与故障排查")
                }

                Section {
                    Toggle(isOn: $multitask) {
                        Label {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("以窗口化方式打开应用")
                                Text("在运行应用的同时继续使用 Husk").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        } icon: {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.purple.huskGradient)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "macwindow.on.rectangle")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                } header: {
                    Text("多任务")
                } footer: {
                    Text("游戏和应用将在可移动、调整大小并最小化到 Dock 栏的浮窗中打开（类似 LiveContainer 多任务模式）。每个应用可在其专属设置中单独覆盖此项。")
                }

                Section {
                    Toggle(isOn: $askCompat) {
                        Label {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("询问游戏运行体验")
                                Text("每次更新后首次游玩结束时询问").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        } icon: {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.green.huskGradient)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "list.bullet.clipboard")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                    Link(destination: CompatibilityStore.site) {
                        Label("在线兼容性列表", systemImage: "safari")
                    }
                } header: {
                    Text("兼容性")
                } footer: {
                    Text("游戏详情页与商店会展示社区汇总的运行报告（来源于 antiweb.lol）。您的测试反馈将连同设备型号、iOS版本、Husk版本及JIT方式一同提交。")
                }

                Section {
                    row(AndroidSystemPage(), "apps.iphone", AndroidMark.green, "Android 系统", "实验性：基于 QEMU 的完整 Android")
                    row(InputSettings(), "hand.tap.fill", .indigo, "输入设置", "屏幕、触控、虚拟键盘")
                    row(NetworkSettings(), "globe", .green, "网络设置", "网络连接与会话保持")
                    row(SavedMachineSettings(), "externaldrive.fill", .teal, "虚拟机快照", "开机快照与自动存档保存")
                } header: {
                    Text("Android 模拟器")
                } footer: {
                    Text("完整 Android 系统运行于 QEMU 模拟器中，用于运行翻译层暂未支持的应用。此功能属于实验性，运行较慢，可能出现卡顿或闪退。")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
        }
    }

    private var appCard: some View {
        HStack(spacing: 14) {
            HuskMark(size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("Husk").font(.title3.weight(.semibold))
                Text("Version \(Bundle.main.version) · \(Bundle.main.commit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func row<D: View>(_ destination: D, _ icon: String, _ tint: Color,
                              _ title: String, _ subtitle: String) -> some View {
        NavigationLink { destination } label: {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            } icon: {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tint.huskGradient)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                    }
            }
        }
    }
}

/// A Form, as the system draws one.
private struct HuskForm: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(.inline)
    }
}

extension View {
    func huskForm() -> some View { modifier(HuskForm()) }
}

// MARK: - Library

struct LibrarySettings: View {
    @ObservedObject private var host = AndroidHost.shared
    @State private var working = false

    var body: some View {
        Form {
            Section {
                DetailRow(label: "已安装应用", value: "\(host.packages.count)", mono: false)
                DetailRow(label: "包含图标",
                          value: "\(host.packages.filter { $0.iconPath != nil }.count)",
                          mono: false)
            } footer: {
                Text("应用列表已缓存在本地，因此在 Android 尚未完全启动前即可显示在屏幕上。")
            }

            Section {
                Button {
                    working = true
                    Task { await host.refreshPackages(); working = false }
                } label: {
                    Label(working ? "正在刷新…" : "从 Android 刷新列表",
                          systemImage: "arrow.clockwise")
                }
                .disabled(working || !host.isReady)

                Button {
                    AndroidHost.forgetIcons()
                    working = true
                    Task { await host.refreshPackages(); working = false }
                } label: {
                    Label("重新获取图标", systemImage: "photo.on.rectangle")
                }
                .disabled(working || !host.isReady)
            } footer: {
                Text("名称和图标提取自 Android 系统的桌面启动器。重新获取将清除本地缓存并重新提取。")
            }
        }
        .huskForm()
        .navigationTitle("游戏库设置")
    }
}

// MARK: - Fonts

/// The Chinese, Japanese and Korean fonts the bundle leaves out (#95: 58 MB of Android's 82 MB of fonts), downloaded on request. Apps
/// on the translation layer find them where Android keeps them, through fonts.xml, which already names the file.
@MainActor
final class CJKFonts: ObservableObject {
    static let shared = CJKFonts()
    static let fileName = "NotoSansCJK-Regular.ttc"
    static let source = URL(string: "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTC/NotoSansCJK-Regular.ttc")!
    nonisolated static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Fonts", isDirectory: true)
    }
    nonisolated static var installed: Bool { FileManager.default.fileExists(atPath: directory.appendingPathComponent(fileName).path) }

    @Published private(set) var isInstalled = CJKFonts.installed
    @Published private(set) var downloading = false
    @Published private(set) var failure: String?

    func download() {
        guard !downloading else { return }
        downloading = true
        failure = nil
        Task {
            do {
                let (temp, response) = try await URLSession.shared.download(from: Self.source)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                try FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
                let dest = Self.directory.appendingPathComponent(Self.fileName)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: temp, to: dest)
                HuskLog.log("fonts", "CJK fonts installed at \(dest.path)")
                isInstalled = true
            } catch {
                failure = "The download failed: \(error.localizedDescription)"
                HuskLog.log("fonts", "CJK font download failed: \(error.localizedDescription)")
            }
            downloading = false
        }
    }

    func remove() {
        try? FileManager.default.removeItem(at: Self.directory.appendingPathComponent(Self.fileName))
        isInstalled = Self.installed
    }
}

struct FontSettings: View {
    @ObservedObject private var fonts = CJKFonts.shared

    var body: some View {
        Form {
            Section {
                if fonts.isInstalled {
                    Label("已安装", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Button(role: .destructive) { fonts.remove() } label: { Label("删除字体", systemImage: "trash") }
                } else {
                    Button { fonts.download() } label: {
                        Label(fonts.downloading ? "正在下载…" : "下载字体 (19.5 MB)", systemImage: "arrow.down.circle")
                    }
                    .disabled(fonts.downloading)
                }
                if let failure = fonts.failure { Text(failure).font(.caption).foregroundStyle(.red) }
            } header: {
                Text("中日韩文字体支持")
            } footer: {
                Text("Noto Sans CJK 是 Android 用于渲染中日韩语言的字体。自行渲染文本的游戏和应用（如 Unity、Flutter、"
                   + "cocos2d-x）若缺少此字体，中文字符将显示为空白方块。下载后在下次启动应用时生效。")
            }
        }
        .huskForm()
        .navigationTitle("字体设置")
    }
}

// MARK: - Performance

struct PerformanceSettings: View {
    @ObservedObject private var runner = QemuRunner.shared
    @State private var gpuMode =
        UserDefaults.standard.object(forKey: "husk.gpuMode") as? Bool ?? true
    @State private var sound = UserDefaults.standard.bool(forKey: "husk.sound")
    @State private var soundDevice =
        UserDefaults.standard.object(forKey: "husk.soundDevice") as? Bool ?? true

    var body: some View {
        Form {
            Section {
                Picker("渲染器", selection: $gpuMode) {
                    Text("GPU 硬件加速").tag(true)
                    Text("CPU 软件渲染").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: gpuMode) { v in
                    UserDefaults.standard.set(v, forKey: "husk.gpuMode")
                    HuskLog.log("ui", v ? "GPU renderer selected" : "CPU renderer selected")
                }
            } header: {
                Text("渲染器模式")
            } footer: {
                Text(gpuMode
                     ? "Android 通过 Metal 在真实 GPU 上加速渲染，帧率约为 CPU 渲染的 4 倍（默认推荐）。"
                     : "每个像素均由模拟的 CPU 绘制。速度极慢，仅在 GPU 渲染异常时使用。")
            }

            Section {
                DetailRow(label: "当前帧率",
                          value: runner.fps > 0
                                 ? String(format: "%.0f fps", runner.fps) : "—")
                DetailRow(label: "虚拟机分辨率",
                          value: "\(QemuRunner.lastGuestRes.w)×\(QemuRunner.lastGuestRes.h)")
            } header: {
                Text("实时状态")
            }

            Section {
                Toggle("声音输出", isOn: $sound)
                    .onChange(of: sound) { v in
                        UserDefaults.standard.set(v, forKey: "husk.sound")
                        HuskLog.log("ui", v ? "sound on" : "sound off")
                    }
                if sound {
                    Toggle("挂载虚拟声卡设备", isOn: $soundDevice)
                        .onChange(of: soundDevice) { v in
                            UserDefaults.standard.set(v, forKey: "husk.soundDevice")
                        }
                }
            } header: {
                Text("音频")
            } footer: {
                Text("添加虚拟声卡设备。挂载声卡时 Android 无法保存虚拟机快照（QEMU 限制），因此每次启动都将进行冷启动。"
                   + "切换此选项均需冷启动后生效。")
            }
        }
        .huskForm()
        .navigationTitle("性能设置")
    }
}

// MARK: - Input

struct InputSettings: View {
    @State private var landscapeGuest =
        UserDefaults.standard.bool(forKey: "husk.landscapeGuest")
    @State private var customRes = UserDefaults.standard.bool(forKey: "husk.customRes")
    @State private var widthText = InputSettings.stored("husk.resWidth", 720)
    @State private var heightText = InputSettings.stored("husk.resHeight", 1280)

    /// Sizes worth offering without typing. Deliberately short: these are the
    /// shapes a phone guest is actually run at, not a catalogue of every panel
    /// ever made.
    private static let presets: [(name: String, w: Int, h: Int)] = [
        ("小屏 — 360 × 800", 360, 800),
        ("高清 HD — 720 × 1280", 720, 1280),
        ("全高清 FHD — 1080 × 1920", 1080, 1920),
        ("横屏高清 HD — 1280 × 720", 1280, 720),
        ("平板 — 1280 × 800", 1280, 800),
    ]

    private static func stored(_ key: String, _ fallback: Int) -> String {
        let v = UserDefaults.standard.integer(forKey: key)
        return String(v > 0 ? v : fallback)
    }

    /// What the typed numbers actually come to, or nothing if they are not a
    /// size the guest can be given.
    private var effective: (w: Int, h: Int)? {
        QemuRunner.validResolution(w: Int(widthText) ?? 0, h: Int(heightText) ?? 0)
    }

    var body: some View {
        Form {
            Section {
                Picker("屏幕方向", selection: $landscapeGuest) {
                    Text("竖屏").tag(false)
                    Text("横屏").tag(true)
                }
                .pickerStyle(.segmented)
                .disabled(customRes)
                .onChange(of: landscapeGuest) { v in
                    UserDefaults.standard.set(v, forKey: "husk.landscapeGuest")
                    HuskLog.log("ui", v ? "guest panel will be landscape"
                                        : "guest panel will be portrait")
                }
            } header: {
                Text("屏幕方向")
            } footer: {
                Text(customRes
                     ? "开启自定义分辨率时由具体宽高决定屏幕比例，此处设置暂不生效。如需横屏请在下方输入较宽的分辨率。"
                     : "Android 系统在启动后无法动态调整屏幕比例，因此竖屏下玩横屏游戏会出现黑边且画面很小。"
                     + "以横屏模式创建虚拟机可全屏展示横屏游戏（竖屏应用则左右留黑边）。修改需冷启动一次生效。")
            }

            Section {
                Toggle("自定义分辨率", isOn: $customRes)
                    .onChange(of: customRes) { v in
                        UserDefaults.standard.set(v, forKey: "husk.customRes")
                        store()
                        HuskLog.log("ui", v ? "custom resolution on: "
                                            + "\(widthText)x\(heightText)"
                                            : "custom resolution off")
                    }

                if customRes {
                    Picker("预设分辨率", selection: Binding(
                        get: { presetIndex },
                        set: { i in
                            guard i >= 0, i < Self.presets.count else { return }
                            widthText = String(Self.presets[i].w)
                            heightText = String(Self.presets[i].h)
                            store()
                        })) {
                        ForEach(0..<Self.presets.count, id: \.self) { i in
                            Text(Self.presets[i].name).tag(i)
                        }
                        Text("自定义").tag(-1)
                    }

                    HStack {
                        Text("宽度")
                        Spacer()
                        TextField("720", text: $widthText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.technical())
                            .frame(width: 90)
                            .onChange(of: widthText) { _ in store() }
                    }
                    HStack {
                        Text("高度")
                        Spacer()
                        TextField("1280", text: $heightText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.technical())
                            .frame(width: 90)
                            .onChange(of: heightText) { _ in store() }
                    }

                    if let size = effective {
                        DetailRow(label: "Android 实际分辨率",
                                  value: "\(size.w) × \(size.h)")
                    } else {
                        Text("宽和高均须在 240 到 2560 之间。")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }

                DetailRow(label: "当前运行分辨率", value: running)
            } header: {
                Text("分辨率设置")
            } footer: {
                Text("虚拟屏幕在系统启动时配置，修改分辨率需冷启动一次生效，下次保存快照将替换旧存档。"
                   + "尺寸会自动对齐为 8 的倍数。分辨率越高渲染越吃性能。Android 的 DPI 不会随分辨率缩放，因此更高分辨率会展示更多内容而非单纯放大。")
            }

            Section {
                Text("触控操作默认始终开启。软键盘与屏幕旋转控件位于屏幕下方的胶囊栏中；游戏手柄与鼠标指针控制暂未适配。")
                    .font(.footnote).foregroundStyle(.secondary)
            } header: {
                Text("控制方式")
            }
        }
        .huskForm()
        .navigationTitle("输入与屏幕设置")
    }

    /// The panel the guest actually has, which only means anything while there
    /// is a guest: the stored value is last launch's until one starts.
    private var running: String {
        guard QemuRunner.shared.isRunning else { return "未启动" }
        return "\(QemuRunner.lastGuestRes.w) × \(QemuRunner.lastGuestRes.h)"
    }

    /// Which preset the typed numbers are, if any.
    private var presetIndex: Int {
        guard let size = effective else { return -1 }
        return Self.presets.firstIndex { $0.w == size.w && $0.h == size.h } ?? -1
    }

    private func store() {
        UserDefaults.standard.set(Int(widthText) ?? 0, forKey: "husk.resWidth")
        UserDefaults.standard.set(Int(heightText) ?? 0, forKey: "husk.resHeight")
    }
}

// MARK: - Network

struct NetworkSettings: View {
    @State private var keepNetwork =
        UserDefaults.standard.object(forKey: "husk.keepNetwork") as? Bool ?? true

    var body: some View {
        Form {
            Section {
                Toggle("在保存快照时保持网络连接", isOn: $keepNetwork)
                    .onChange(of: keepNetwork) { v in
                        UserDefaults.standard.set(v, forKey: "husk.keepNetwork")
                    }
            } footer: {
                Text(keepNetwork
                     ? "保存快照时关闭前台应用但保持 Android 核心网络框架运行，因此在恢复快照后网络仍可正常使用。"
                     : "保存快照时完全停止系统框架。这能更彻底释放 GPU 显存，但恢复后网络可能需要冷启动才能恢复。")
            }

            Section {
                Text("Android 通过 QEMU 虚拟网络中的虚拟以太网卡访问互联网。您局域网中的其他设备无法扫描虚拟机，虚拟机也无法嗅探局域网。")
                    .font(.footnote).foregroundStyle(.secondary)
            } header: {
                Text("网络连接原理")
            }
        }
        .huskForm()
        .navigationTitle("网络设置")
    }
}

// MARK: - JIT and sideloading

struct JITSettings: View {
    @ObservedObject private var runner = QemuRunner.shared
    @ObservedObject private var jit = JITCoordinator.shared
    @State private var autoStart = Onboarding.autoStart
    @AppStorage(JITCoordinator.autoEnableKey) private var autoJIT = false
    @AppStorage(JITCoordinator.trollStoreAutoKey) private var trollStoreJIT = true
    @State private var keepAttached = JITBootstrap.keepDebuggerAttached

    private var pairingLabel: String {
        switch jit.pairingSource {
        case .onDevice: return "已在本设备配对"
        case .imported: return "已导入配对文件"
        case nil: return "未配置"
        }
    }

    var body: some View {
        Form {
            Section {
                JITCard()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section {
                Picker("启用方式", selection: $jit.method) {
                    ForEach(JITMethod.allCases) { Text($0.title).tag($0) }
                }
                DetailRow(label: "StikDebug",
                          value: JITBootstrap.isStikDebugInstalled ? "已安装" : "未找到", mono: false)
                DetailRow(label: "TrollStore",
                          value: JITBootstrap.isTrollStoreInstalled ? "已安装" : "未找到", mono: false)
                DetailRow(label: "通过 TrollStore 安装",
                          value: JITBootstrap.isInstalledWithTrollStore ? "是" : "否", mono: false)
                DetailRow(label: "越狱环境",
                          value: JITBootstrap.debuggedAtLaunch ? "已允许应用 JIT"
                               : JITBootstrap.isJailbroken ? "已越狱" : "未越狱", mono: false)
                DetailRow(label: "内置配对状态", value: pairingLabel, mono: false)
                Button {
                    jit.showSetup = true
                } label: {
                    Label("配置 JIT 向导", systemImage: "wand.and.stars")
                }
            } header: {
                Text("其他 JIT 开启方式")
            } footer: {
                Text(jit.method == .automatic
                     ? jit.automaticDescription + " 内置 StikJIT 需要 iOS 16、LocalDevVPN 和配对文件（Husk 可在 iOS 17 上自行生成）。"
                     : HuskBuiltInJIT.unavailableReason ?? "内置 StikJIT 需要 LocalDevVPN 和配对文件（Husk 可在 iOS 17 上自行生成）。")
            }

            Section {
                DetailRow(label: "调试器状态",
                          value: JITBootstrap.isDebuggerAttached ? "已附加" : "未附加",
                          mono: false)
                DetailRow(label: "可执行内存",
                          value: JITBootstrap.isLive ? "已授予" : "未获取", mono: false)
                // The two routes, named separately. Either one is enough, and
                // when someone reports "JIT does not work" these two rows are
                // the whole diagnosis.
                DetailRow(label: "陷阱服务",
                          value: husk_ios_jit_self_route() != nil ? "无需使用"
                               : JITBootstrap.prewarmed ? "正常响应" : "未响应",
                          mono: false)
                if let route = husk_ios_jit_self_route() {
                    DetailRow(label: "内存路由",
                              value: String(cString: route) == "MAP_JIT" ? "MAP_JIT (TrollStore 权限)" : "原生内存 (已调试或已越狱)",
                              mono: false)
                }
                // Cached answer only: running the probe from a view body
                // could freeze the app (see JITBootstrap.mapJITWorks).
                DetailRow(label: "MAP_JIT 状态",
                          value: JITBootstrap.deviceEnforcesTXM ? "未启用 (TXM 限制)"
                               : JITBootstrap.mapJITResult.map { $0 ? "支持执行" : "被拒绝" }
                                 ?? "未测试",
                          mono: false)
                DetailRow(label: "配置后调试器",
                          value: JITBootstrap.detached ? "已自动分离" : "保持附加",
                          mono: false)
                if let why = JITBootstrap.lastFailure {
                    Text(why).font(.caption).foregroundStyle(.orange)
                }
                if !JITBootstrap.ready {
                    Button {
                        jit.enable()
                    } label: {
                        Label("使用 \(jit.resolvedMethod.title) 开启 JIT", systemImage: "bolt.fill")
                    }
                    .disabled(jit.busy)
                    Button {
                        _ = JITBootstrap.requestTrollStoreAttach()
                    } label: {
                        Label("使用 TrollStore 开启 JIT", systemImage: "sparkles")
                    }
                }
            } header: {
                Text("JIT 诊断信息")
            } footer: {
                Text("Husk 需要同时可写可执行的代码内存。在 iOS 上这通常需要附加调试器。系统提供两种途径：由调试器响应陷阱请求，或通过内核允许的 MAP_JIT 映射。满足其一即可。")
            }

            if JITBootstrap.isInstalledWithTrollStore {
                Section {
                    Toggle("启动时通过 TrollStore 自动开启 JIT", isOn: $trollStoreJIT)
                } footer: {
                    Text("每次打开 Husk 时若未开启 JIT，将自动唤起 TrollStore 开启。需要开启 TrollStore 的 URL Scheme 设置。")
                }
            }

            Section {
                Toggle("启动时自动开启 JIT", isOn: $autoJIT)
                    .disabled(!HuskBuiltInJIT.isAvailable)
            } footer: {
                Text(HuskBuiltInJIT.isAvailable
                     ? "Each time Husk opens without JIT, it asks the built-in StikJIT to turn it on, so games are ready "
                       + "without a tap. Needs StikJIT set up once (paired) first."
                     : "Needs the built-in StikJIT, which is available on iOS 26 and later.")
            }

            Section {
                Toggle("启动时自动启动 Android", isOn: $autoStart)
                    .onChange(of: autoStart) { v in
                        UserDefaults.standard.set(v, forKey: "husk.autoStart")
                    }
            } footer: {
                Text("当 JIT 可用时，打开 Husk 立即自动启动虚拟机。")
            }

            Section {
                Toggle("保持调试器持续附加", isOn: $keepAttached)
                    .onChange(of: keepAttached) { v in JITBootstrap.keepDebuggerAttached = v }
            } footer: {
                Text("默认关闭。Husk 在申请到 JIT 内存区后会自动分离 StikDebug，避免调试器被系统挂起导致应用冻结。仅在抓取 StikDebug 本身日志时开启。")
            }

            Section {
                Text("可通过游戏库的 + 按钮或“文件”标签页安装 APK。分卷/拆分包（基础 APK 与配置拆分项）必须一同选中安装；仅安装基础 APK 会因缺少原生动态库而报错。")
                    .font(.footnote).foregroundStyle(.secondary)
            } header: {
                Text("侧载与安装说明")
            }
        }
        .huskForm()
        .navigationTitle("JIT 与侧载设置")
    }
}

// MARK: - Saved machine

struct SavedMachineSettings: View {
    @ObservedObject private var runner = QemuRunner.shared
    @State private var autoSave =
        UserDefaults.standard.object(forKey: "husk.autoSave") as? Bool ?? true
    @State private var useSnapshot =
        UserDefaults.standard.object(forKey: "husk.downloadSnapshot") as? Bool ?? true
    @State private var askWhichToDelete = false
    @State private var deleteResult: String?
    @State private var askRemoveAndroid = false
    @State private var removeResult: String?
    @State private var androidBytes = GuestImage.shared.androidBytes
    @AppStorage(GuestImage.askUpdatesKey) private var askUpdates = true

    var body: some View {
        Form {
            Section {
                Toggle("自动保存快照", isOn: $autoSave)
                    .onChange(of: autoSave) { v in
                        UserDefaults.standard.set(v, forKey: "husk.autoSave")
                        HuskLog.log("ui", v ? "automatic saving on" : "automatic saving off")
                    }
                Button {
                    QemuRunner.shared.saveState(reason: "asked from settings")
                } label: {
                    Label(runner.isSavingState ? "正在保存…" : "立即保存快照",
                          systemImage: "externaldrive.badge.checkmark")
                }
                .disabled(runner.isSavingState)
            } footer: {
                Text("Husk 优先恢复已保存的虚拟机快照而不是冷启动，只需几秒即可进入系统。写入快照时画面会暂时冻结。关闭此项后不会自动保存快照。")
            }

            Section {
                Button(role: .destructive) { askWhichToDelete = true } label: {
                    Label("删除已保存的快照", systemImage: "trash")
                }
                .disabled(!QemuRunner.shared.hasSnapshot)
                if let deleteResult {
                    Text(deleteResult).font(.caption).foregroundStyle(.secondary)
                }
            } footer: {
                Text(QemuRunner.shared.hasSnapshot
                     ? "当前保存的快照渲染模式："
                     + ((QemuRunner.shared.snapshotDisplay ?? "sw").contains("gl")
                        ? "GPU 硬件加速" : "CPU 软件渲染") + "。"
                     : "当前没有已保存的快照，Android 将进行冷启动。")
            }

            Section {
                Toggle("下载预启动的开机快照", isOn: $useSnapshot)
                    .onChange(of: useSnapshot) { v in
                        UserDefaults.standard.set(v, forKey: "husk.downloadSnapshot")
                    }
            } footer: {
                Text("首次下载时额外增加约 2 GB。该快照在 CPU 软件渲染模式下录制，因此在 GPU 模式下不会直接加载（GPU 模式将冷启动一次并保存专属快照）。")
            }

            Section {
                Button(role: .destructive) { askRemoveAndroid = true } label: {
                    Label("清除 Android 所有文件", systemImage: "trash.slash")
                }
                .disabled(runner.isRunning || androidBytes == 0)
                if let removeResult {
                    Text(removeResult).font(.caption).foregroundStyle(.secondary)
                }
            } footer: {
                Text(androidBytes > 0
                     ? "Android's system, its data and the saved machine take \(ByteCountFormatter.string(fromByteCount: androidBytes, countStyle: .file)). "
                     + "Apps and games on the translation layer do not need them. Android downloads again the next time it is started."
                     : "Android is not downloaded.")
            }

            Section {
                Toggle("检查 Android 镜像更新", isOn: $askUpdates)
            } footer: {
                Text("当发布新的 Android 系统镜像或快照时，Husk 会提示是否下载更新。在尚未下载 Android 时不会提示。")
            }
        }
        .huskForm()
        .navigationTitle("虚拟机快照与存档")
        .confirmationDialog("选择要删除的快照？", isPresented: $askWhichToDelete,
                            titleVisibility: .visible) {
            Button("GPU 硬件加速快照", role: .destructive) { forget("gl", "GPU 硬件加速") }
            Button("CPU 软件渲染快照", role: .destructive) { forget("sw", "CPU 软件渲染") }
            Button("取消", role: .cancel) { }
        } message: {
            Text("删除后 Android 将进行一次冷启动，随后自动保存新快照。")
        }
        .confirmationDialog("确认清除 Android 文件？", isPresented: $askRemoveAndroid, titleVisibility: .visible) {
            Button("彻底清除 Android", role: .destructive) {
                let freed = GuestImage.shared.removeAll()
                androidBytes = GuestImage.shared.androidBytes
                removeResult = "已释放 \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))。"
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("将删除 Android 模拟器内的所有已安装应用与存档数据。翻译层的应用数据不受影响。")
        }
    }

    private func forget(_ mode: String, _ name: String) {
        if QemuRunner.shared.forgetSnapshot(mode: mode) {
            deleteResult = "已删除 \(name) 快照。下次启动将进行冷启动。"
        } else {
            deleteResult = "未找到已保存的 \(name) 快照，未删除任何内容。"
        }
    }
}

// MARK: - Appearance

struct AppearanceSettings: View {
    @State private var appIcon = HuskAppIcon.current
    @AppStorage(Theme.Appearance.key) private var appearance = Theme.Appearance.system
    @AppStorage(Holiday.key) private var holiday = true
    @ObservedObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var scheme
    @State private var custom: Color = AppTheme.shared.accentColor

    private let iconColumns = [GridItem(.adaptive(minimum: 92), spacing: 14)]

    var body: some View {
        Form {
            Section {
                Picker("外观模式", selection: $appearance) {
                    ForEach(Theme.Appearance.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: appearance) { v in
                    HuskLog.log("ui", "appearance: \(v.rawValue)")
                }
                Toggle("节日装饰特效", isOn: $holiday)
            } header: {
                Text("主题外观")
            } footer: {
                Text("“跟随系统”将匹配手机的深浅色设置。虚拟机屏幕本身始终保持暗色背景。节日特效在每年 12 月至 1 月初自动显示。")
            }

            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                    ForEach(AppTheme.presets) { preset in
                        Button {
                            theme.accentColor = preset.color
                            custom = preset.color
                        } label: {
                            swatch(preset.color, selected: preset.color.themeHex == theme.accentColor.themeHex)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(preset.name)
                    }
                }
                .padding(.vertical, 6)

                ColorPicker("自定义强调色", selection: $custom, supportsOpacity: false)
                    .onChange(of: custom) { theme.accentColor = $0 }
            } header: {
                Text("强调色")
            } footer: {
                Text("设置全局按钮、开关与高亮选中状态的主题色。")
            }

            Section {
                LazyVGrid(columns: iconColumns, spacing: 14) {
                    ForEach(HuskAppIcon.allCases) { icon in
                        Button {
                            appIcon = icon
                            HuskAppIcon.apply(icon)
                        } label: {
                            VStack(spacing: 8) {
                                if let art = icon.preview(dark: scheme == .dark) {
                                    Image(uiImage: art)
                                        .resizable().scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(appIcon == icon ? Color.accentColor : .clear, lineWidth: 3))
                                }
                                Text(icon.title)
                                    .font(.caption)
                                    .foregroundStyle(appIcon == icon ? Color.accentColor : .primary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Text("应用图标")
            } footer: {
                Text("“自动”选项将跟随系统外观（浅色、深色、着色）。其他选项将固定为指定图标。更改图标时 iOS 会弹出系统确认提示，该提示无法关闭。")
            }
        }
        .navigationTitle("外观设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func swatch(_ color: Color, selected: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 34, height: 34)
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.9), lineWidth: selected ? 2 : 0).padding(-4))
            .overlay {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color.isLight ? .black : .white)
                }
            }
            .frame(maxWidth: .infinity)
    }
}

// MARK: - About

struct AboutSettings: View {
    @ObservedObject private var runner = QemuRunner.shared
    @State private var showLogs = false
    @AppStorage(TranslationLayer.devInfoKey) private var devInfo = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    HuskMark(size: 84)
                    Text("Husk").font(.title2.weight(.semibold))
                    Text("Version \(Bundle.main.version)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("构建编号", value: Bundle.main.commit)
                LabeledContent("虚拟机版本", value: GuestImage.imageVersion)
                LabeledContent("渲染器",
                               value: runner.displayKind == .gl ? "GPU 硬件加速"
                                    : runner.displayKind == .software ? "CPU 软件渲染"
                                    : "未启动")
            }

            Section {
                Toggle(isOn: $devInfo) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("开发者调试信息")
                        Text("在 Android 翻译层各界面展示技术细节：动态库日志、设备检测与运行日志。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if devInfo {
                    NavigationLink { TLChecksView() } label: {
                        Label("设备环境检测", systemImage: "stethoscope")
                    }
                    NavigationLink { MassTestView() } label: {
                        Label("批量兼容性测试", systemImage: "square.stack.3d.down.forward")
                    }
                }
                Button { showLogs = true } label: {
                    Label("打开控制台日志", systemImage: "terminal")
                }
            } footer: {
                Text("Husk 允许在 iPhone 上直接运行未经修改的原生 Android APK。控制台展示 Husk 实时运行日志、虚拟机串口输出及 QEMU 输出日志。")
            }
        }
        .navigationTitle("关于 Husk")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogs) { LogView() }
    }
}

extension Bundle {
    var version: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"
    }
    var commit: String {
        (infoDictionary?["HuskBuildCommit"] as? String) ?? "?"
    }
}
