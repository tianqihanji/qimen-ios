import Foundation
import Combine
import CoreLocation

/// 磁力计航向 + 定位（真北 / 磁北 / 磁偏角 / 经度）
final class CompassService: NSObject, ObservableObject {

    private let manager = CLLocationManager()

    @Published var magneticHeading: Double = 0
    @Published var trueHeading: Double = 0
    @Published var trueHeadingIsValid: Bool = false
    @Published var headingAccuracy: Double = -1
    @Published var longitude: Double?
    @Published var latitude: Double?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 0.5
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var declination: Double {
        trueHeadingIsValid ? trueHeading - magneticHeading : 0
    }

    var isAvailable: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingHeading()
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    /// 将连续旋转角度规整到 0..<360
    static func normalized(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }

    /// 由方位角换算二十四山
    static func mountain(for bearing: Double) -> String {
        let index = Int((normalized(bearing) + 7.5) / 15) % 24
        return QimenConstants.mountains[index]
    }
}

extension CompassService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magnetic = newHeading.magneticHeading
        let trueValue = newHeading.trueHeading
        let valid = trueValue >= 0
        let accuracy = newHeading.headingAccuracy
        DispatchQueue.main.async {
            self.magneticHeading = magnetic
            self.trueHeading = valid ? trueValue : magnetic
            self.trueHeadingIsValid = valid
            self.headingAccuracy = accuracy
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let lon = location.coordinate.longitude
        let lat = location.coordinate.latitude
        DispatchQueue.main.async {
            self.longitude = lon
            self.latitude = lat
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingHeading()
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 定位失败时静默处理，界面会给出提示
    }
}
