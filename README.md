# 🧼 Cốc Cốc Debloat

Mục tiêu: cố gắng làm sạch mọi thứ không cần thiết, tối ưu hiệu năng, bảo vệ quyền riêng tư, dễ tùy chỉnh theo nhu cầu cá nhân.

---

## Các tính năng đã tắt hoặc điều chỉnh

| Tính năng | Trạng thái |
|----------|------------|
| Tiện ích mặc định (Từ Điển, Rủng Rỉnh) | Đã tắt |
| **Passwords Manager** | Đã tắt |
| Extension Tab mới (New Tab) | Thay thế bằng trang sạch không quảng cáo |
| Extension Google Search Clean | Thay thế thay thế tìm kiếm mặc định bằng Google |
| `CocCocCrashHandler` (tiến trình nền) | Đã tắt |
| `CocCocUpdate` (tự động cập nhật) | Đã tắt |
| Gửi dữ liệu về máy chủ Google/Cốc Cốc | Hầu hết đã bị vô hiệu hóa |
| Quyền riêng tư | Thiết lập ở mức cao:<br> - Tắt cookie bên thứ ba<br> - Tắt thông báo<br> - Tắt định vị & cảm biến chuyển động <br> - Có thể cài đặt Canvas Blocker giúp bạn ẩn danh hơn khi lướt web|
| DNS mặc định | Sử dụng Cloudflare Gateway DNS hỗ trợ ECS giúp tăng tốc và chặn 1 phần quảng cáo |
| Tính năng tiết kiệm RAM | Bật chế độ Balanced memory savings |

---

## ⚙️ Cách cài đặt / cập nhật

### Chạy script PowerShell

> ⚠️ Yêu cầu chạy PowerShell với quyền **Administrator**

Cốc Cốc Debloat được cài đặt trực tiếp qua Omaha API, không dùng bản setup mặc định, hạn chế các lỗi cài đặt [không thành công](https://www.facebook.com/groups/CocCocGroup/posts/2356258015130605)

```powershell
irm https://go.bibica.net/coccoc | iex
```

- Chạy lại mỗi khi cần cập nhập lên phiên bản mới nhất

### Chặn Cốc Cốc Savior popup/ads​
Cốc Cốc Savior là công cụ download video rất mạnh được Cốc Cốc duy trì nhiều năm, thi thoảng nó hiện ra 1 số popup/ads hơi phiền

- Có thể chặn bằng uBlock Origin qua Filter lists → Import thêm vào

```
https://raw.githubusercontent.com/bibicadotnet/ublock-filters/main/coc-coc-savior.txt
```

- Hoặc thêm trực tiếp 4 rule

```
##savior-host
###mobile-wrapper
###onboard-nmp
###onboard-yaa
```

### Thay thế tìm kiếm mặc định

Cốc Cốc Debloat tự cài đặt extension [Google Search Clean](https://github.com/bibicadotnet/Google-Search-Clean) khi lần đầu sử dụng (extension sau khi cài sẽ tắt theo mặc định), nó sẽ dùng Google làm tìm kiếm mặc định, xóa bớt phần AI Overview và dọn URL tracking giúp tìm kiếm nhanh hơn

## 🧑‍💼 Tạo profile riêng biệt

- Có thể tạo nhiều shortcut profile khác nhau (hỗ trợ tùy chọn nơi chứa profile riêng) cho từng mục đích sử dụng (ví dụ: làm việc, học tập, giải trí).

### Phương pháp 1: Chạy script PowerShell

```powershell
irm https://go.bibica.net/coccoc-profile | iex
```

### Phương pháp 2: Thêm tham số vào shortcut

Thêm vào cuối `Target` trong shortcut:

```text
--user-data-dir="C:\Private\coccoc_lamviec"
```

> 📁 Đường dẫn `C:\Private\coccoc_lamviec` là nơi lưu trữ dữ liệu người dùng độc lập.

---
### Đường dẫn pin shortcut profile
```
%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\ImplicitAppShortcuts
```

---

## 🌐 Thiết lập trình duyệt mặc định (cho profile tùy chỉnh)

- Lưu bất kỳ trang web nào về máy dưới dạng file .html
  - (Nhấn Ctrl + S trên trình duyệt → chọn định dạng “Webpage, complete”).
- Mở thư mục chứa file .html vừa lưu.
- 🖱 Chuột phải vào file đó → chọn Mở bằng (Open with) → Chọn ứng dụng khác (Choose another app).
  - ✅ Đánh dấu vào ô “Always use this app to open .html files”
- Trong danh sách, tìm tới vị để với profile shortcut bạn muốn đặt làm mặc định (ví dụ: `coccoc_lamviec`, nếu đã đăng ký trình duyệt này qua script bat).
- Bấm Open để hoàn tất.

> 🧠 **Lưu ý:**
> Do giới hạn của Windows 10/11, không thể đặt trình duyệt mặc định hoàn toàn qua script – cần thực hiện thủ công như trên.

---
