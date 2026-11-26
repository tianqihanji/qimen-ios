import Foundation

/// 奇门九宫与盘面常量
enum QimenConstants {

    /// 顺时针八宫环序（坎→艮→震→巽→离→坤→兑→乾）
    static let ring: [Int] = [1, 8, 3, 4, 9, 2, 7, 6]

    /// 洛书方位对应的屏幕角度（自正上方顺时针）
    static let palaceAngle: [Int: Double] = [
        1: 0, 8: 45, 3: 90, 4: 135, 9: 180, 2: 225, 7: 270, 6: 315, 5: 0,
    ]

    /// 宫名
    static let palaceName: [Int: String] = [
        1: "坎一宫", 2: "坤二宫", 3: "震三宫", 4: "巽四宫", 5: "中五宫",
        6: "乾六宫", 7: "兑七宫", 8: "艮八宫", 9: "离九宫",
    ]

    static let palaceShort: [Int: String] = [
        1: "坎1", 2: "坤2", 3: "震3", 4: "巽4", 5: "中5",
        6: "乾6", 7: "兑7", 8: "艮8", 9: "离9",
    ]

    static let palaceDirection: [Int: String] = [
        1: "正北", 2: "西南", 3: "正东", 4: "东南", 5: "中央",
        6: "西北", 7: "正西", 8: "东北", 9: "正南",
    ]

    static let palaceElement: [Int: String] = [
        1: "水", 2: "土", 3: "木", 4: "木", 5: "土",
        6: "金", 7: "金", 8: "土", 9: "火",
    ]

    /// 九星本宫
    static let starOfPalace: [Int: String] = [
        1: "天蓬", 8: "天任", 3: "天冲", 4: "天辅", 9: "天英",
        2: "天芮", 7: "天柱", 6: "天心", 5: "天禽",
    ]

    /// 八门本宫（中五宫无门，寄坤二）
    static let doorOfPalace: [Int: String] = [
        1: "休门", 8: "生门", 3: "伤门", 4: "杜门", 9: "景门",
        2: "死门", 7: "惊门", 6: "开门",
    ]

    static let starOrder: [String] = ["天蓬", "天任", "天冲", "天辅", "天英", "天芮", "天柱", "天心"]
    static let doorOrder: [String] = ["休门", "生门", "伤门", "杜门", "景门", "死门", "惊门", "开门"]
    static let godOrder: [String] = ["值符", "螣蛇", "太阴", "六合", "白虎", "玄武", "九地", "九天"]
    static let yiOrder: [String] = ["戊", "己", "庚", "辛", "壬", "癸", "丁", "丙", "乙"]

    /// 六旬
    static let xunHeads: [String] = ["甲子", "甲戌", "甲申", "甲午", "甲辰", "甲寅"]
    static let xunYi: [String: String] = [
        "甲子": "戊", "甲戌": "己", "甲申": "庚", "甲午": "辛", "甲辰": "壬", "甲寅": "癸",
    ]
    static let xunKongWang: [String: String] = [
        "甲子": "戌亥", "甲戌": "申酉", "甲申": "午未",
        "甲午": "辰巳", "甲辰": "寅卯", "甲寅": "子丑",
    ]

    /// 阳遁九局（节气 → 上元 / 中元 / 下元）
    static let juTableYang: [SolarTerm: (Int, Int, Int)] = [
        .dongzhi: (1, 7, 4), .xiaohan: (2, 8, 5), .dahan: (3, 9, 6),
        .lichun: (8, 5, 2), .yushui: (9, 6, 3), .jingzhe: (1, 7, 4),
        .chunfen: (3, 9, 6), .qingming: (4, 1, 7), .guyu: (5, 2, 8),
        .lixia: (4, 1, 7), .xiaoman: (5, 2, 8), .mangzhong: (6, 3, 9),
    ]

    /// 阴遁九局
    static let juTableYin: [SolarTerm: (Int, Int, Int)] = [
        .xiazhi: (9, 3, 6), .xiaoshu: (8, 2, 5), .dashu: (7, 1, 4),
        .liqiu: (2, 5, 8), .chushu: (1, 4, 7), .bailu: (9, 3, 6),
        .qiufen: (7, 1, 4), .hanlu: (6, 9, 3), .shuangjiang: (5, 8, 2),
        .lidong: (6, 9, 3), .xiaoxue: (5, 8, 2), .daxue: (4, 7, 1),
    ]

    /// 二十四山（自正北顺时针，每山 15°）
    static let mountains: [String] = [
        "子", "癸", "丑", "艮", "寅", "甲", "卯", "乙",
        "辰", "巽", "巳", "丙", "午", "丁", "未", "坤",
        "申", "庚", "酉", "辛", "戌", "乾", "亥", "壬",
    ]

    /// 九宫 → 八宫环索引（中五宫寄坤二）
    static func ringPosition(of palace: Int) -> Int {
        ring.firstIndex(of: palace == 5 ? 2 : palace) ?? 0
    }
}
