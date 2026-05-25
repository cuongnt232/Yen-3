import Foundation

struct CellProbeBridge {
    static func fetchSnapshot() -> CellSnapshot {
        let probe = CellProbeService.shared().fetchServingCellInfo()

        var snapshot = CellSnapshot()
        snapshot.carrier = CellSnapshotFormatter.display(probe.carrier)
        snapshot.band = CellSnapshotFormatter.display(probe.band)
        snapshot.cid = CellSnapshotFormatter.display(probe.cid)
        snapshot.enbId = CellSnapshotFormatter.display(probe.enbid)
        snapshot.eci = CellSnapshotFormatter.display(probe.eci)
        snapshot.pci = CellSnapshotFormatter.display(probe.pci)
        snapshot.radioTechnology = CellSnapshotFormatter.display(probe.radioAccessTechnology)
        snapshot.statusMessage = probe.statusMessage
        snapshot.rawCellInfo = probe.rawCellInfo
        snapshot.updatedAt = Date()
        return snapshot
    }
}
