import CoreLocation
import Foundation

@MainActor
final class LocationTracker: NSObject, ObservableObject {
    @Published private(set) var latitude: String = "-"
    @Published private(set) var longitude: String = "-"
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var locationError: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissionIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            locationError = "Can quyen vi tri de lay lat/long."
        @unknown default:
            locationError = "Trang thai quyen vi tri khong xac dinh."
        }
    }

    func refresh() {
        requestPermissionIfNeeded()
        manager.requestLocation()
    }
}

extension LocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                locationError = nil
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            latitude = String(format: "%.6f", location.coordinate.latitude)
            longitude = String(format: "%.6f", location.coordinate.longitude)
            locationError = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error.localizedDescription
        }
    }
}