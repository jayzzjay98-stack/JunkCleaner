# 🤖 AI Prompt: ปรับ JunkCleaner ให้เป็นหน้าเดียว สไตล์เดียวกับ RamCleaner

---

## 🎯 โจทย์

ปรับ `MenuBarView.swift` และ `ScanResultView.swift` ของ JunkCleaner ใหม่ทั้งหมด
ให้เป็น **หน้าเดียว (single scrollable popup)** สไตล์เดียวกับ RamCleaner ทุกประการ
**ไม่ต้องมี Tab bar, ไม่มี Settings, ไม่มี App Uninstaller**
มีแค่ฟังก์ชัน **สแกนไฟล์ขยะ + ลบไฟล์ขยะ** เท่านั้น

---

## 🎨 ดู RamCleaner เป็น Reference

โค้ด `MenuBarView.swift` ของ RamCleaner มีโครงสร้างดังนี้ (ให้ทำตามแบบนี้):

```
VStack(spacing: 0) {
    headerSection          ← ชื่อแอป + ไอคอน (แนวนอน, centered)
    mainDisplay            ← ตัวเลขใหญ่ + วงแหวน (main stat)
    statsGrid              ← 3 กล่องสถิติย่อย
    dividerLine("JUNK")    ← เส้นคั่น + label
    junkListSection        ← รายการขยะที่เจอ (compact rows)
    actionButtons          ← ปุ่ม Scan + Clean
    themeSection           ← scroll แนวนอนเลือก theme
    footerSection          ← Quit + version
}
.frame(width: 280)
.background(theme.bgColor)
```

---

## 📐 รายละเอียดแต่ละ section

### 1. `headerSection`
```swift
// ← เหมือน RamCleaner ทุกอย่าง เปลี่ยนแค่ข้อความ
HStack {
    Spacer()
    Image(systemName: "trash")
        .font(.system(size: 17))
        .foregroundStyle(theme.accent)
    Text("JunkCleaner · M4")   // หรือดึงชื่อ chip จาก sysctl เหมือน RamCleaner
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(.white.opacity(0.9))
    Spacer()
}
.padding(.vertical, 12)
// เส้นคั่นล่าง 0.5px
```

---

### 2. `mainDisplay` ← ส่วนสำคัญที่สุด
```
HStack(alignment: .top) {
    LEFT SIDE:
    - Label "JUNK FILES"  (monospaced, uppercase, white 50%)
    - ตัวเลข GB ใหญ่ (42pt bold) สี theme.accent  ← แสดง totalJunkGB
    - subtext "X items found" หรือ "Ready to scan" (12pt monospaced)
    - Segment bar  ← แสดง % ของ junk เทียบกับ disk ที่ใช้อยู่
      (ใช้ diskUsedPercent แทน usagePercent ของ RAM)

    RIGHT SIDE:
    - miniRing  ← วงแหวนเดียวกันกับ RamCleaner แต่แสดง free disk space
      ตรงกลางวงแหวน: แสดง free GB ของ disk
      label: "FREE"
}
```

**วิธีดึงข้อมูล disk:**
```swift
// เพิ่มใน JunkScanner หรือสร้าง helper
func getDiskInfo() -> (totalGB: Double, freeGB: Double) {
    let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
    let total = attrs?[.systemSize] as? Int64 ?? 0
    let free = attrs?[.systemFreeSize] as? Int64 ?? 0
    return (Double(total) / 1_073_741_824.0, Double(free) / 1_073_741_824.0)
}
```

---

### 3. `statsGrid` — 3 กล่องสถิติย่อย
```swift
// เหมือน RamCleaner ทุกอย่าง
HStack(spacing: 4) {
    statBox(label: "STATUS",   value: scanner.isScanning ? "Scanning" : scanResult != nil ? "Done" : "Ready",   isOk: !scanner.isScanning)
    statBox(label: "ITEMS",    value: "\(scanResult?.items.count ?? 0)",  isOk: false)
    statBox(label: "LAST SCAN",value: lastScanTimeAgo,   isOk: false)
    // lastScanTimeAgo: "2m ago", "Just now", "Never"
}
```

---

### 4. `junkListSection` — รายการขยะ (หลัง scan)

**ก่อนสแกน:** ไม่แสดงอะไร หรือแสดง placeholder text จาง ๆ
```
Text("Press Scan to find junk files")
    .font(.system(size: 12, design: .monospaced))
    .foregroundStyle(.white.opacity(0.2))
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
```

**ระหว่างสแกน:** progress + task name
```swift
VStack(spacing: 6) {
    ProgressView(value: scanner.scanProgress)
        .progressViewStyle(.linear)
        .tint(theme.accent)
    Text(scanner.currentScanTask)
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.white.opacity(0.5))
}
.padding(.horizontal, 4)
.padding(.vertical, 4)
```

**หลังสแกน:** แสดง grouped rows แบบ compact เหมือน process rows ใน RamCleaner
```swift
// แสดง top categories ที่มีขนาดใหญ่สุด 7 อันดับ
// format เหมือน processRow ใน RamCleaner:
HStack(spacing: 6) {
    Text(String(format: "%02d", rank))       // "01", "02", ...
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(theme.accent.opacity(0.5))
        .frame(width: 14)

    Text(category.name)                      // "Xcode DerivedData"
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .lineLimit(1).truncationMode(.tail)
        .frame(maxWidth: .infinity, alignment: .leading)

    // mini bar (40px wide) เหมือน RamCleaner
    ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 1.5).fill(Color.white.opacity(0.06)).frame(width: 40, height: 2.5)
        RoundedRectangle(cornerRadius: 1.5).fill(theme.accent.opacity(0.7))
            .frame(width: max(2, 40 * item.sizeBytes / maxSize), height: 2.5)
    }

    Text(item.formattedSize)                 // "3.2 GB", "450 MB"
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(.white.opacity(0.8))
        .frame(width: 56, alignment: .trailing)
}
.padding(.vertical, 3)
.padding(.horizontal, 6)
```

