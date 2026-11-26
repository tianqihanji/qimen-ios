import SwiftUI

// MARK: - 配色

enum Palette {
    static let gold = Color(red: 0.86, green: 0.74, blue: 0.46)
    static let goldDim = Color(red: 0.62, green: 0.53, blue: 0.34)
    static let ink = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let panel = Color(red: 0.11, green: 0.12, blue: 0.16)
    static let cinnabar = Color(red: 0.80, green: 0.24, blue: 0.20)
    static let jade = Color(red: 0.38, green: 0.68, blue: 0.60)
}

// MARK: - 几何

enum Geo {
    /// 以正上方为 0°、顺时针角度的圆周取点
    static func point(center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let rad = degrees * .pi / 180
        return CGPoint(x: center.x + radius * CGFloat(sin(rad)),
                       y: center.y - radius * CGFloat(cos(rad)))
    }

    static func swiftUIAngle(fromTop degrees: Double) -> Double { degrees - 90 }

    /// 自正上方角度为中心、左右各 22.5° 的圆弧
    static func arc(center: CGPoint, radius: CGFloat, fromTop degrees: Double) -> Path {
        var path = Path()
        path.addArc(center: center,
                    radius: radius,
                    startAngle: .degrees(swiftUIAngle(fromTop: degrees - 22.5)),
                    endAngle: .degrees(swiftUIAngle(fromTop: degrees + 22.5)),
                    clockwise: false)
        return path
    }
}

// MARK: - 罗盘页

struct LuopanView: View {

    @ObservedObject var model: AppModel
    @ObservedObject var compass: CompassService

    private var heading: Double {
        model.useTrueNorth ? compass.trueHeading : compass.magneticHeading
    }

