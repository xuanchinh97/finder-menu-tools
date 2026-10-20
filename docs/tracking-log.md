# Nhật ký Triển khai (Tracking Log)

Tài liệu này theo dõi toàn bộ quá trình thiết lập môi trường, thiết kế kiến trúc, triển khai code và kiểm thử cho dự án `FinderMenuTools`.

---

## [2026-10-20] Giai đoạn 1: Khởi tạo dự án & Thiết lập môi trường AI Agent

### Mục tiêu
- Khởi tạo dự án tại `/Users/trinhxuanchinh/Workspace/tools/finder-menu-tools`.
- Thiết lập Git quản lý phiên bản (`main` branch).
- Thiết lập môi trường tối ưu cho AI Agent thực thi (Project Rules `AGENTS.md` + Specialized Skill `macos-finder-sync`).
- Xây dựng bộ khung tài liệu `docs/`.

### Các hạng mục đã hoàn thành
- [x] Khởi tạo Git repository và cấu hình `.gitignore` cho Xcode/Swift.
- [x] Tạo `AGENTS.md` định nghĩa rõ stack Swift 6 + AppKit + FinderSync (ghi đè giả định mặc định về Frontend Web trong Global Rule) và quy chuẩn cập nhật tài liệu/Git.
- [x] Tạo Workspace Skill `.agents/skills/macos-finder-sync/SKILL.md` kèm công cụ chẩn đoán `scripts/diagnose.sh` để tự động kiểm tra chữ ký số, `pluginkit`, và trạng thái cài đặt.
- [x] Tạo tài liệu `docs/architecture.md`, `docs/usage-and-setup.md`, và `docs/tracking-log.md`.

### Bước tiếp theo (Giai đoạn 2)
- Triển khai mã nguồn `FinderMenuTools` (Host App) và `FinderSyncExt` (Finder Sync Extension).
- Tạo cấu hình Xcode project và script `scripts/install.sh`.
- Build, cài đặt vào `/Applications` và kiểm thử thực tế.

---

## [2026-10-20] Giai đoạn 2: Xây dựng mã nguồn, Build, Cài đặt & Kích hoạt Finder Sync Extension

### Mục tiêu
- Viết mã nguồn Host App (`FinderMenuTools`) và Extension (`FinderSyncExt`).
- Cấu hình Xcode Project (`FinderMenuTools.xcodeproj`) và script cài đặt tự động `scripts/install.sh`.
- Biên dịch bản Release, cài đặt vào `/Applications/FinderMenuTools.app` và kích hoạt trên Finder.

### Phát hiện kỹ thuật & Giải pháp (Root Cause & Fix)
- **Vấn đề**: Khi đặt `com.apple.security.app-sandbox = false` cho `FinderSyncExt.appex` (hoặc dùng `codesign --deep` trên Host App làm ghi đè entitlements của Extension), daemon `pkd` (`pluginkit`) của macOS từ chối đăng ký extension (trả về `(no matches)`).
- **Giải pháp**:
  1. Bật `com.apple.security.app-sandbox = true` kèm `com.apple.security.temporary-exception.files.all.read-write = true` trong `FinderSyncExt/FinderSyncExt.entitlements`.
  2. Trong `scripts/install.sh`, ký riêng `FinderSyncExt.appex` trước, sau đó ký `FinderMenuTools.app` không dùng `--deep`.
- **Kết quả xác minh (`diagnose.sh` & `pluginkit`)**:
  - `xcodebuild` biên dịch thành công (`Universal binary: x86_64 + arm64`).
  - `pluginkit -m -v -i com.chinh.FinderMenuTools.FinderSyncExt` trả về trạng thái `+` (Active):
    `+ com.chinh.FinderMenuTools.FinderSyncExt(1.0.0) /Applications/FinderMenuTools.app/Contents/PlugIns/FinderSyncExt.appex`
  - Tiến trình `FinderSyncExt` đã được Finder khởi chạy thành công.

---

## [2026-10-20] Giai đoạn 3: Khắc phục lỗi Sandbox Permission & Bổ sung "Open in Terminal"

### Mục tiêu
- Sửa lỗi popup thông báo: *"The application 'FinderMenuTools Extension' does not have permission to open..."* khi click chuột phải chọn **Open in iTerm2**.
- Bổ sung tuỳ chọn **Open in Terminal** trực tiếp trên menu chuột phải.
- Kiểm thử kỹ lưỡng toàn bộ luồng hoạt động.

### Nguyên nhân gốc rễ (Root Cause Analysis)
- Extension (`FinderSyncExt.appex`) bắt buộc phải bật Sandbox (`com.apple.security.app-sandbox = true`) để `pluginkit` chấp nhận nạp vào Finder.
- Khi Extension trong Sandbox gọi `NSWorkspace.shared.open([folderURL], withApplicationAt: itermURL)`, tiến trình LaunchServices (`CoreServicesUIAgent`) kiểm tra token bảo mật và phát hiện tiến trình gọi không có quyền truy cập trực tiếp vào folder đó trong ngữ cảnh gọi mở app khác, dẫn đến mã lỗi OSStatus `-54` (`permErr`) và hiển thị popup cảnh báo lỗi.

