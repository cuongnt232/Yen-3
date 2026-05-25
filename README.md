# CellNet Monitor (iOS)

App iOS doc thong tin cell co ban cho ky su vien thong.

## Quan trong

Apple khong cung cap API cong khai cho CID/PCI/band tren App Store app thong thuong.

Project nay dung CoreTelephony private API nen:
- Khong phu hop submit App Store thong thuong
- Can cai len iPhone that bang Xcode developer certificate hoac sideload
- Simulator khong co du lieu cell

## Cach build

1. Mo CellNetMonitor.xcodeproj tren Mac
2. Chon Team trong Signing and Capabilities
3. Bridging Header = CellNetMonitor/CellNetMonitor-Bridging-Header.h
4. Chon iPhone that, Run
5. Tat Wi-Fi, bat Cellular Data khi test