**ข้อมูลที่แสดงใน list:** รวม items ที่มีขนาดใหญ่สุดก่อน เรียงจากมากไปน้อย
```swift
let topItems = (scanResult?.items ?? [])
    .sorted { $0.sizeBytes > $1.sizeBytes }
    .prefix(7)  // แสดงแค่ 7 รายการใหญ่สุด
```

---

### 5. `actionButtons` — ปุ่ม Scan + Clean

```swift
// เหมือน RamCleaner actionButtons ทุกอย่าง
HStack(spacing: 6) {
    if isCleaningInProgress {
        // loading state เหมือน RamCleaner
        HStack(spacing: 6) {
            ProgressView().controlSize(.small).tint(theme.accent)
            Text("Cleaning...")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.accent)
        }
        .frame(maxWidth: .infinity).frame(height: 42)
        .background(...)
    } else {
        // ปุ่ม Scan
        cleanButton(icon: "◎", label: "Scan") {
            Task { await scanner.startScan() }
        }
        .keyboardShortcut("s", modifiers: [.command])

        // ปุ่ม Clean — disabled ถ้ายังไม่ได้สแกน หรือ items = 0
        cleanButton(icon: "🗑", label: "Clean All") {
            guard let result = scanner.scanResult else { return }
            Task { await cleaner.clean(items: result.items.filter { $0.isSelected }) }
        }
        .disabled(scanner.scanResult == nil || scanner.scanResult!.items.isEmpty)
        .keyboardShortcut("c", modifiers: [.command])
    }
}
```

**หลัง clean เสร็จ:** แสดง status message เหมือน RamCleaner
```swift
// แสดงบน actionButtons
if let result = cleaner.lastResult {
    Text("✅ Freed \(result.formattedFreed) · \(result.deletedCount) items deleted")
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(Color(red: 0.29, green: 0.87, blue: 0.5))
        .lineLimit(1)
}
// ซ่อนหลังจาก 6 วินาที (ใช้ DispatchQueue.main.asyncAfter เหมือน RamCleaner)
```

---

### 6. `themeSection`
```swift
// Copy มาจาก RamCleaner ทั้งก้อน — ไม่ต้องเปลี่ยนอะไร
// ใช้ @AppStorage("selectedTheme") key เดียวกัน
// ดังนั้น theme จะ sync กับ RamCleaner อัตโนมัติ
```

---

### 7. `footerSection`
```swift
// เหมือน RamCleaner ทุกอย่าง เปลี่ยนแค่ข้อความ
HStack {
    Button("⏻ Quit") { NSApplication.shared.terminate(nil) }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.6))
        .keyboardShortcut("q", modifiers: [.command])
    Spacer()
    Text("AUTO SCAN OFF · v1.0")
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.white.opacity(0.5))
}
```

---

## 📏 ขนาด Popup

```swift
.frame(width: 280)   // ← เท่ากับ RamCleaner พอดี
// height: ไม่กำหนด ให้ VStack ยืดตามเนื้อหา
.background(theme.bgColor)
```

---

## 🗑️ ไฟล์ที่ต้องลบทิ้ง / ไม่ต้องใช้แล้ว

- `ScanResultView.swift` → ลบทิ้ง ไม่ต้องใช้แล้ว (รวมเข้า MenuBarView)
- AppUninstaller tab → ลบออก
- Settings tab → ลบออก
- `Picker` tab bar → ลบออก
- `@State private var selectedTab` → ลบออก

---

## ✅ สรุปสิ่งที่ต้องทำ

1. **แก้ `MenuBarView.swift` ใหม่ทั้งหมด** ตามโครงสร้างข้างบน width: 280 หน้าเดียว
2. **ลบ `ScanResultView.swift`** ออก (ไม่ต้องใช้)
3. **ไม่ต้องแก้ไฟล์อื่น** — JunkScanner, JunkCleaner, AppUninstaller, Theme, JunkCategory ใช้เหมือนเดิมทั้งหมด
4. **เพิ่ม `getDiskInfo()`** ใน JunkScanner สำหรับ mainDisplay

---

## 🔑 Key Principles (สำคัญมาก)

- `width: 280` — เท่ากับ RamCleaner พอดี ห้ามใช้ 400
- ห้ามมี Picker / Tab bar
- ห้ามมี ScrollView ครอบทั้งหน้า — ใช้ ScrollView เฉพาะใน themeSection เหมือน RamCleaner
- ใช้ `theme.accent`, `theme.bgColor`, `theme.accentDim`, `theme.borderColor` ทุก UI element
- font: `.monospaced` สำหรับตัวเลขและ labels ทุกตัว
- สีพื้นหลัง: `Color.white.opacity(0.03~0.06)` สำหรับกล่อง
- เส้นคั่น: `Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)`
- ทุกอย่างต้อง **dark theme** — ไม่มีสีขาวสว่าง

---

*prompt นี้สำหรับ AI เขียนโค้ด Swift/SwiftUI ปรับ JunkCleaner ให้เป็น single-page menu bar app สไตล์ RamCleaner*
