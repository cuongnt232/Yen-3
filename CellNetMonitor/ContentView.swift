import SwiftUI
import UIKit

struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .font(.body)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CellMonitorViewModel()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Thông tin cell")) {
                    MetricRow(title: "Nhà mạng", value: viewModel.snapshot.carrier)
                    MetricRow(title: "Băng tần", value: viewModel.snapshot.band)
                    MetricRow(title: "Latitude", value: viewModel.snapshot.latitude)
                    MetricRow(title: "Longitude", value: viewModel.snapshot.longitude)
                    MetricRow(title: "CID", value: viewModel.snapshot.cid)
                    MetricRow(title: "eNB ID", value: viewModel.snapshot.enbId)
                    MetricRow(title: "ECI", value: viewModel.snapshot.eci)
                    MetricRow(title: "PCI", value: viewModel.snapshot.pci)
                    MetricRow(title: "RAT", value: viewModel.snapshot.radioTechnology)
                }

                if let status = viewModel.snapshot.statusMessage, !status.isEmpty {
                    Section(header: Text("Trạng thái")) {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                if let raw = viewModel.snapshot.rawCellInfo, !raw.isEmpty {
                    Section(header: Text("Raw cell info")) {
                        Text(raw)
                            .font(.caption2)
                            .textSelection(.enabled)
                    }
                }

                Section {
                    Toggle("Tự làm mới (3 giây)", isOn: Binding(
                        get: { viewModel.autoRefresh },
                        set: { viewModel.setAutoRefresh($0) }
                    ))

                    Button {
                        UIPasteboard.general.string = viewModel.copyText()
                    } label: {
                        Label("Sao chép tất cả", systemImage: "doc.on.doc")
                    }
                } footer: {
                    Text("Cập nhật lần cuối: \(viewModel.snapshot.updatedAt.formatted(date: .omitted, time: .standard))")
                }
            }
            .navigationTitle("CellNet Monitor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
            .onAppear {
                viewModel.start()
            }
            .onDisappear {
                viewModel.stop()
            }
        }
        .navigationViewStyle(.stack)
    }
}
