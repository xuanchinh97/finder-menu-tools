# Hướng dẫn Cài đặt & Sử dụng (Usage & Setup)

## 1. Yêu cầu hệ thống
- macOS 14.0+ (Apple Silicon / Intel)
- Xcode / Command Line Tools (Swift 6+)
- [iTerm2](https://iterm2.com/) được cài đặt tại `/Applications/iTerm.app` (hoặc fallback về `Terminal.app` nếu máy chưa cài iTerm2).

## 2. Build & Cài đặt tự động
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
