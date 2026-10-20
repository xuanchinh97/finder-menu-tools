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