### Giải pháp kỹ thuật (URL Scheme Delegation Architecture)
1. **Host App**:
   - Đăng ký Custom URL Scheme `findermenutools://` trong `Info.plist`.
   - Trong `AppDelegate.swift`, triển khai phương thức `application(_:open:)` để đón nhận URL `findermenutools://open?app=<iterm|terminal>&path=<path>`.
   - Vì Host App không bị sandbox (`app-sandbox = false`), nó sử dụng `/usr/bin/open -a <app> <path>` để mở tab/cửa sổ tại thư mục mục tiêu một cách an toàn và hợp lệ 100%.
2. **FinderSync Extension**:
   - Thêm `Open in Terminal` (icon `apple.terminal`) song song cùng `Open in iTerm2` (icon `terminal.fill`).
   - Thay vì gọi trực tiếp `NSWorkspace.open(withApplicationAt:)`, Extension đóng gói đường dẫn thư mục vào URL `findermenutools://open?...` và gọi `NSWorkspace.shared.open(actionURL)`.

### Kết quả kiểm thử thực tế (Verification)
- [x] Đã gửi URL test `findermenutools://open?app=terminal&path=/Users/trinhxuanchinh/Workspace/tools`: Terminal mở ngay tại thư mục chỉ định, không có bất kỳ popup phân quyền nào.
- [x] Đã gửi URL test `findermenutools://open?app=iterm&path=/Users/trinhxuanchinh/Workspace/tools`: iTerm2 nhận lệnh và mở tab mới trỏ vào đúng thư mục.
- [x] Extension đăng ký hợp lệ: `pluginkit -m -v -p com.apple.FinderSync` báo `+ com.chinh.FinderMenuTools.FinderSyncExt`.
- [x] Tiến trình `FinderSyncExt` đang hoạt động ổn định trên Finder.

---

## [2026-10-20] Giai đoạn 4: Nâng cấp Toàn diện (v1.1.0) - Đầy đủ tính năng như Windows + Dev Tools

### Mục tiêu
- Triển khai toàn bộ các tính năng đề xuất:
  1. **Open in VS Code** (nhận diện tự động).
  2. **Copy Name** (bên cạnh Copy Path).
  3. **New File Here...** (tạo file trống với popup nhập tên).
  4. **Toggle Hidden Files** (chuyển đổi ẩn/hiện file ẩn Finder).
  5. **Smart App Detection** (chỉ hiện iTerm2/VS Code nếu máy có cài).
  6. **Giao diện Cài đặt (Settings UI)** cho phép bật/tắt từng tính năng qua `UserDefaults`.

### Triển khai & Xác minh
- **Host App (`AppDelegate.swift`)**:
  - Bổ sung các checkbox cấu hình trong cửa sổ cài đặt.
  - Xử lý các scheme: `findermenutools://open?app=vscode`, `findermenutools://newfile`, `findermenutools://toggle-hidden`.
- **Extension (`FinderSync.swift`)**:
  - Đọc cấu hình từ `UserDefaults` và chỉ hiển thị các mục người dùng đã bật.
  - Tự động kiểm tra file cài đặt để hiển thị hoặc ẩn iTerm2 / VS Code.
- **Kết quả kiểm thử**:
  - Lệnh mở VS Code qua URL scheme hoạt động chính xác (`Visual Studio Code` nhận diện folder dự án ngay lập tức).
  - Bản build Release đã được ký và cài đặt thành công vào `/Applications/FinderMenuTools.app`.
  - Extension `com.chinh.FinderMenuTools.FinderSyncExt` đang hoạt động trên PID `4047`.

---

## [2026-10-20] Giai đoạn 5: Tối ưu Toggle Hidden Files - Loại bỏ hiện tượng nháy tắt Finder

### Vấn đề ghi nhận (User Feedback)
- Khi chọn **Toggle Hidden Files**, Finder bị nháy tắt rồi mở lại (`killall Finder`), làm gián đoạn cửa sổ làm việc của người dùng trên màn hình.

### Nguyên nhân gốc rễ (Root Cause)
- Trước đó, ứng dụng sử dụng lệnh `killall Finder` để buộc Finder nạp lại giá trị `defaults write com.apple.Finder AppleShowAllFiles`. Lệnh này kill toàn bộ tiến trình Finder, khiến mọi cửa sổ đang mở bị đóng rồi khởi động lại.

### Giải pháp kỹ thuật (Smooth Live Toggle via CGEvent)
- Thay vì `killall Finder`, Host App kết hợp:
  1. Cập nhật giá trị `AppleShowAllFiles` (true <-> false) trong `defaults` để lưu trạng thái bền vững.
  2. Bắn sự kiện phím tắt native `Cmd + Shift + .` (Virtual KeyCode `47` kết hợp `flags: [.maskCommand, .maskShift]`) trực tiếp vào session và HID event tap thông qua `CGEvent`.
- **Kết quả**:
  - Finder tự động cập nhật ẩn/hiện file ẩn ngay lập tức trong cửa sổ hiện tại mà **không bị tắt, không bị nháy, cửa sổ giữ nguyên 100% trên màn hình**.
  - Đã kiểm tra tự động qua URL scheme `findermenutools://toggle-hidden`, giá trị chuyển đổi mượt mà giữa `0` và `1` mà không làm thay đổi PID của Finder.
