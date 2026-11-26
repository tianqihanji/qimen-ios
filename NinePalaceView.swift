import SwiftUI

/// 九宫盘面页：完整展示地、天、人、神四层
struct NinePalaceView: View {

    let chart: QimenChart

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                infoCard
                gridCard
                footNote
            }
            .padding(14)
        }
        .background(Palette.ink.ignoresSafeArea())
        .navigationTitle("奇门盘面")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 基本信息

    private var infoCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text(chart.fourPillars)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Palette.gold)
                Spacer()
                Text(chart.juLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Palette.cinnabar)
            }

            Divider().overlay(Palette.goldDim.opacity(0.4))

            row("节气", "\(chart.term.name) · \(chart.yuan)")
            row("定局法", chart.method.rawValue)
            row("旬首", "\(chart.xunHead)（遁\(chart.xunYi)）")
            row("值符", "\(chart.zhiFuStar) 临 \(QimenConstants.palaceName[chart.zhiFuPalace] ?? "")")
            row("值使", "\(chart.zhiShiDoor) 临 \(QimenConstants.palaceName[chart.zhiShiPalace] ?? "")")
            row("旬空", chart.kongWang)
            row("驿马", "\(chart.maXing)（\(QimenConstants.palaceShort[chart.maXingPalace] ?? "")宫）")
            row("起局时刻", "\(chart.timeLabel)\(chart.usedTrueSolar ? "（真太阳时）" : "（标准时）")")
        }
        .padding(14)
        .background(Palette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Palette.goldDim)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.88))
            Spacer(minLength: 0)
        }
    }

    // MARK: 九宫

    private var gridCard: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            GridRow {
                cell(4); cell(9); cell(2)
            }
            GridRow {
                cell(3); cell(5); cell(7)
            }
            GridRow {
                cell(8); cell(1); cell(6)
            }
        }
        .background(Palette.goldDim.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Palette.goldDim.opacity(0.8), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func cell(_ palaceID: Int) -> some View {
        if let palace = chart.palace(palaceID) {
            PalaceCellView(palace: palace,
                           isZhiFu: palaceID == chart.zhiFuPalace,
                           isZhiShi: palaceID == chart.zhiShiPalace,
                           isHorse: palaceID == chart.maXingPalace)
                .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        } else {
            Color.clear.frame(minHeight: 108)
        }
    }

    private var footNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("盘面说明")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Palette.goldDim)
            Text("每宫自上而下依次为：八神、九星、八门、天盘干 / 地盘干。中五宫无门无神，其地盘干寄坤二宫，并随坤二宫一同转动。")
                .font(.system(size: 11))
                .foregroundColor(Palette.goldDim.opacity(0.85))
            Text("红色「符」标记值符所临之宫，绿色「使」标记值使所临之宫，「马」为时支驿马所在。")
                .font(.system(size: 11))
                .foregroundColor(Palette.goldDim.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Palette.panel.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// 单宫格
struct PalaceCellView: View {

    let palace: QimenPalace
    let isZhiFu: Bool
    let isZhiShi: Bool
    let isHorse: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(QimenConstants.palaceShort[palace.id] ?? "")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Palette.goldDim)
                Spacer(minLength: 0)
                if isZhiFu { badge("符", Palette.cinnabar) }
                if isZhiShi { badge("使", Palette.jade) }
                if isHorse { badge("马", Palette.gold) }
            }

            Text(palace.god.isEmpty ? "　" : palace.god)
                .font(.system(size: 11))
                .foregroundColor(Palette.goldDim)

            Text(palace.star.isEmpty ? "　" : palace.star)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.92))

            Text(palace.door.isEmpty ? "　" : palace.door)
                .font(.system(size: 12))
                .foregroundColor(Palette.jade)

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Text(palace.heavenGan.joined())
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.cinnabar)
                Text(palace.earthGan)
                    .font(.system(size: 11))
                    .foregroundColor(Palette.goldDim)
            }
        }
        .padding(7)
        .background(Palette.panel)
    }

    private func badge(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.opacity(0.7), lineWidth: 0.6)
            )
    }
}
