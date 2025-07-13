---

# 🧼 Giao diện Cốc Cốc sạch như Chromium nguyên bản

>
  Mục tiêu: Giống giao diện Chrome/Chromium thuần, tối ưu hiệu năng, bảo vệ quyền riêng tư, dễ tùy chỉnh theo nhu cầu cá nhân.

---

## ✅ Các tính năng đã tắt hoặc điều chỉnh

| Tính năng | Trạng thái |
|----------|------------|
| Tiện ích mặc định (Từ Điển, Rủng Rỉnh) | ✅ Đã tắt |
| Side Panel | ✅ Đã tắt |
| Split View | ✅ Đã tắt |
| Tab mới (New Tab) | ✅ Thay thế bằng trang sạch không quảng cáo |
| `CocCocCrashHandler` (tiến trình nền) | ✅ Đã tắt |
| `CocCocUpdate` (tự động cập nhật) | ✅ Đã tắt |
| Gửi dữ liệu về máy chủ Google/Cốc Cốc | ✅ Hầu hết đã bị vô hiệu hóa |
| Quyền riêng tư | ✅ Thiết lập ở mức cao:<br> - Tắt cookie bên thứ ba<br> - Tắt thông báo<br> - Tắt định vị & cảm biến chuyển động <br> - Cài đặt Canvas Blocker giúp bạn ẩn danh hơn khi lướt web|
| DNS mặc định | ✅ Sử dụng Cloudflare để tăng tốc và bảo mật |
| Tính năng tiết kiệm RAM | ✅ Bật chế độ Balanced memory savings |

---

## ⚙️ Cách cài đặt / cập nhật

### Phương pháp 1: Chạy script PowerShell

> ⚠️ Yêu cầu chạy PowerShell với quyền **Administrator**

```powershell
irm https://go.bibica.net/coccoc | iex
```

### Phương pháp 2: Chạy thủ công trên Windows

Để chạy thủ công các file `.ps1` trên Windows, làm theo các bước sau:

1. 📥 **Tải mã nguồn**:

   * [Phiên bản mới nhất](https://github.com/bibicadotnet/coccoc-debloat/archive/latest.zip)
   * Hoặc xem các [bản phát hành khác](https://github.com/bibicadotnet/coccoc-debloat/releases)

2. 📦 **Giải nén** file `.zip` vừa tải về.

3. 📝 **Chuyển mã hóa file `.ps1` sang UTF-8 with BOM** (để hiển thị tiếng Việt chính xác):

   * Mở file `.ps1` bằng **Notepad**.
   * Vào **File → Save As...**
   * Ở mục **Encoding**, chọn: `UTF-8 with BOM`
   * Bấm **Save**

4. 🚀 **Chạy PowerShell tại đúng thư mục**:

   * Bên trong thư mục đã giải nén, bấm **File > Open PowerShell > Open Windows PowerShell as administrator**
   * (Tùy phiên bản Windows, có thể là: chuột phải → chọn **Open in Terminal**)

5. 🛡️ **Cho phép chạy script**:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
   ```

6. ▶️ **Chạy script chính**:

   ```powershell
   ./install-coccoc.ps1
   ```

## 🔧 Tùy chỉnh nâng cao

### 1. Bật lại Split View và Side Panel qua shortcut

👉 Click chuột phải vào shortcut → Chọn **Properties** → Tab **Shortcut** → Xóa đoạn sau ở ô **Target**:

```text
--disable-features=CocCocSplitView,SidePanel
```

> 🔁 Để tắt Split View và Side Panel lại, chỉ cần thêm dòng trên vào lại `Target`.

---

### 2. Tắt/Bật Split View thủ công

Dán đường dẫn sau vào thanh địa chỉ Cốc Cốc:

```
coccoc://flags/#coccoc-split-view
```

→ Chọn **Disabled** hoặc **Enabled** tương ứng.

---

### 3. Tắt/Bật Side Panel thủ công

Dán đường dẫn sau vào thanh địa chỉ Cốc Cốc:

```
coccoc://flags/#coccoc-side-panel
```

→ Chọn **Disabled** hoặc **Enabled** tương ứng.

---

## 📁 Quản lý cấu hình

### 1. Chỉnh sửa cấu hình tinh chỉnh

- Mở file `coccoc-restore.reg` để **khôi phục trạng thái ban đầu**.
- Mở file `coccoc-debloat.reg` để **chỉnh sửa/tùy biến** các thiết lập.
    - Thêm `;` phía trước dòng muốn tắt.
    - Xóa `;` để bật lại.

> 💡 Sau khi chỉnh sửa, hãy chạy lại file `.reg` để áp dụng thay đổi.

---

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



