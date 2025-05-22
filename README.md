# Làm sạch trình duyệt Cốc Cốc

Tắt chạy ngầm, tắt tự cập nhập và tắt 1 số tính năng giúp tăng cường bảo mật, tốc độ, riêng tư ... 
### Cài đặt
- Chạy `PowerShell` với quyền `Administrator` để cài đặt lại Cốc Cốc
```
irm https://go.bibica.net/coccoc | iex
```
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
- Mở `coccoc-debloat.reg` bặt/tắt các tính năng, bằng cách thêm `;` đằng trước (hoặc xóa nội dung đó đi)
- Chạy `coccoc-restore.reg` để xóa toàn bộ cấu hình cũ
- Chạy lại `coccoc-debloat.reg` để áp dụng cấu hình mới
