# Hướng dẫn Cài đặt & Sử dụng (Usage & Setup)

## 1. Yêu cầu hệ thống & Tính năng hỗ trợ
- macOS 14.0+ (Apple Silicon / Intel).
- Tự động nhận diện các phần mềm có sẵn trên máy:
  - **Terminal**: Tích hợp sẵn trong macOS.
  - **iTerm2**: Nhận diện tại `/Applications/iTerm.app`.
  - **Visual Studio Code**: Nhận diện tại `/Applications/Visual Studio Code.app`.

## 2. Danh sách tính năng trên Context Menu
- **Copy Path**: Copy đường dẫn tuyệt đối (nhiều file/folder sẽ nối bằng `\n`).
- **Copy Name**: Copy riêng tên file/folder (kèm đuôi mở rộng).
- **Open in Terminal**: Mở Terminal tại đường dẫn đang chọn.
- **Open in iTerm2**: Mở iTerm2 tại đường dẫn đang chọn.
- **Open in VS Code**: Mở VS Code tại thư mục dự án đang chọn.
- **New File Here...**: Mở popup để nhập tên file mới và tạo file trống ngay tại folder đó.
- **Toggle Hidden Files**: Bật/tắt chế độ hiển thị file ẩn trong Finder.

## 3. Tùy biến bật/tắt tính năng (Preferences)
- Mở ứng dụng `/Applications/FinderMenuTools.app`.
- Bạn có thể tick chọn hoặc bỏ tick bất kỳ tính năng nào không dùng đến.
- Nhấn **Refresh Finder** để cập nhật lại menu ngay lập tức.
Chạy script cài đặt tự động tại thư mục gốc của dự án:

```bash
./scripts/install.sh
```

Script này sẽ thực hiện:
1. Build target `FinderMenuTools` (bao gồm cả `FinderSyncExt.appex`) ở chế độ `Release`.
2. Copy `FinderMenuTools.app` vào `/Applications/FinderMenuTools.app`.
3. Đăng ký và kích hoạt extension với hệ thống qua `pluginkit`.
4. Khởi động lại Finder để nạp menu chuột phải mới.

## 3. Kiểm tra trạng thái & Chẩn đoán lỗi
Sử dụng script chẩn đoán trong AI Agent Skill:

```bash
./.agents/skills/macos-finder-sync/scripts/diagnose.sh
```

Nếu menu chuột phải chưa hiển thị:
1. Mở `/Applications/FinderMenuTools.app` và kiểm tra trạng thái.
2. Hoặc vào **System Settings > General > Login Items & Extensions > Finder** (hoặc **Extensions > Finder Extensions**) và bật **FinderMenuTools**.
3. Chạy lệnh làm mới Finder:
   ```bash
   killall FinderSyncExt 2>/dev/null || true
   killall Finder
   ```
