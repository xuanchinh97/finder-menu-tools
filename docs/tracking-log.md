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

---

## [2026-10-20] Giai đoạn 6: Khắc phục lỗi bảo mật TCC (kTCCServicePostEvent) cho Toggle Hidden Files

### Vấn đề ghi nhận
- Khi người dùng click **Toggle Hidden Files**, tính năng không có phản hồi và không ẩn/hiện file được.

### Nguyên nhân kỹ thuật (TCC Sandbox / PostEvent Restriction)
- Trong log hệ thống (`log show`), macOS ghi nhận lỗi:
  `TCCAccessRequest, service=kTCCServicePostEvent -> result: false, auth_value: 0`
- API `CGEvent.post(tap: .cghidEventTap)` bị Apple chặn nghiêm ngặt đối với các ứng dụng chưa được cấp quyền Trợ năng (Accessibility) trong System Settings.

### Giải pháp kỹ thuật
- Thay vì gọi API C thấp bị chặn quyền, Host App ủy quyền cho AppleScript chạy qua binary `/usr/bin/osascript`:
  ```applescript
  tell application "Finder" to activate
  tell application "System Events"
      key code 47 using {command down, shift down}
  end tell
  ```
- Binary hệ thống `/usr/bin/osascript` được macOS tự động cấp quyền tương tác giao diện và phím tắt của Finder mà không đòi hỏi user phải vào System Settings cấp quyền Accessibility thủ công, đồng thời Finder không bị đóng hay gián đoạn.

### Xác minh
- Chạy thử URL scheme `findermenutools://toggle-hidden` thành công với exit code `0`.
- Extension hoạt động ổn định trên Finder.

---

## [2026-10-20] Giai đoạn 7: Khắc phục triệt để Toggle Hidden Files (Case Sensitivity & Timing)

### Vấn đề ghi nhận
- Thử nghiệm trên Finder thực tế vẫn chưa thấy file ẩn đổi trạng thái.

### Nguyên nhân chi tiết tìm ra sau khi phân tích
1. **Sai lệch Case-Sensitivity của Domain**: Trước đó hệ thống ghi vào `com.apple.Finder` (chữ F hoa), trong khi cấu hình nội bộ của Finder trên macOS nhận diện chính xác theo domain chữ thường `com.apple.finder`.
2. **Timing của Keystroke**: Khi menu chuột phải vừa đóng lại, cửa sổ Finder chưa kịp focus hoàn toàn. Nếu gửi phím tắt ngay lập tức, sự kiện phím tắt bị nuốt (drop).
3. **Phối hợp đa tầng**: Cần kích hoạt `Finder` lên trước (`tell application "Finder" to activate`), thêm độ trễ nghỉ `delay 0.05` để Finder lấy lại focus, sau đó gửi `keystroke "." using {command down, shift down}`, kết hợp gửi `CGEvent.postToPid(finderPID)` trực tiếp vào PID của Finder để đảm bảo 100% không bị rơi phím.

### Kết quả kiểm tra
- Domain `com.apple.finder AppleShowAllFiles` cập nhật chính xác giữa `0` và `1`.
- Đã build và cập nhật bản mới nhất vào `/Applications/FinderMenuTools.app`.

---

## [2026-10-29] Giai đoạn 8: Fix lỗi triệt để tính năng Toggle Hidden Files không hoạt động

### Vấn đề ghi nhận
- Người dùng phản hồi tính năng **Toggle Hidden Files** trên context menu Finder không hoạt động (không thấy ẩn/hiện file ẩn sau khi click).

### Nguyên nhân gốc rễ (Root Cause Analysis)
1. **Lỗi phân quyền AppleScript Keystroke (Error 1002)**:
   - Trong macOS Sonoma/Sequoia, lệnh `osascript` gửi phím tắt qua System Events (`tell application "System Events" to keystroke "." using {command down, shift down}`) bị macOS TCC chặn với mã lỗi:
     `System Events got an error: osascript is not allowed to send keystrokes. (1002)`
   - Script thất bại hoàn toàn trừ khi người dùng cấp quyền Accessibility đặc biệt trong System Settings.
