import Foundation

@MainActor
final class CellMonitorViewModel: ObservableObject {
    @Published private(set) var snapshot = CellSnapshot.empty
    @Published private(set) var isRefreshing = false
    @Published var autoRefresh = false

    let locationTracker = LocationTracker()

    private var refreshTask: Task<Void, Never>?
    private var loopTask: Task<Void, Never>?

    func start() {
        locationTracker.requestPermissionIfNeeded()
        refresh()
    }

    func stop() {
        refreshTask?.cancel()
        loopTask?.cancel()
        autoRefresh = false
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await performRefresh()
        }
    }

    func toggleAutoRefresh() {
        setAutoRefresh(!autoRefresh)
    }

    func setAutoRefresh(_ enabled: Bool) {
        autoRefresh = enabled
        loopTask?.cancel()

        guard enabled else { return }

        loopTask = Task {
            while !Task.isCancelled && autoRefresh {
                await performRefresh()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func copyText() -> String {
        """
        Nhà mạng: \(snapshot.carrier)
        Băng tần: \(snapshot.band)
        Lat: \(snapshot.latitude)
        Long: \(snapshot.longitude)
        CID: \(snapshot.cid)
        eNB ID: \(snapshot.enbId)
        ECI: \(snapshot.eci)
        PCI: \(snapshot.pci)
        RAT: \(snapshot.radioTechnology)
        """
    }

    private func performRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        locationTracker.refresh()

        let cellSnapshot = await Task.detached(priority: .userInitiated) {
            CellProbeBridge.fetchSnapshot()
        }.value

        snapshot.carrier = cellSnapshot.carrier
        snapshot.band = cellSnapshot.band
        snapshot.cid = cellSnapshot.cid
        snapshot.enbId = cellSnapshot.enbId
        snapshot.eci = cellSnapshot.eci
        snapshot.pci = cellSnapshot.pci
        snapshot.radioTechnology = cellSnapshot.radioTechnology
        snapshot.statusMessage = cellSnapshot.statusMessage
        snapshot.rawCellInfo = cellSnapshot.rawCellInfo
        snapshot.updatedAt = cellSnapshot.updatedAt
        snapshot.latitude = locationTracker.latitude
        snapshot.longitude = locationTracker.longitude
    }
}
