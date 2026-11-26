import Foundation

/// 时家奇门转盘排盘引擎
enum QimenEngine {

    // MARK: - 对外入口

    static func makeChart(date: Date,
                          timeZone: TimeZone,
                          method: JuMethod,
                          useTrueSolar: Bool,
                          longitude: Double?) -> QimenChart {

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let offsetHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0

        // ---- 真太阳时校正 ----
        var effectiveDate = date
        if useTrueSolar, let lon = longitude {
            let c0 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let jd0 = Astro.julianDay(year: c0.year ?? 2000,
                                      month: c0.month ?? 1,
                                      day: c0.day ?? 1,
                                      hour: c0.hour ?? 0,
                                      minute: c0.minute ?? 0,
                                      utcOffsetHours: offsetHours)
            let standardMeridian = 15.0 * offsetHours
            let minutes = (lon - standardMeridian) * 4.0
                + TrueSolarTime.equationOfTimeMinutes(julianDay: jd0)
            effectiveDate = date.addingTimeInterval(minutes * 60.0)
        }

        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: effectiveDate)
        let y = comps.year ?? 2000
        let mo = comps.month ?? 1
        let d = comps.day ?? 1
        let h = comps.hour ?? 0
        let mi = comps.minute ?? 0

        let jd = Astro.julianDay(year: y, month: mo, day: d,
                                 hour: h, minute: mi, utcOffsetHours: offsetHours)
        let (current, _) = Astro.term(atJulianDay: jd, year: y, utcOffsetHours: offsetHours)
        let term = current.term

        // ---- 四柱 ----
        let dayIdx = Astro.dayPillarIndex(year: y, month: mo, day: d)

        let termsOfYear = Astro.termMoments(year: y, utcOffsetHours: offsetHours)
        let lichun = termsOfYear.first { $0.term == .lichun }?.julianDay ?? 0
        let ganZhiYear = jd >= lichun ? y : y - 1
        var yearIdx = (ganZhiYear - 4) % 60
        if yearIdx < 0 { yearIdx += 60 }

        let monthZhi = term.monthZhiIndex
        let yearGan = yearIdx % 10
        let startMonthGan = (2 + 2 * (yearGan % 5)) % 10          // 五虎遁
        let monthGan = (startMonthGan + (monthZhi - 2 + 12) % 12) % 10
        let monthIdx = indexOf(gan: monthGan, zhi: monthZhi)

        let hourZhi = ((h + 1) / 2) % 12
        let baseDayForHour = (h == 23) ? (dayIdx + 1) % 60 : dayIdx   // 晚子时按次日日干
        let startHourGan = (2 * ((baseDayForHour % 10) % 5)) % 10     // 五鼠遁
        let hourGan = (startHourGan + hourZhi) % 10
        let hourIdx = indexOf(gan: hourGan, zhi: hourZhi)

        // ---- 定局：日之符头定元 ----
        let fork = futouBack(forDayIndex: dayIdx)
        var yuanIndex = yuanIndexFor(futouZhi: ((dayIdx - fork) % 12 + 12) % 12)

        if method == .zhirun,
           term == .mangzhong || term == .daxue {
            // 古法置闰：芒种、大雪超神满十天，于本节气末重复一轮上中下三元
            let termJDN = Int((current.julianDay + 0.5).rounded(.down))
            let termDayIndex = (termJDN + 49) % 60
            let chaoShenDays = futouBack(forDayIndex: termDayIndex)
            let todayJDN = Astro.julianDayNumber(year: y, month: mo, day: d)
            let dayOffset = todayJDN - termJDN
            if chaoShenDays >= 10 && dayOffset >= 15 {
                let shiftedIndex = (dayIdx - 15 + 60) % 60
                let shiftedFork = futouBack(forDayIndex: shiftedIndex)
                let shiftedZhi = ((shiftedIndex - shiftedFork) % 12 + 12) % 12
                yuanIndex = yuanIndexFor(futouZhi: shiftedZhi)
            }
        }

        let isYang = term.isYangDunTerm
        let table = isYang ? QimenConstants.juTableYang : QimenConstants.juTableYin
        let tuple = table[term] ?? (1, 7, 4)
        let ju = [tuple.0, tuple.1, tuple.2][yuanIndex]
        let yuanName = ["上元", "中元", "下元"][yuanIndex]

        // ---- 地盘三奇六仪 ----
        var diPan: [Int: String] = [:]
        var palace = ju
        for yi in QimenConstants.yiOrder {
            diPan[palace] = yi
            palace = isYang ? palace + 1 : palace - 1
            if palace > 9 { palace = 1 }
            if palace < 1 { palace = 9 }
        }

        // ---- 旬首、值符、值使 ----
        let xunIndex = hourIdx / 10
        let xunHead = QimenConstants.xunHeads[xunIndex]
        let xunYi = QimenConstants.xunYi[xunHead] ?? "戊"
        let stepInXun = hourIdx % 10 + 1

        let xunPalace = diPan.first { $0.value == xunYi }?.key ?? 1
        let zhiFuStar = QimenConstants.starOfPalace[xunPalace] ?? "天禽"
        let zhiShiDoor = QimenConstants.doorOfPalace[xunPalace] ?? "死门"

        // ---- 天盘：值符随时干，整盘沿八宫环转动 ----
        let hourGanChar = String(Astro.gan[hourIdx % 10])
        let hourGanPalace: Int
        if hourGanChar == "甲" {
            hourGanPalace = xunPalace
        } else {
            hourGanPalace = diPan.first { $0.value == hourGanChar }?.key ?? xunPalace
        }

