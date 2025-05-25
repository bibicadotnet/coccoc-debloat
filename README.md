# Giao diện Cốc Cốc sạch như Chromium nguyên bản

- Tắt các tiện ích mặc định (Từ Điển, Rủng Rỉnh)
- Thay thế trang newtab bằng một trang trắng sạch sẽ
- Tắt mọi tiến trình chạy ngầm và cập nhật tự động.
- Tắt gần như mọi thứ có thể gửi thông tin về Google hay Cốc Cốc
- Thiết lập quyền riêng tư ở mức nghiêm ngặt: tắt cookie của bên thứ ba, tắt thông báo, tắt định vị
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
- Tắt split view

  Copy trực tiếp link bên dưới vào trình duyệt, chọn Disabled
```
coccoc://flags/#coccoc-split-view
```
- Tắt side panel

Copy trực tiếp link bên dưới vào trình duyệt, chọn Disabled
```
coccoc://flags/#coccoc-side-panel
```
💡 Trong trường hợp muốn bặt/tắt các tính năng khác cho phù hợp với nhu cầu cá nhân hơn
- Mở `coccoc-debloat.reg` bật/tắt các tính năng, bằng cách thêm `;` đằng trước (hoặc xóa nội dung đó đi)
- Chạy `coccoc-restore.reg` để xóa toàn bộ cấu hình cũ
- Chạy lại `coccoc-debloat.reg` để áp dụng cấu hình mới