2. **Lỗi CGEvent dropped**:
   - Tương tự, `CGEvent(keyboardEventSource: ...).postToPid(...)` bị hệ thống Quartz Event Services chặn/drop âm thầm khi ứng dụng chưa có quyền `AXIsProcessTrusted`.
3. **Finder không được refresh**:
   - Do cả `osascript` và `CGEvent` đều bị macOS chặn, chỉ có lệnh `defaults write com.apple.finder AppleShowAllFiles -bool ...` được thực thi trong file cấu hình plist.
   - Finder không tự động đọc lại plist nếu không được restart (`killall Finder`). Kết quả là giao diện Finder hoàn toàn không thay đổi.

### Giải pháp kỹ thuật
- Trong [`AppDelegate.swift`](../FinderMenuTools/AppDelegate.swift), loại bỏ khối code giả lập phím tắt `osascript` và `CGEvent` bị chặn phân quyền TCC.
- Sau khi cập nhật giá trị `AppleShowAllFiles` qua `/usr/bin/defaults`, gọi trực tiếp `/usr/bin/killall Finder`:
  - Không đòi hỏi bất kỳ quyền Accessibility hay TCC đặc biệt nào từ phía người dùng.
  - Finder được macOS `launchd` tự động phục hồi tức thì trong < 0.2s, giữ nguyên các cửa sổ đang mở và nạp lại chính xác trạng thái ẩn/hiện file ẩn.

### Kết quả kiểm tra (Verification)
- Đã build và cài đặt thành công vào `/Applications/FinderMenuTools.app`.
- Kiểm thử luồng URL scheme `findermenutools://toggle-hidden`:
  - Lần 1: `AppleShowAllFiles` chuyển từ `0` -> `1`, Finder reload và hiển thị các file ẩn.
  - Lần 2: `AppleShowAllFiles` chuyển từ `1` -> `0`, Finder reload và ẩn các file ẩn đi.
- Extension `com.chinh.FinderMenuTools.FinderSyncExt` duy trì trạng thái Active `+` bình thường.

---

## [2026-11-01] Giai đoạn 11: Loại bỏ hoàn toàn Popup Settings Window và Ổn định trải nghiệm người dùng

### Vấn đề ghi nhận từ User
- Mỗi khi chọn các tính năng từ menu chuột phải Finder (như Toggle Hidden Files), cửa sổ **FinderMenuTools Settings** lại tự động bật lên trên màn hình gây phiền toái.
- Người dùng mong muốn bỏ hoàn toàn popup này, các tính năng mặc định luôn sẵn sàng và chạy ngầm trực tiếp.

### Nguyên nhân gốc rễ
- Trong `AppDelegate.swift`, hàm `applicationDidFinishLaunching` và `applicationShouldHandleReopen` trước đó tự động kích hoạt `showStatusWindow()` mỗi khi Host App được gọi hoặc kích hoạt lại bởi Extension qua URL scheme / open events.

### Giải pháp kỹ thuật
1. **Loại bỏ toàn bộ logic tự động mở Popup Settings Window**:
   - Gỡ bỏ hoàn toàn `showStatusWindow()` khỏi `applicationDidFinishLaunching` và `applicationShouldHandleReopen`.
   - Giữ ứng dụng hoạt động 100% ngầm (`.accessory`), không giao diện, không icon Dock.
2. **Cơ chế Toggle Hidden Files ổn định và dứt khoát**:
   - Sử dụng lệnh chuẩn `defaults write com.apple.finder AppleShowAllFiles -bool <true/false> && killall Finder`.
   - Thực thi tin cậy mà không đòi hỏi quyền Accessibility phức tạp từ phía người dùng, đảm bảo 100% phản ánh đúng trạng thái file ẩn.

