# Giao diện Cốc Cốc sạch như Chromium nguyên bản

- Tắt các tiện ích mặc định (Từ Điển, Rủng Rỉnh)
- Tắt side panel, split view
- Thay thế trang newtab bằng một trang trắng sạch sẽ
- Tắt mọi tiến trình chạy ngầm và cập nhật tự động.
- Tắt gần như mọi thứ có thể gửi thông tin về Google hay Cốc Cốc
- Thiết lập quyền riêng tư ở mức nghiêm ngặt: tắt cookie của bên thứ ba, tắt thông báo, tắt định vị, tắt cảm biến chuyển động
- Sử dụng tự động DNS Cloudflare để tăng tốc và bảo vệ quyền riêng tư.
- Bật tính năng tiết kiệm RAM (Memory Saver)
- .....
### Cài đặt và cập nhập
- Chạy `PowerShell` với quyền `Administrator` để cài đặt/cập nhập lại Cốc Cốc
```
irm https://go.bibica.net/coccoc | iex
```
- Hoặc chạy file [coccoc.bat](https://github.com/bibicadotnet/coccoc-debloat/archive/latest.zip) trực tiếp từ PC, sau cập nhập cho tiện
### Tùy chỉnh thêm
Shortcut Cốc Cốc chạy qua `--disable-features=CocCocSplitView,SidePanel` để tắt split view và side panel, cần bật lại thì xóa dòng này ở `Target` đi

Click phải vào shortcut Cốc Cốc -> Chọn Properties  -> Trong tab Shortcut -> sẽ thấy ô Target

- Tắt/Bật split view thủ công

  Copy trực tiếp link bên dưới vào trình duyệt, chọn Disabled/Enabled
```
coccoc://flags/#coccoc-split-view
```
- Tắt/Bật side panel thủ công

Copy trực tiếp link bên dưới vào trình duyệt, chọn Disabled/Enabled
```
coccoc://flags/#coccoc-side-panel
```
💡 Trong trường hợp muốn bặt/tắt các tính năng khác cho phù hợp với nhu cầu cá nhân hơn
- Mở `coccoc-debloat.reg` bật/tắt các tính năng, bằng cách thêm `;` đằng trước (hoặc xóa nội dung đó đi)
- Chạy `coccoc-restore.reg` để xóa toàn bộ cấu hình cũ
- Chạy lại `coccoc-debloat.reg` để áp dụng cấu hình mới

### Tạo nhanh profile
- Chạy `PowerShell` với quyền `Administrator` để tạo nhanh profile mới cho trình duyệt Cốc Cốc (hỗ trợ tùy chọn nơi chứa profile)
```
irm https://go.bibica.net/coccoc-profile | iex
```
Hoặc tạo 1 shortcut Cốc Cốc, thêm vào Target `--user-data-dir="C:\Private\coccoc_lamviec"` 
- `C:\Private\coccoc_lamviec` đường dẫn nơi chứa profile
