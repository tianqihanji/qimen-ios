import Foundation

/// 定局法
enum JuMethod: String, CaseIterable, Identifiable {
    case chaibu = "拆补法"
    case zhirun = "置闰法"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .chaibu:
            return "以交节时刻定节气，以日之符头定元。节气为尊，上元天数不足时从下一节气拆补。现行排盘软件普遍采用。"
        case .zhirun:
            return "以符头为尊的古法。芒种、大雪超神超过九天时于节气末重复上中下三元，用以抹平符头与节气的累积误差。"
        }
    }
}

/// 时间取用方式
enum TimeSource: String, CaseIterable, Identifiable {
    case standard = "标准时"
    case trueSolar = "真太阳时"

    var id: String { rawValue }
}

/// 单个宫位
struct QimenPalace: Identifiable {
    let id: Int                    // 宫数 1~9
    let god: String                // 八神
    let star: String               // 九星
    let door: String               // 八门
    let heavenGan: [String]        // 天盘干（中五宫寄干会一并带入）
    let earthGan: String           // 地盘干

    var isEmpty: Bool { id == 5 }
}

/// 一张完整的时家奇门转盘
struct QimenChart {

    let yearPillar: String
    let monthPillar: String
    let dayPillar: String
    let hourPillar: String

    let term: SolarTerm
    let yuan: String
    let isYang: Bool
    let ju: Int
    let method: JuMethod

    let xunHead: String
    let xunYi: String
    let zhiFuStar: String
    let zhiShiDoor: String
    let zhiFuPalace: Int
    let zhiShiPalace: Int
    let kongWang: String
    let maXing: String
    let maXingPalace: Int

    let palaces: [QimenPalace]

    /// 起局所用时刻（按取用方式换算后）
    let moment: Date
    let timeLabel: String
    let usedTrueSolar: Bool

    var fourPillars: String {
        "\(yearPillar) \(monthPillar) \(dayPillar) \(hourPillar)"
    }

    var juLabel: String {
        (isYang ? "阳遁" : "阴遁") + "\(ju)局"
    }

    var juAndYuan: String {
        "\(juLabel) · \(term.name)\(yuan)"
    }

    func palace(_ index: Int) -> QimenPalace? {
        palaces.first { $0.id == index }
    }
}
