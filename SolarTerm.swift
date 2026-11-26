import Foundation

/// 二十四节气（立春起序，对应太阳视黄经 315° 起每 15° 一个）
enum SolarTerm: Int, CaseIterable, Identifiable {
    case lichun = 0      // 立春 315°
    case yushui          // 雨水 330°
    case jingzhe         // 惊蛰 345°
    case chunfen         // 春分 0°
    case qingming        // 清明 15°
    case guyu            // 谷雨 30°
    case lixia           // 立夏 45°
    case xiaoman         // 小满 60°
    case mangzhong       // 芒种 75°
    case xiazhi          // 夏至 90°
    case xiaoshu         // 小暑 105°
    case dashu           // 大暑 120°
    case liqiu           // 立秋 135°
    case chushu          // 处暑 150°
    case bailu           // 白露 165°
    case qiufen          // 秋分 180°
    case hanlu           // 寒露 195°
    case shuangjiang     // 霜降 210°
    case lidong          // 立冬 225°
    case xiaoxue         // 小雪 240°
    case daxue           // 大雪 255°
    case dongzhi         // 冬至 270°
    case xiaohan         // 小寒 285°
    case dahan           // 大寒 300°

    var id: Int { rawValue }

    private static let names = [
        "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
        "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
        "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
        "立冬", "小雪", "大雪", "冬至", "小寒", "大寒",
    ]

    var name: String { SolarTerm.names[rawValue] }

    /// 对应太阳视黄经（度）
    var longitude: Double { Double((315 + 15 * rawValue) % 360) }

    /// 是否属阳遁区间（冬至 ~ 夏至前）
    var isYangDunTerm: Bool {
        switch self {
        case .dongzhi, .xiaohan, .dahan, .lichun, .yushui, .jingzhe,
             .chunfen, .qingming, .guyu, .lixia, .xiaoman, .mangzhong:
            return true
        default:
            return false
        }
    }

    /// 月建地支序号（节令换月：立春起寅月）
    var monthZhiIndex: Int {
        switch self {
        case .lichun, .yushui: return 2      // 寅
        case .jingzhe, .chunfen: return 3    // 卯
        case .qingming, .guyu: return 4      // 辰
        case .lixia, .xiaoman: return 5      // 巳
        case .mangzhong, .xiazhi: return 6   // 午
        case .xiaoshu, .dashu: return 7      // 未
        case .liqiu, .chushu: return 8       // 申
        case .bailu, .qiufen: return 9       // 酉
        case .hanlu, .shuangjiang: return 10 // 戌
        case .lidong, .xiaoxue: return 11    // 亥
        case .daxue, .dongzhi: return 0      // 子
        case .xiaohan, .dahan: return 1      // 丑
        }
    }
}
