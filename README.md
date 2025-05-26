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
| Quyền riêng tư | ✅ Thiết lập ở mức cao:<br> - Tắt cookie bên thứ ba<br> - Tắt thông báo<br> - Tắt định vị & cảm biến chuyển động |
| DNS mặc định | ✅ Sử dụng Cloudflare để tăng tốc và bảo mật |
| Tính năng tiết kiệm RAM | ✅ Bật chế độ Balanced memory savings |

---

## ⚙️ Cách cài đặt / cập nhật

### Phương pháp 1: Chạy script PowerShell

> ⚠️ Yêu cầu chạy PowerShell với quyền **Administrator**

```powershell
irm https://go.bibica.net/coccoc | iex
```

### Phương pháp 2: Tải file `.bat` về và chạy trực tiếp

📁 Download [`coccoc.bat`](https://github.com/bibicadotnet/coccoc-debloat/archive/latest.zip)

> 💡 Sau khi cài đặt, bạn có thể dùng file này để **cập nhật** nhanh chóng.

---

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



