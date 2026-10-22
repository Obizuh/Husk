// SPDX-License-Identifier: GPL-2.0-or-later
import SwiftUI

// MARK: - what's new

/// What this version brought, shown once after updating to it (not on a first install: onboarding is the welcome then).
enum WhatsNew {
    struct Item: Identifiable {
        let symbol: String
        let title: String
        let detail: String
        var id: String { title }
    }

    /// The version whose notes these are. A build of the same version shows nothing again.
    static let version = "3.0.0"
    static let items: [Item] = [
        Item(symbol: "gamecontroller.fill", title: "全新 Husk 体验",
             detail: "主机风格的主屏幕：应用陈列在书架上，选中即可全屏展示精美海报，一键点击“开始游戏”。Android 与 PS4 游戏并排呈现，全新设计的游戏库，完美适配深浅色外观。"),
        Item(symbol: "playstation.logo", title: "PS4 游戏运行",
             detail: "点击 + 号即可添加 PS4 假包 (.pkg)、包文件夹或解压后的游戏文件夹，并直接在游戏库中启动。更新补丁可自动识别归档，着色器缓存跨次启动保持，支持虚拟键盘输入游戏名。"),
        Item(symbol: "square.stack.3d.up.fill", title: "新增支持数百款 Android 游戏",
             detail: "兼容性列表中新增数百款可完美运行的游戏，支持 Sonic Robo Blast 2、Ring Racers、NetHack、PokeWilds 等非官方移植版，修复 Flutter 游戏黑屏，支持 Godot 4 及 Python 游戏网络连接。"),
        Item(symbol: "arrow.down.circle.fill", title: "完整的商店下载功能",
             detail: "带 OBB 数据包的游戏在下载时将自动完整下载，拆分包 (Split APKs) 可直接加载安装。"),
        Item(symbol: "keyboard.fill", title: "全局虚拟键盘呼出",
             detail: "Unity、Java、Flutter、cocos2d-x 及 SDL 游戏内的输入框均可正常唤起 iOS 软键盘输入。"),
        Item(symbol: "textformat", title: "中日韩文字体支持",
             detail: "前往“设置 › 字体设置”一键下载 Noto Sans CJK 字体，彻底告别游戏中文方块乱码。"),
        Item(symbol: "bolt.fill", title: "自动化 JIT 体验",
             detail: "TrollStore 安装用户可在打开时自动唤起开启 JIT，并在缺少 JIT 时给出清晰直观的屏幕提示。"),
        Item(symbol: "iphone", title: "兼容 iOS 15 系统",
             detail: "Husk 现已支持最低 iOS 15.5 及更高版本（PS4 游戏需 iOS 17.4+）。"),
        Item(symbol: "wrench.and.screwdriver.fill", title: "稳定性与问题修复",
             detail: "修复 Android 镜像下载后闪退的问题，将完整模拟器移入设置中并配有安全提示，从多任务上滑退出不再误报崩溃，以及众多底层优化。"),
    ]

    private static let seenKey = "husk.whatsNew.seen"

    /// Whether to show the notes now: an update to this version, not a new install.
    static var due: Bool {
        let seen = UserDefaults.standard.string(forKey: seenKey)
        if seen == version { return false }
        if Onboarding.needed { markSeen(); return false }       // a first install: onboarding welcomes them
        return true
    }

    static func markSeen() { UserDefaults.standard.set(version, forKey: seenKey) }
}

struct WhatsNewSheet: View {
    var done: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Husk \(WhatsNew.version) 新特性").font(.largeTitle.weight(.bold))
                        Text("全新视觉设计、PS4 游戏支持及数百款 Android 游戏适配。").foregroundStyle(.secondary)
                    }
                    .padding(.top, 36)
                    ForEach(WhatsNew.items) { item in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 26))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(.headline)
                                Text(item.detail).font(.subheadline).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            }
            Button(action: done) {
                Text("继续").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - a newer Husk

/// A newer Husk on GitHub: the releases page is asked at launch (at most twice a day) and the person is told once per release.
@MainActor
final class AppUpdates: ObservableObject {
    static let shared = AppUpdates()

    struct Release: Equatable {
        let version: String
        let page: URL
    }

    @Published var available: Release?

    private static let api = URL(string: "https://api.github.com/repos/Leviidev/Husk/releases/latest")!
    private static let checkedKey = "husk.updates.checked", dismissedKey = "husk.updates.dismissed"

    static var current: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0" }

    func check() async {
        let d = UserDefaults.standard
        if Date().timeIntervalSince1970 - d.double(forKey: Self.checkedKey) < 12 * 3600 { return }
        var req = URLRequest(url: Self.api)
        req.timeoutInterval = 20
        req.setValue("Husk", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = obj["tag_name"] as? String,
              let page = (obj["html_url"] as? String).flatMap(URL.init(string:)) else { return }
        d.set(Date().timeIntervalSince1970, forKey: Self.checkedKey)
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        guard Self.newer(version, than: Self.current), d.string(forKey: Self.dismissedKey) != version else { return }
        HuskLog.log("update", "Husk \(version) is out (this is \(Self.current))")
        available = Release(version: version, page: page)
    }

    func dismiss() {
        if let v = available?.version { UserDefaults.standard.set(v, forKey: Self.dismissedKey) }
        available = nil
    }

    /// "1.0.10" is newer than "1.0.9": compared number by number.
    static func newer(_ a: String, than b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }
}
