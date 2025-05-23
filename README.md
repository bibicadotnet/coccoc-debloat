# Giúp giao diện Cốc Cốc sạch như Chromium nguyên bản

- Tắt chạy ngầm, tắt tự cập nhập và tắt 1 số tính năng giúp tăng cường bảo mật, tốc độ, riêng tư ... 
- Cốc Cốc Extensions: giữ lại Download video & audio
- Extensions bổ xung mặc định: Blank New Tab Page (giúp làm sạch quảng cáo khi mở tab mới)
### Cài đặt và cập nhập
- Chạy `PowerShell` với quyền `Administrator` để cài đặt/cập nhập lại Cốc Cốc
```
irm https://go.bibica.net/coccoc | iex
```
- Hoặc download file [coccoc.bat](https://github.com/bibicadotnet/coccoc-debloat/blob/main/coccoc.bat) về PC, sau cập nhập cho tiện
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