    var body: some View {
        VStack(spacing: 12) {
            headingBar
            dialArea
            summaryBar
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.ink.ignoresSafeArea())
        .navigationTitle("奇门罗盘")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.refreshNow()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .tint(Palette.gold)
            }
        }
    }

    // 当前朝向
    private var headingBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("当前朝向")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.goldDim)
                HStack(spacing: 6) {
                    Text(CompassService.mountain(for: heading))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Palette.gold)
                    Text(String(format: "%.1f°", CompassService.normalized(heading)))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Palette.goldDim)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(model.useTrueNorth ? "真北" : "磁北")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.goldDim)
                Text(compass.isAvailable
                     ? String(format: "磁偏角 %+.1f°", compass.declination)
                     : "未授权定位")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(compass.isAvailable ? Palette.jade : Palette.cinnabar)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Palette.panel.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var dialArea: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                LuopanDial(chart: model.chart)
                    .frame(width: side, height: side)
                    .rotationEffect(.degrees(-heading))

                // 固定读数游标
                VStack(spacing: 0) {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.cinnabar)
                    Spacer()
                }
                .frame(height: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var summaryBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text(model.chart.fourPillars)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Palette.gold)
                Spacer()
                Text(model.chart.juLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.cinnabar)
            }
            HStack(spacing: 12) {
                label("值符", "\(model.chart.zhiFuStar)·\(QimenConstants.palaceShort[model.chart.zhiFuPalace] ?? "")")
                label("值使", "\(model.chart.zhiShiDoor)·\(QimenConstants.palaceShort[model.chart.zhiShiPalace] ?? "")")
                label("空亡", model.chart.kongWang)
                Spacer()
                label("马", model.chart.maXing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Palette.panel.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func label(_ title: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(Palette.goldDim)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

// MARK: - 盘面绘制

struct LuopanDial: View {

    let chart: QimenChart

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 2

            // 底盘
            let disc = Path(ellipseIn: CGRect(x: center.x - radius,
                                              y: center.y - radius,
                                              width: radius * 2,
                                              height: radius * 2))
            context.fill(disc, with: .color(Color(red: 0.09, green: 0.10, blue: 0.14)))
            context.stroke(disc, with: .color(Palette.gold.opacity(0.85)), lineWidth: 1.4)

            // 同心圆
            for ratio in [0.98, 0.86, 0.74, 0.60, 0.46] {
                let r = radius * CGFloat(ratio)
                let ring = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                  width: r * 2, height: r * 2))
                context.stroke(ring, with: .color(Palette.gold.opacity(0.45)), lineWidth: 0.7)
            }

            // 二十四山分隔线
            for i in 0..<24 {
                let a = Double(i) * 15.0
                let inner = Geo.point(center: center, radius: radius * 0.86, degrees: a)
                let outer = Geo.point(center: center, radius: radius * 0.98, degrees: a)
                var line = Path()
                line.move(to: inner)
                line.addLine(to: outer)
                context.stroke(line, with: .color(Palette.gold.opacity(0.28)), lineWidth: 0.6)
            }

            // 八宫分隔线
            for i in 0..<8 {
                let a = Double(i) * 45.0 + 22.5
                let inner = Geo.point(center: center, radius: radius * 0.46, degrees: a)
                let outer = Geo.point(center: center, radius: radius * 0.86, degrees: a)
                var line = Path()
                line.move(to: inner)
                line.addLine(to: outer)
                context.stroke(line, with: .color(Palette.gold.opacity(0.30)), lineWidth: 0.7)
            }

            let mountainFont = radius * 0.050

            // 二十四山
            for (index, name) in QimenConstants.mountains.enumerated() {
                let position = Geo.point(center: center, radius: radius * 0.92,
                                         degrees: Double(index) * 15.0)
                let isFour = [0, 6, 12, 18].contains(index)   // 子午卯酉
                context.draw(
                    Text(name)
                        .font(.system(size: mountainFont, weight: isFour ? .bold : .regular))
                        .foregroundColor(isFour ? Palette.gold : Palette.goldDim),
                    at: position,
                    anchor: .center
                )
            }

            // 八神 / 九星 / 八门 / 天盘干
            for palaceID in QimenConstants.ring {
                guard let palace = chart.palace(palaceID) else { continue }
                let angle = QimenConstants.palaceAngle[palaceID] ?? 0

                let godPoint = Geo.point(center: center, radius: radius * 0.80, degrees: angle)
                context.draw(
                    Text(palace.god)
                        .font(.system(size: radius * 0.040, weight: .regular))
                        .foregroundColor(Palette.goldDim),
                    at: godPoint, anchor: .center
                )

                let starPoint = Geo.point(center: center, radius: radius * 0.665, degrees: angle)
                context.draw(
                    Text(palace.star)
                        .font(.system(size: radius * 0.038, weight: .medium))
                        .foregroundColor(.white.opacity(0.90)),
                    at: starPoint, anchor: .center
                )

                let doorPoint = Geo.point(center: center, radius: radius * 0.555, degrees: angle)
                context.draw(
                    Text(palace.door)
                        .font(.system(size: radius * 0.040, weight: .medium))
                        .foregroundColor(Palette.jade),
                    at: doorPoint, anchor: .center
                )

                let ganPoint = Geo.point(center: center, radius: radius * 0.485, degrees: angle)
                context.draw(
                    Text(palace.heavenGan.joined())
                        .font(.system(size: radius * 0.042, weight: .semibold))
                        .foregroundColor(Palette.cinnabar),
                    at: ganPoint, anchor: .center
                )
            }

            // 值符 / 值使 高亮弧
            if let zhiFuAngle = QimenConstants.palaceAngle[chart.zhiFuPalace] {
                context.stroke(Geo.arc(center: center, radius: radius * 0.86, fromTop: zhiFuAngle),
                               with: .color(Palette.cinnabar), lineWidth: 2.2)
            }
            if let zhiShiAngle = QimenConstants.palaceAngle[chart.zhiShiPalace] {
                context.stroke(Geo.arc(center: center, radius: radius * 0.60, fromTop: zhiShiAngle),
                               with: .color(Palette.jade), lineWidth: 2.2)
            }

            // 天池指针
            let needleLength = radius * 0.30
            var northHalf = Path()
            northHalf.move(to: CGPoint(x: center.x, y: center.y - needleLength))
            northHalf.addLine(to: CGPoint(x: center.x - radius * 0.045, y: center.y))
            northHalf.addLine(to: CGPoint(x: center.x + radius * 0.045, y: center.y))
            northHalf.closeSubpath()
            context.fill(northHalf, with: .color(Palette.cinnabar))

            var southHalf = Path()
            southHalf.move(to: CGPoint(x: center.x, y: center.y + needleLength * 0.75))
            southHalf.addLine(to: CGPoint(x: center.x - radius * 0.045, y: center.y))
            southHalf.addLine(to: CGPoint(x: center.x + radius * 0.045, y: center.y))
            southHalf.closeSubpath()
            context.fill(southHalf, with: .color(.white.opacity(0.35)))

            let hubRadius = radius * 0.035
            let hub = Path(ellipseIn: CGRect(x: center.x - hubRadius,
                                             y: center.y - hubRadius,
                                             width: hubRadius * 2,
                                             height: hubRadius * 2))
            context.fill(hub, with: .color(Palette.gold))
        }
    }
}