        let posFu = QimenConstants.ringPosition(of: xunPalace)
        let posHour = QimenConstants.ringPosition(of: hourGanPalace)
        let offset = (posHour - posFu + 8) % 8

        // 地盘按八宫环排布，中五宫之干并入坤二
        var diRing: [[String]] = []
        for p in QimenConstants.ring {
            var value: [String] = []
            if let g = diPan[p] { value.append(g) }
            if p == 2, let center = diPan[5], center != diPan[2] {
                value.append(center)
            }
            diRing.append(value)
        }

        var heavenStar: [Int: String] = [:]
        var heavenGan: [Int: [String]] = [:]
        for j in 0..<8 {
            let src = (j - offset + 8) % 8
            let p = QimenConstants.ring[j]
            let srcPalace = QimenConstants.ring[src]
            var star = QimenConstants.starOfPalace[srcPalace] ?? "天芮"
            if srcPalace == 2 { star = "天芮·天禽" }
            heavenStar[p] = star
            heavenGan[p] = diRing[src]
        }

        // ---- 八门：值使从本宫起，依阳顺阴逆沿九宫飞布 ----
        var cursor = xunPalace
        if stepInXun > 1 {
            for _ in 1..<stepInXun {
                cursor = isYang ? cursor + 1 : cursor - 1
                if cursor > 9 { cursor = 1 }
                if cursor < 1 { cursor = 9 }
            }
        }
        let zhiShiPalace = cursor

        var doors: [Int: String] = [:]
        let zhiShiPos = QimenConstants.ringPosition(of: zhiShiPalace)
        let doorBase = QimenConstants.doorOrder.firstIndex(of: zhiShiDoor) ?? 0
        for j in 0..<8 {
            let p = QimenConstants.ring[(zhiShiPos + j) % 8]
            doors[p] = QimenConstants.doorOrder[(doorBase + j) % 8]
        }

        // ---- 八神：值符神随值符星宫，阳遁顺排、阴遁逆排 ----
        var gods: [Int: String] = [:]
        let godPos = QimenConstants.ringPosition(of: hourGanPalace)
        for j in 0..<8 {
            let idx = isYang ? (godPos + j) % 8 : (godPos - j + 8) % 8
            gods[QimenConstants.ring[idx]] = QimenConstants.godOrder[j]
        }

        // ---- 驿马 ----
        let horse = horseStar(forHourZhi: hourZhi)

        // ---- 组装 ----
        var palaces: [QimenPalace] = []
        for p in 1...9 {
            if p == 5 {
                palaces.append(QimenPalace(id: 5, god: "", star: "天禽", door: "",
                                           heavenGan: [], earthGan: diPan[5] ?? ""))
            } else {
                palaces.append(QimenPalace(id: p,
                                           god: gods[p] ?? "",
                                           star: heavenStar[p] ?? "",
                                           door: doors[p] ?? "",
                                           heavenGan: heavenGan[p] ?? [],
                                           earthGan: diPan[p] ?? ""))
            }
        }

        return QimenChart(
            yearPillar: Astro.name(ofIndex: yearIdx),
            monthPillar: Astro.name(ofIndex: monthIdx),
            dayPillar: Astro.name(ofIndex: dayIdx),
            hourPillar: Astro.name(ofIndex: hourIdx),
            term: term,
            yuan: yuanName,
            isYang: isYang,
            ju: ju,
            method: method,
            xunHead: xunHead,
            xunYi: xunYi,
            zhiFuStar: zhiFuStar,
            zhiShiDoor: zhiShiDoor,
            zhiFuPalace: hourGanPalace,
            zhiShiPalace: zhiShiPalace,
            kongWang: QimenConstants.xunKongWang[xunHead] ?? "",
            maXing: horse.name,
            maXingPalace: horse.palace,
            palaces: palaces.sorted { $0.id < $1.id },
            moment: effectiveDate,
            timeLabel: timeLabel(for: effectiveDate, timeZone: timeZone),
            usedTrueSolar: useTrueSolar && longitude != nil
        )
    }

    // MARK: - 辅助

    /// 六十甲子查索引
    private static func indexOf(gan: Int, zhi: Int) -> Int {
        for i in 0..<60 where i % 10 == gan && i % 12 == zhi {
            return i
        }
        return 0
    }

    /// 距最近「甲 / 己」日的天数差
    private static func futouBack(forDayIndex dayIndex: Int) -> Int {
        var back = 0
        while back < 10 {
            let g = (dayIndex - back) % 10
            if g == 0 || g == 5 { break }
            back += 1
        }
        return back
    }

    /// 符头地支定元：子午卯酉上元，寅申巳亥中元，辰戌丑未下元
    private static func yuanIndexFor(futouZhi: Int) -> Int {
        switch futouZhi {
        case 0, 6, 3, 9: return 0
        case 2, 8, 5, 11: return 1
        default: return 2
        }
    }

    /// 驿马：申子辰马在寅、寅午戌马在申、巳酉丑马在亥、亥卯未马在巳
    private static func horseStar(forHourZhi zhi: Int) -> (name: String, palace: Int) {
        switch zhi {
        case 8, 0, 4: return ("寅", 8)
        case 2, 6, 10: return ("申", 2)
        case 5, 9, 1: return ("亥", 6)
        default: return ("巳", 4)
        }
    }

    private static func timeLabel(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