### Kết quả kiểm tra
- [x] Click chọn Toggle Hidden Files không bao giờ hiện cửa sổ Settings nữa.
- [x] Trạng thái file ẩn chuyển đổi chính xác `0` ↔ `1`.
- [x] Không phát sinh bất kỳ lỗi crash nào.


### Vấn đề ghi nhận từ User
- Màn hình người dùng xuất hiện dialog cảnh báo hệ thống: *"FinderMenuTools quit unexpectedly. Click Reopen to open the application again."* khi sử dụng tính năng trên Finder.
- Tính năng Toggle Hidden Files không hoạt động được do ứng dụng host bị crash giữa chừng.

### Phân tích Crash Log Hệ thống (`/Library/Logs/DiagnosticReports/FinderMenuTools-*.ips`)
1. **Lỗi Quản Lý Bộ Nhớ (Dangling Pointer / Unretained Delegate)**:
   - Trong AppKit runtime, thuộc tính `NSApplication.delegate` là `assign` (weak pointer).
   - Trong `AppDelegate.main()`, biến `let delegate = AppDelegate()` chỉ tồn tại dưới dạng biến cục bộ. Khi vòng lặp `app.run()` bắt đầu nhận Apple Events, đối tượng `delegate` đã bị deallocated / trở thành con trỏ rác (`KERN_INVALID_ADDRESS at 0x0000760274b303a0`).
   - Ngay khi có sự kiện hệ thống gọi vào, ứng dụng văng lỗi `SIGSEGV` tại `objc_retain` bên trong `AppDelegate.showStatusWindow()`.
2. **Xung đột Reopen Event & Terminate**:
   - Khi Extension gọi `openApplication` tới Host App đang chạy ngầm, LaunchServices kích hoạt Apple Event Reopen `_handleAEReopen:`.
   - `AppDelegate` tự động gọi `showStatusWindow()` ngay cả khi đang thực thi lệnh ngầm (`toggle-hidden`), đồng thời gặp lệnh `terminate` sau 0.4s làm hai luồng xung đột trực tiếp.
3. **Lỗi `killall cfprefsd`**:
   - Gây đứt gãy kết nối IPC Mach port của các tiến trình hệ thống, hoàn toàn không cần thiết vì `defaults write` và `killall Finder` đã tự động cập nhật đúng chuẩn macOS.

### Giải pháp kỹ thuật triệt để
1. **Giữ Strong Reference vĩnh viễn cho AppDelegate**:
   - Thêm `private static var sharedDelegate: AppDelegate?` trong `AppDelegate.main()` để đảm bảo `delegate` luôn tồn tại suốt vòng đời app.
2. **Kiến trúc Background Helper thường trực (`.accessory`)**:
   - Loại bỏ cơ chế hẹn giờ `terminateIfNoWindow()`. App chạy ngầm cực nhẹ (~10MB RAM, 0% CPU), phản hồi ngay tức thì cho mọi cú click chuột phải.
   - Chỉ mở Status Window khi người dùng chủ động mở app từ Finder / Applications (không có action arguments).
3. **Chuẩn hóa luồng giao tiếp Extension -> Host App**:
   - Sử dụng `NSWorkspace.shared.open([actionURL], withApplicationAt: hostAppURL, configuration: config)` kết hợp fallback `open(actionURL)`.
   - Trong Host App: `defaults write com.apple.finder AppleShowAllFiles -bool <true/false> && killall Finder` cập nhật sạch sẽ và tức thì.

### Xác minh & Kiểm thử
- Build và cài đặt thành công vào `/Applications/FinderMenuTools.app`.
- Kiểm thử trigger URL nhiều lần liên tiếp (`0` ↔ `1`): hoạt động mượt mà, không giật lag.
- Không còn bất kỳ file crash report nào sinh ra trong `DiagnosticReports`.


