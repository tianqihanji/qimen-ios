import Foundation

/// 天文与干支历基础运算
enum Astro {

    static let gan: [Character] = Array("甲乙丙丁戊己庚辛壬癸")
    static let zhi: [Character] = Array("子丑寅卯辰巳午未申酉戌亥")

    /// 儒略日数（该日 0 时的 JDN）
    static func julianDayNumber(year: Int, month: Int, day: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
    }

    /// 日柱序号（0 = 甲子）
    static func dayPillarIndex(year: Int, month: Int, day: Int) -> Int {
        var v = (julianDayNumber(year: year, month: month, day: day) + 49) % 60
        if v < 0 { v += 60 }
        return v
    }

    static func name(ofIndex index: Int) -> String {
        String(gan[index % 10]) + String(zhi[index % 12])
    }

    /// 由年、月、日、时、分与地方时区偏差计算 UT 儒略日
    static func julianDay(year: Int, month: Int, day: Int,
                          hour: Int, minute: Int, utcOffsetHours: Double) -> Double {
        Double(julianDayNumber(year: year, month: month, day: day)) - 0.5
            + (Double(hour) - utcOffsetHours + Double(minute) / 60.0) / 24.0
    }

    /// 太阳视黄经（Meeus 低精度算法，误差约 0.01°，折合时间约 6 分钟）
    static func solarApparentLongitude(julianDay jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        let m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        let mr = m * .pi / 180
        let c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(mr)
            + (0.019993 - 0.000101 * t) * sin(2 * mr)
            + 0.000289 * sin(3 * mr)
        let omega = (125.04 - 1934.136 * t) * .pi / 180
        var lambda = (l0 + c) - 0.00569 - 0.00478 * sin(omega)
        lambda = lambda.truncatingRemainder(dividingBy: 360)
        if lambda < 0 { lambda += 360 }
        return lambda
    }

    /// 牛顿迭代求太阳视黄经等于 target 的儒略日
    static func solveSolarTerm(target: Double, guess: Double) -> Double {
        var jd = guess
        for _ in 0..<64 {
            let lambda = solarApparentLongitude(julianDay: jd)
            var d = (target - lambda + 540).truncatingRemainder(dividingBy: 360)
            if d < 0 { d += 360 }
            let diff = d - 180
            jd += diff / 0.9856473
            if abs(diff) < 1e-8 { break }
        }
        return jd
    }

    struct TermMoment {
        let term: SolarTerm
        let julianDay: Double
    }

    /// 指定年度的二十四个节气交节时刻（按立春起序，儒略日按给定时区偏移换算）
    static func termMoments(year: Int, utcOffsetHours: Double) -> [TermMoment] {
        var result: [TermMoment] = []
        let base = Double(julianDayNumber(year: year, month: 2, day: 4)) - 0.5
        for term in SolarTerm.allCases {
            var guess = base + Double(term.rawValue) * 15.22
            let lambda = solarApparentLongitude(julianDay: guess)
            var d = (term.longitude - lambda + 540).truncatingRemainder(dividingBy: 360)
            if d < 0 { d += 360 }
            guess += (d - 180) / 0.9856473
            let solved = solveSolarTerm(target: term.longitude, guess: guess)
            result.append(TermMoment(term: term, julianDay: solved + utcOffsetHours / 24.0))
        }
        return result
    }

    /// 查找某一时刻所处的节气（区间为「本节气交节时刻 ~ 下一节气交节时刻」）
    static func term(atJulianDay jd: Double, year: Int, utcOffsetHours: Double) -> (current: TermMoment, next: TermMoment) {
        let pool = termMoments(year: year - 1, utcOffsetHours: utcOffsetHours)
            + termMoments(year: year, utcOffsetHours: utcOffsetHours)
            + termMoments(year: year + 1, utcOffsetHours: utcOffsetHours)
        let past = pool.filter { $0.julianDay <= jd }
        let current = past.max { $0.julianDay < $1.julianDay } ?? pool[0]
        let next = pool.filter { $0.julianDay > jd }.min { $0.julianDay < $1.julianDay } ?? current
        return (current, next)
    }
}
