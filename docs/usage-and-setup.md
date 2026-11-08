# Hướng dẫn cài đặt và sử dụng

## Yêu cầu

- macOS 14 trở lên.
- Xcode và macOS command-line build tools.
- Terminal có sẵn trong macOS. iTerm2 và Visual Studio Code là tùy chọn.

Finder Menu Tools phát hiện iTerm2 tại `/Applications/iTerm.app` và Visual Studio Code tại `/Applications/Visual Studio Code.app`. Nếu ứng dụng nằm nơi khác, mục tương ứng sẽ không xuất hiện trong menu.

## Cài đặt nhanh

Từ thư mục gốc repo:

```bash
./scripts/install.sh
```

Script dùng `xcodebuild` để build cấu hình Release, cài `FinderMenuTools.app` vào `/Applications`, ký cục bộ app và extension, đăng ký/bật extension bằng `pluginkit`, rồi khởi động lại Finder. Tài khoản chạy script cần có quyền ghi vào `/Applications`. Lưu công việc đang mở trong Finder trước khi cài đặt.

Nếu muốn chỉ build mà chưa cài, hãy mở `FinderMenuTools.xcodeproj` trong Xcode, chọn scheme **FinderMenuTools** và cấu hình **Release**. Lệnh build mà script sử dụng:

```bash
xcodebuild \
  -project FinderMenuTools.xcodeproj \
  -target FinderMenuTools \
  -configuration Release \
  SYMROOT=build \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  clean build
```

## Bật Finder Sync extension

Sau khi chạy script, kiểm tra **System Settings → General → Login Items & Extensions → Finder Extensions** và bật **FinderMenuTools** nếu đang tắt. Vị trí hoặc tên mục có thể thay đổi nhẹ giữa các phiên bản macOS.

Kiểm tra trạng thái bằng:

```bash
pluginkit -m -v -i com.chinh.FinderMenuTools.FinderSyncExt
```

## Dùng menu

Bấm chuột phải vào một hay nhiều tệp/thư mục, hoặc bấm chuột phải vào vùng trống trong cửa sổ Finder:

| Mục menu | Kết quả |
| --- | --- |
| Copy Path | Sao chép đường dẫn POSIX đầy đủ; nhiều mục được nối bằng dòng mới. |
| Copy Name | Sao chép tên từng mục; nhiều tên được nối bằng dòng mới. |
| Open in Terminal | Mở thư mục được chọn; nếu chọn tệp thì mở thư mục cha. |
| Open in iTerm2 | Tương tự Terminal, chỉ hiện khi iTerm2 ở `/Applications/iTerm.app`. |
| Open in VS Code | Mở thư mục được chọn hoặc thư mục cha của tệp; chỉ hiện khi VS Code ở `/Applications/Visual Studio Code.app`. |
| New File Here… | Hiện hộp thoại nhập tên và tạo tệp rỗng trong thư mục đích. Dùng thư mục đầu tiên khi chọn nhiều mục. Không ghi đè tệp đã có cùng tên. |
| Toggle Hidden Files | Đổi tùy chọn hiện tệp ẩn của Finder, sau đó khởi động lại Finder để áp dụng. |

Với thao tác mở, nhiều mục cùng nằm trong một thư mục chỉ mở thư mục đó một lần. Tệp được chuyển thành thư mục chứa tệp. Toggle Hidden Files ảnh hưởng thiết lập Finder của người dùng hiện tại và khởi động lại Finder.

## Xử lý lỗi

1. Xác nhận FinderMenuTools đang bật trong phần **Finder Extensions** của System Settings.
2. Nếu menu chưa được nạp lại, khởi động lại Finder:

   ```bash
   killall Finder
   ```

3. Nếu mục iTerm2 hoặc VS Code không hiện, kiểm tra vị trí cài đặt đúng như phần Yêu cầu.
4. Xem trạng thái extension:

   ```bash
   pluginkit -m -v -i com.chinh.FinderMenuTools.FinderSyncExt
   ```

## Gỡ cài đặt

1. Tắt FinderMenuTools trong **System Settings → General → Login Items & Extensions → Finder Extensions**.
2. Chuyển `/Applications/FinderMenuTools.app` vào Thùng rác.

Có thể tắt extension bằng Terminal trước:

```bash
pluginkit -e ignore -i com.chinh.FinderMenuTools.FinderSyncExt
```
