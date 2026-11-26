import Foundation
import Combine

final class AppModel: ObservableObject {

    @Published var juMethod: JuMethod = .chaibu
    @Published var timeSource: TimeSource = .standard
    @Published var useTrueNorth: Bool = true
    @Published var manualLongitude: Double = 120.0
    @Published var locationLongitude: Double?

    @Published private(set) var chart: QimenChart
    @Published var now: Date = Date()

    private var cancellables = Set<AnyCancellable>()

    init() {
        chart = QimenEngine.makeChart(date: Date(),
                                      timeZone: TimeZone.current,
                                      method: .chaibu,
                                      useTrueSolar: false,
                                      longitude: nil)

        // 任一影响排盘的参数变化即重排（用 Combine 订阅，避免属性包装器上挂 didSet）
        $juMethod
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.rebuild()
            }
            .store(in: &cancellables)

        $timeSource
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.rebuild()
            }
            .store(in: &cancellables)

        $manualLongitude
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.rebuild()
            }
            .store(in: &cancellables)

        $locationLongitude
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.rebuild()
            }
            .store(in: &cancellables)

        // 每分钟跟随当前时刻重排
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] value in
                guard let self else { return }
                self.now = value
                self.rebuild()
            }
            .store(in: &cancellables)
    }

    /// 真太阳时必须拿到经度；未定位时退回手动经度
    var effectiveLongitude: Double? {
        guard timeSource == .trueSolar else { return nil }
        return locationLongitude ?? manualLongitude
    }

    func rebuild() {
        chart = QimenEngine.makeChart(date: now,
                                      timeZone: TimeZone.current,
                                      method: juMethod,
                                      useTrueSolar: timeSource == .trueSolar,
                                      longitude: effectiveLongitude)
    }

    func refreshNow() {
        now = Date()
        rebuild()
    }
}
