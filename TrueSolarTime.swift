import Foundation

/// 真太阳时与均时差
enum TrueSolarTime {

    /// 均时差（分钟）—— NOAA 算法，精度约 ±0.5 分钟
    static func equationOfTimeMinutes(julianDay jd: Double) -> Double {
        let civil = civilDate(fromJulianDay: jd)
        let jdnDay = Astro.julianDayNumber(year: civil.year, month: civil.month, day: civil.day)
        let dayOfYear = Double(jdnDay - Astro.julianDayNumber(year: civil.year, month: 1, day: 1) + 1)
        let hour = civil.hourUT

        let gamma = 2.0 * Double.pi / 365.0 * (dayOfYear - 1.0 + (hour - 12.0) / 24.0)
        return 229.18 * (0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma))
    }

    /// 经度校正（分钟）：每偏离标准经线 1° 相差 4 分钟
    static func longitudeCorrectionMinutes(longitude: Double, standardMeridian: Double = 120.0) -> Double {
        (longitude - standardMeridian) * 4.0
    }

    /// 真太阳时相对标准时的总偏移（分钟）
    static func totalOffsetMinutes(longitude: Double,
                                   standardMeridian: Double = 120.0,
                                   julianDay: Double) -> Double {
        longitudeCorrectionMinutes(longitude: longitude, standardMeridian: standardMeridian)
            + equationOfTimeMinutes(julianDay: julianDay)
    }

    /// 儒略日反算公历
    static func civilDate(fromJulianDay jd: Double) -> (year: Int, month: Int, day: Int, hourUT: Double) {
        let z = Int((jd + 0.5).rounded(.down))
        let f = (jd + 0.5) - Double(z)
        var a = z
        if z >= 2299161 {
            let alpha = Int((Double(z) - 1867216.25) / 36524.25)
            a = z + 1 + alpha - alpha / 4
        }
        let b = a + 1524
        let c = Int((Double(b) - 122.1) / 365.25)
        let dd = Int(365.25 * Double(c))
        let e = Int((Double(b) - Double(dd)) / 30.6001)
        let day = b - dd - Int(30.6001 * Double(e))
        let month = e < 14 ? e - 1 : e - 13
        let year = month > 2 ? c - 4716 : c - 4715
        return (year, month, day, f * 24.0)
    }
}
