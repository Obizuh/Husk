// SPDX-License-Identifier: GPL-2.0-or-later
import SwiftUI

/// Help: common problems and what to do about them, so a user stuck on JIT or on an app that will not open has an answer
/// without leaving Husk. A page in Settings (it was a tab of its own; four tabs read simpler than five).
struct FAQTab: View {
    @State private var query = ""

    private var sections: [FAQ.Section] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return FAQ.sections }
        return FAQ.sections.compactMap { s in
            let items = s.items.filter { $0.question.localizedCaseInsensitiveContains(q) || $0.answer.localizedCaseInsensitiveContains(q) }
            return items.isEmpty ? nil : FAQ.Section(title: s.title, symbol: s.symbol, items: items)
        }
    }

    var body: some View {
            List {
                ForEach(sections) { s in
                    Section {
                        ForEach(s.items) { item in FAQRow(item: item, expanded: !query.isEmpty) }
                    } header: {
                        Label(s.title, systemImage: s.symbol)
                    }
                }
                if sections.isEmpty {
                    Text("未找到与“\(query)”匹配的常见问题。可打开“设置 › 关于 Husk › 打开控制台日志”查看运行状态。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("帮助与常见问题")
            .searchable(text: $query, prompt: "搜索问题与故障排查")
    }
}

private struct FAQRow: View {
    let item: FAQ.Item
    var expanded: Bool
    @State private var open = false

    var body: some View {
        DisclosureGroup(isExpanded: Binding(get: { open || expanded }, set: { open = $0 })) {
            Text(.init(item.answer))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
        } label: {
            Text(item.question).font(.body.weight(.medium))
        }
    }
}

enum FAQ {
    struct Item: Identifiable { let question: String; let answer: String; var id: String { question } }
    struct Section: Identifiable { let title: String; let symbol: String; let items: [Item]; var id: String { title } }

    static let sections: [Section] = [
        Section(title: "JIT 与可执行内存", symbol: "bolt.fill", items: [
            Item(question: "什么是 JIT，为什么 Husk 必须需要它？",
                 answer: "Android 应用和游戏在运行时进行即时编译，这需要系统授予同时具备可写入和可执行权限的内存空间。"
                       + "iOS 系统出于安全策略，仅在调试器附加到应用时才允许此权限。开启 JIT 就是临时附加调试器以解锁该权限。"
                       + "若没有 JIT，Husk 可以浏览游戏库，但无法启动 Android 系统或运行游戏。"),
            Item(question: "我应该使用哪种 JIT 开启方式？",
                 answer: "• **iOS 17 及以上：** 设置 › JIT › 在本机配对。无需电脑，全自动化。\n"
                       + "• **iOS 16：** 使用内置 StikJIT 搭配电脑端配对文件 + LocalDevVPN。\n"
                       + "• **旧版 iOS 或 LiveContainer 内运行：** 使用 StikDebug 独立 App。\n"
                       + "• **TrollStore 安装：** 使用 TrollStore，并确保其 URL Scheme 开关已打开。\n"
                       + "• **Dopamine 越狱环境：** 在越狱设置中开启对应用的 JIT 权限。"),
            Item(question: "StikJIT 提示无法连接，或开启 JIT 失败怎么办？",
                 answer: "1. 确保已安装并连接 **LocalDevVPN**（状态栏应显示 VPN 图标）。\n"
                       + "2. 必须开启 Wi-Fi（即便完全不连接外网）。\n"
                       + "3. 必须在系统“设置 › 隐私与安全性 › 开发者模式”中开启开发者模式。\n"
                       + "4. 首次使用时，Husk 需要下载苹果开发者镜像包（可能耗时一两分钟），请等待完成。\n"
                       + "5. 仍然失败？请尝试开关一次 LocalDevVPN，然后重新配对。"),
            Item(question: "开发者模式中没有出现“与 Husk 配对”提示",
                 answer: "请先在 Husk 中点击“开始配对”，并在系统弹出弹窗时允许“本地网络”权限。如果曾误点拒绝，"
                       + "请前往系统“设置 › 隐私与安全性 › 本地网络 › Husk”手动开启。同时 Wi-Fi 必须保持开启，"
                       + "开发者模式已启用（首次启用需重启手机）。"),
            Item(question: "配对文件失效了怎么办？",
                 answer: "当重置 iPhone 信任证书或系统更新后，配对文件可能会失效。"
                       + "请重新生成配对文件（iOS 17 可直接在本机完成配对），然后在“设置 › JIT”中重新导入。"),
            Item(question: "StikDebug 可以打开，但 JIT 依然显示未开启",
                 answer: "请单独打开 StikDebug 检查是否已导入配对文件且 LocalDevVPN 是否已连接。"
                       + "请确保更新 StikDebug 到最新版本。Husk 会自行向 StikDebug 发送执行脚本，无需在 StikDebug 内部特殊配置。"),
            Item(question: "为什么每次重新打开应用都要重新开启 JIT？",
                 answer: "JIT 权限仅在 Husk 进程运行期间持续有效。当 iOS 在后台清理了 Husk，或您手动上滑杀后台后，"
                       + "下次重新打开均需重新激活 JIT。通过本机配对或保存的配对文件，只需一键即可重新开启。"),
            Item(question: "可以在没有 JIT 的情况下使用 Husk 吗？",
                 answer: "可以浏览和导入应用，但无法运行任何 Android 内容。所有游戏和应用启动均必须依赖 JIT。"),
        ]),
        Section(title: "Husk 软件本身", symbol: "app.badge", items: [
            Item(question: "Husk 完全打不开或闪退",
                 answer: "• **打开后瞬间闪退：** 签名证书可能已过期（免费个人证书通常为 7 天有效期）。请使用侧载工具（如 AltStore/SideStore）重新签名安装，您的应用和存档数据都会完整保留。\n"
                       + "• **提示“不受信任的开发者”：** 前往系统“设置 › 通用 › VPN 与设备管理”信任证书。\n"
                       + "• **提示需要开发者模式：** 前往“设置 › 隐私与安全性”开启开发者模式。"),
            Item(question: "游戏中途崩溃闪退了",
                 answer: "重新打开 Husk 时会弹出崩溃诊断报告，您可以直接分享此报告。崩溃通常是因为设备内存不足（OOM）"
                       + "或触及了翻译层尚未适配的底层接口。请关闭后台其他应用，若频繁崩溃可提交报告以便适配。"),
            Item(question: "如何获取日志以反馈问题？",
                 answer: "打开游戏库中的应用详情页，点击**分享报告**。如需 Husk 核心日志，可前往"
                       + "“设置 › 关于 Husk › **打开控制台日志**”，开启“开发者调试信息”可查看更详细的动态库调用。"),
            Item(question: "如何更新 Husk？",
                 answer: "新版本发布时 Husk 会主动提示。使用同一个侧载工具将新版 IPA 覆盖安装即可，"
                       + "您的游戏库、已装应用和存档均会完好保留。"),
        ]),
        Section(title: "游戏与应用运行", symbol: "gamecontroller.fill", items: [
            Item(question: "如何添加 PS4 游戏？",
                 answer: "点击 + 号，选择伪装安装包 (.pkg)、包文件夹或已解压的游戏文件夹（包含 eboot.bin 与 sce_sys）。"
                       + "Husk 会将其导入“文件”中的 PS4 Games 目录。官方原版光盘 dump 包因加密锁机无法运行。PS4 游戏需要 iOS 17.4 或更高系统。"),
            Item(question: "应用打不开的原因？",
                 answer: "在游戏库中打开该应用页面，Husk 会标明原因：\n"
                       + "• **带有安全保护：** 应用检测真机环境、反作弊或 DRM 保护，Husk 目前不绕过此类防护。\n"
                       + "• **CPU 架构不匹配：** 该 APK 仅包含 32 位二进制，iPhone 硬件仅支持 64 位，请寻找 arm64-v8a 版本。\n"
                       + "• **缺少游戏数据包：** APK 需要配套的拆分数据包或 OBB 数据包。请导入完整 .xapk/.apkm。\n"
                       + "• **强依赖 Google 框架：** 该应用依赖 Husk 无法提供的 Google Play 认证服务。\n"
                       + "• **遇到未适配接口：** 请分享崩溃报告以便开发者添加支持。"),
            Item(question: "启动后黑屏怎么办？",
                 answer: "大型游戏首次启动需要解包和预编译数据，可能需要等待多达一分钟。"
                       + "若之后仍黑屏，请退出重开一次；若依旧黑屏请分享崩溃报告。"),
            Item(question: "改包或修改版 APK 闪退",
                 answer: "第三方修改版常对其自身代码进行深度混淆或加入防篡改校验，极易发生崩溃。"
                       + "建议使用开发者原版 APK 或从 APKMirror 下载纯净版。"),
            Item(question: "支持导入哪些文件？",
                 answer: ".apk，以及包含拆分包的 .apks、.xapk、.apkm。直接分享至 Husk、“文件”中打开或点击游戏库 + 号均可。"),
            Item(question: "运行卡顿或手机发烫",
                 answer: "建议关闭其他后台应用并摘下保护壳散热。游戏以原生指令集执行，但部分图形着色器在 iPhone 上需软转译。"
                       + "低电量模式也会大幅限制 CPU 性能导致卡顿。"),
            Item(question: "手柄可以使用吗？",
                 answer: "可以。在 iPhone 蓝牙设置中连接手柄后，支持手柄控制的游戏可直接识别并操作。"),
            Item(question: "玩游戏时可以切出来用 Husk 吗？",
                 answer: "可以在设置中开启**以窗口化方式打开应用**。开启后游戏将在可移动、缩放和最小化的独立窗口中运行。"),
            Item(question: "Google 登录无法使用",
                 answer: "Husk 不包含 Google Play 专有服务，因此“使用 Google 账号登录”会失败。如游戏支持，请使用邮箱或游客登录。"),
        ]),
        Section(title: "存档与存储空间", symbol: "externaldrive.fill", items: [
            Item(question: "我的游戏存档在哪里？",
                 answer: "每个应用的数据都保存在 Husk 内部沙盒。在应用详情页中，**备份存档**可导出为 zip 压缩包，**恢复存档**可重新导入（支持跨设备迁移）。"),
            Item(question: "Husk 占用了大量存储空间",
                 answer: "导入的应用和数据均存放在 Husk 目录。可在详情页删除不再游玩的游戏。"
                       + "完整的 Android 模拟器系统镜像约额外占用 2 GB 空间。"),
        ]),
        Section(title: "Android 模拟器", symbol: "cpu", items: [
            Item(question: "翻译层和 Android 模拟器有什么区别？",
                 answer: "绝大部分应用和游戏通过翻译层（Translation Layer）在 iPhone 上原生执行，速度极快；"
                       + "完整的 Android 模拟器是运行在 QEMU 中的完整虚拟机，速度较慢，主要用于运行无法在翻译层启动的应用。"),
            Item(question: "Android 模拟器启动很慢",
                 answer: "首次启动需要解压并进行冷启动，需要数分钟。之后 Husk 会直接从保存的内存快照中恢复，几秒即可进入桌面。"),
        ]),
    ]
}
