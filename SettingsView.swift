import SwiftUI
import CoreLocation

struct SettingsView: View {

    @ObservedObject var model: AppModel
    @ObservedObject var compass: CompassService

    var body: some View {
        Form {
            Section {
                Picker("定局法", selection: $model.juMethod) {
                    ForEach(JuMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)

                Text(model.juMethod.detail)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("定局")
            }

            Section {
                Picker("时间取用", selection: $model.timeSource) {
                    ForEach(TimeSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                Text(model.timeSource == .trueSolar
                     ? "按所在地经度与均时差换算真太阳时，时柱以真太阳时为准。古人起局多用此法。"
                     : "直接使用设备所在时区的标准时（北京时间为东八区标准时）。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("时间")
            }

            Section {
                Toggle("罗盘使用真北", isOn: $model.useTrueNorth)

                HStack {
                    Text("磁偏角")
                    Spacer()
                    Text(compass.isAvailable
                         ? String(format: "%+.1f°", compass.declination)
                         : "—")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("航向精度")
                    Spacer()
                    Text(compass.headingAccuracy >= 0
                         ? String(format: "%.0f°", compass.headingAccuracy)
                         : "—")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("罗盘")
            } footer: {
                Text("真北由系统结合磁偏角换算；磁北为磁力计直读值。磁偏角取自设备实时航向数据。")
            }

            Section {
                HStack {
                    Text("定位授权")
                    Spacer()
                    Text(statusText)
                        .foregroundColor(authorized ? Color.green : Color.orange)
                }

                if let lon = compass.longitude {
                    HStack {
                        Text("经度")
                        Spacer()
                        Text(String(format: "%.4f°E", lon))
                            .foregroundColor(.secondary)
                    }
                }

                if let lat = compass.latitude {
                    HStack {
                        Text("纬度")
                        Spacer()
                        Text(String(format: "%.4f°N", lat))
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("备用经度")
                        Spacer()
                        Text(String(format: "%.1f°E", model.manualLongitude))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $model.manualLongitude, in: 70...140, step: 0.5)
                    Text("未取得定位时，真太阳时按此经度计算。默认 120°E 即东八区标准经线。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("定位")
            }

            Section {
                NavigationLink("算法与校验说明") {
                    AlgorithmNoteView()
                }
            } header: {
                Text("关于")
            }

            Section {
                Button("重新起局（当前时刻）") {
                    model.refreshNow()
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var authorized: Bool {
        compass.authorizationStatus == .authorizedWhenInUse
            || compass.authorizationStatus == .authorizedAlways
    }

    private var statusText: String {
        switch compass.authorizationStatus {
        case .notDetermined: return "未请求"
        case .restricted: return "受限"
        case .denied: return "已拒绝"
        case .authorizedWhenInUse: return "使用期间"
        case .authorizedAlways: return "始终"
        @unknown default: return "未知"
        }
    }
}

// MARK: - 算法说明

struct AlgorithmNoteView: View {

    private let sections: [(String, String)] = [
        ("四柱",
         "公历年月日以儒略日数换算日柱；年柱以立春为界，月柱以节令换月并按五虎遁配干，时柱按五鼠遁配干，晚子时（23 时）按次日日干起。"),
        ("节气",
         "以太阳视黄经求解二十四节气交节时刻（Meeus 低精度算法），误差约 0.01°、折合时间约 6 分钟；仅在交节时刻前后数分钟内可能影响取用。"),
        ("定局",
         "拆补法以交节时刻定节气、以日之符头定元（符头地支子午卯酉为上元、寅申巳亥为中元、辰戌丑未为下元），再查节气—局数对照表得局数。"),
        ("地盘",
         "三奇六仪自局数之宫起戊，阳遁顺飞九宫、阴遁逆飞九宫，中五宫之干寄坤二宫。"),
        ("天盘",
         "值符随时干：值符星连同旬首所遁之仪移至时干所在地盘宫，其余八星按蓬、任、冲、辅、英、芮、柱、心顺时针依次排布，整盘随之转动。"),
        ("八门",
         "值使从旬首本宫起，按阳遁顺、阴遁逆沿九宫飞布，步数为时柱在本旬的序号减一；其余七门按休、生、伤、杜、景、死、惊、开顺时针依次排布。"),
        ("八神",
         "值符神随值符星所临之宫，阳遁顺时针、阴遁逆时针依次排布：值符、螣蛇、太阴、六合、白虎、玄武、九地、九天。"),
        ("校验",
         "内核以独立参考实现逐盘比对：2026-11-25 06:39（阴遁八局·小雪中元）与 2025-05-07 09:58（阳遁七局·立夏下元），四柱、局数、旬首、值符值使、九星、八门、八神、天地盘干全部一致。"),
        ("置闰法",
         "按超神接气规则实现：芒种、大雪交节时符头早于节气满十天，则于本节气末重复一轮上中下三元。此派在各家排盘软件间存在细微差异，如需严格对齐请以拆补法结果为准，或与其他专业排盘软件交叉核对。"),
    ]

    var body: some View {
        List {
            ForEach(sections.indices, id: \.self) { index in
                Section {
                    Text(sections[index].1)
                        .font(.footnote)
                } header: {
                    Text(sections[index].0)
                }
            }
        }
        .navigationTitle("算法与校验")
        .navigationBarTitleDisplayMode(.inline)
    }
}
