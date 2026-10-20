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