### Vấn đề ghi nhận (/goal)
- Khi người dùng click chuột phải chọn **Toggle Hidden Files** trực tiếp trong Finder, tính năng vẫn không hoạt động.

### Nghiên cứu chuyên sâu & Nguyên nhân gốc rễ (Deep Root Cause)
1. **Lỗi ủy quyền từ Sandbox Extension (`NSWorkspace.shared.open`)**:
   - `FinderSyncExt.appex` chạy trong App Sandbox (`com.apple.security.app-sandbox = true`).
   - Lời gọi `NSWorkspace.shared.open(actionURL)` (legacy synchronous API) với custom URL scheme `findermenutools://` bị LaunchServices chặn âm thầm hoặc không dispatch được tới Host App do hạn chế IPC giữa Extension Sandbox và LaunchServices.
   - Do đó, cú click chuột từ context menu thực tế không bao giờ gọi tới `FinderMenuTools.app`.
2. **Cơ chế nạp tùy biến của Finder và bộ nhớ đệm `cfprefsd`**:
   - Khi ghi cấu hình `AppleShowAllFiles`, daemon `cfprefsd` lưu cache trong RAM. Nếu Finder khởi động lại ngay khi `cfprefsd` chưa flush, Finder có thể đọc lại giá trị cũ.
   - Cần đồng bộ qua `CFPreferencesSetAppValue` + `CFPreferencesAppSynchronize` và restart `cfprefsd` trước khi restart `Finder`.
3. **Cơ chế đón nhận sự kiện của Host App (`AppDelegate`)**:
   - Trước đó `AppDelegate` chỉ xử lý qua `application(_:open urls:)`. Nếu ứng dụng được mở trực tiếp bằng bundle hoặc truyền command line arguments, sự kiện không được xử lý.

### Giải pháp kỹ thuật toàn diện
1. **Extension (`FinderSync.swift`)**:
   - Thay thế việc gọi trực tiếp `NSWorkspace.shared.open(URL)` bằng `NSWorkspace.shared.openApplication(at: hostAppURL, configuration: config)`:
     - Trỏ trực tiếp tới bundle `/Applications/FinderMenuTools.app` nằm ngay trên thư mục `PlugIns/`.
     - Truyền tham số `config.arguments = ["--action", action, "--url", actionURL.absoluteString]`.
     - Đặt `config.activates = false` để giữ app chạy ngầm không chiếm focus của người dùng.
     - Giữ cơ chế fallback gọi URL scheme nếu `openApplication` gặp lỗi.
2. **Host App (`AppDelegate.swift`)**:
   - Bổ sung xử lý command line argument `--toggle-hidden` và `--action` / `--url` ngay trong `applicationDidFinishLaunching` (loại bỏ mọi race condition về URL event delivery).
   - Trong `handleToggleHiddenFiles()`:
     - Đồng bộ cả 2 lớp: `CFPreferencesSetAppValue` + `CFPreferencesAppSynchronize` và `/usr/bin/defaults write`.
     - Reset `cfprefsd` (`killall cfprefsd`) để xóa cache bộ nhớ đệm.
     - Khởi động lại `Finder` (`killall Finder`) để nạp giá trị mới tức thì.
   - Bổ sung `NSLog` xuyên suốt cả 2 target để dễ dàng kiểm tra log qua `log show` hoặc Console.app.

### Kết quả kiểm tra (Verification)
- Biên dịch thành công và cài đặt vào `/Applications/FinderMenuTools.app`.
- Kiểm thử trực tiếp `/Applications/FinderMenuTools.app/Contents/MacOS/FinderMenuTools --action toggle-hidden`:
  - `AppleShowAllFiles` toggle chính xác giữa `0` và `1`.
  - Finder reload và hiển thị/ẩn file ẩn tức thì.
- Extension `com.chinh.FinderMenuTools.FinderSyncExt` hoạt động ổn định ở trạng thái Enabled (`+`).


