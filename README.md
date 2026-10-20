# FinderMenuTools

Công cụ mở rộng menu chuột phải (Context Menu) cho macOS Finder tương tự Windows, viết bằng Swift (AppKit + FinderSync):
- **Copy Path**: Copy đường dẫn tuyệt đối của Folder/File đang chọn.
- **Open in iTerm2**: Mở nhanh `iTerm2` tại Folder đang chọn (hoặc thư mục cha nếu chọn File).

## Cấu trúc thư mục
- `AGENTS.md`: Quy tắc thực thi dành cho AI Agent trong phạm vi dự án.
- `.agents/skills/macos-finder-sync/`: Runbook và script chẩn đoán chuyên biệt cho Finder Sync Extension.
- `docs/`:
  - [architecture.md](./docs/architecture.md): Kiến trúc hệ thống.
  - [usage-and-setup.md](./docs/usage-and-setup.md): Hướng dẫn cài đặt và sử dụng.
  - [tracking-log.md](./docs/tracking-log.md): Nhật ký theo dõi tiến độ triển khai.
- `FinderMenuTools/`: Mã nguồn ứng dụng Host.
- `FinderSyncExt/`: Mã nguồn Finder Sync Extension.
- `scripts/install.sh`: Script tự động build và cài đặt vào `/Applications`.
