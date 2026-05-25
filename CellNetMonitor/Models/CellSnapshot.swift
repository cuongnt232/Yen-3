import Foundation

struct CellSnapshot: Equatable {
    var carrier: String = "-"
    var band: String = "-"
    var latitude: String = "-"
    var longitude: String = "-"
    var cid: String = "-"
    var enbId: String = "-"
    var eci: String = "-"
    var pci: String = "-"
    var radioTechnology: String = "-"
    var updatedAt: Date = .distantPast
    var statusMessage: String?
    var rawCellInfo: String?

    static let empty = CellSnapshot()
}

enum CellSnapshotFormatter {
    static func display(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        return value
    }

    static func display(_ number: NSNumber?) -> String {
        guard let number else { return "-" }
        return number.stringValue
    }
}