# TechStore — Website bán thiết bị công nghệ

## Công nghệ và chức năng

- Backend: Java 21, Spring Boot 3.4.3, Spring Data JPA, MySQL 8, Spring Security/JWT, BCrypt, Spring Mail.
- Frontend: HTML/CSS, JavaScript ES Modules, Bootstrap 5, Chart.js; không cần bước build.
- Customer: đăng ký/đăng nhập, khôi phục mật khẩu qua email, sản phẩm, giỏ hàng, coupon, checkout, đơn hàng, đánh giá.
- Staff/Admin: đơn hàng, thêm/sửa sản phẩm, danh mục, thương hiệu, kho/chi nhánh, coupon, người dùng/nhân viên, dashboard. Quyền được kiểm tra ở backend.
- Thanh toán hỗ trợ COD và ONLINE_MOCK (giả lập, chưa tích hợp cổng thanh toán thật).

## Cấu trúc

```text
backend/src/main/java/com/techstore/
  controller/  service/  repository/  entity/  dto/
  security/  config/  exception/  specification/
backend/src/test/java/com/techstore/  # Integration tests + concurrency tests
frontend/pages/                      # Auth, products, cart, checkout, orders, admin
frontend/js/                         # API client, auth, components, configuration
database/                            # MySQL schema + demo seed
scripts/                             # Startup, isolated test database, frontend checks
docs/architecture.md
00_MASTER_CONTEXT.md                 # Đặc tả và quy chuẩn dự án
```

## Chạy trên Windows

Cài JDK 21, Node.js/npm và MySQL 8. Sao chép `.env.example` thành `.env`, đặt `JAVA_HOME`, `DB_USERNAME`, `DB_PASSWORD` phù hợp. Script PowerShell đọc `.env` theo dạng `KEY=value`; biến đã có trong môi trường được ưu tiên, riêng `JAVA_HOME` trong `.env` được ưu tiên để project luôn dùng JDK 21. Script kiểm tra phiên bản và đặt Java 21 lên đầu PATH cho tiến trình hiện tại. Không commit `.env`.

Tạo khóa JWT ngẫu nhiên bằng PowerShell, rồi lưu kết quả vào `JWT_SECRET` trong `.env`:

```powershell
$bytes = New-Object byte[] 48
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
[Convert]::ToBase64String($bytes)
$rng.Dispose()
```

Backend bắt buộc có khóa JWT tối thiểu 32 byte; không có khóa mặc định. Đổi khóa sẽ vô hiệu hóa các token cũ.

Khởi tạo database **mới** qua MySQL client:

```sql
SOURCE C:/path/to/techstore/database/schema.sql;
SOURCE C:/path/to/techstore/database/seed.sql;
```

`schema.sql` có DROP TABLE: chỉ chạy trên database mới hoặc bản sao đã sao lưu. Với database dev đang có dữ liệu, không chạy lại schema chỉ để áp dụng thay đổi mã nguồn.

Chạy `start-all.bat`, hoặc chạy riêng `start-backend.bat` và `start-frontend.bat`. Backend mặc định `http://localhost:8080`, frontend `http://localhost:5500`. Chờ thông báo backend khởi động thành công trước khi sử dụng. Frontend dùng `npx serve -l 5500`; lần đầu cần mạng để tải `serve`. Phục vụ từ thư mục `frontend/`, không mở HTML qua `file://`.

- Health: `GET /api/v1/health`
- Admin: `/pages/admin/admin.html`
- Tài khoản seed: `admin@techstore.com`, `staff@techstore.com`, `customer1@gmail.com`, `customer2@gmail.com`; mật khẩu demo `password123`.

## Email đặt lại mật khẩu

Cấu hình `MAIL_HOST`, `MAIL_PORT`, `MAIL_FROM`, `MAIL_USERNAME` và `MAIL_PASSWORD` trong `.env`. Mẫu `.env.example` dùng Gmail SMTP (`smtp.gmail.com:587`); `MAIL_PASSWORD` phải là Google App Password, không phải mật khẩu đăng nhập Gmail. Bật `MAIL_SMTP_AUTH=true` và `MAIL_STARTTLS=true`. Với SMTP thử nghiệm cục bộ, thay host/port và tắt auth/TLS theo cấu hình server đó. Nếu gửi mail lỗi, API đăng ký/resend OTP trả lỗi và không ghi OTP ra log.

`FRONTEND_URL` là địa chỉ frontend mà người nhận email truy cập được. Người dùng yêu cầu email rồi mở liên kết để đặt lại mật khẩu. Token có hạn 15 phút, dùng một lần; API không trả token và log không ghi token. Liên kết dùng URL fragment để token không đi vào access log của frontend. Nếu chưa cấu hình SMTP, chức năng gửi email sẽ báo lỗi; không có chế độ trả token trực tiếp để bỏ qua email.

Test tự động dùng mail sender giả lập, không gửi email thật.

## Checkout và quản trị sản phẩm

- ONLINE_MOCK thất bại: trả HTTP 400, không tạo đơn, không trừ kho/coupon, không xóa giỏ. Người dùng có thể thử lại.
- Checkout khóa giỏ hàng, khóa tồn kho theo thứ tự ID sản phẩm và khóa coupon khi sử dụng. Các thao tác sửa giỏ cũng khóa giỏ hàng.
- Hai yêu cầu checkout cùng giỏ: sau khi yêu cầu đầu hoàn tất, yêu cầu sau thấy giỏ trống và bị từ chối.
- Đơn COD/online giả lập thành công vẫn dùng luồng quản lý trạng thái và hoàn kho khi hủy.
- Admin → Sản phẩm → Thêm sản phẩm hoặc biểu tượng sửa: tên, SKU, slug, giá bán/vốn, danh mục, thương hiệu, mô tả, thông số, trạng thái, danh sách URL ảnh. Ảnh đầu tiên là ảnh chính. Đây là quản lý ảnh bằng URL, chưa có lưu trữ file upload.
- Tồn kho sản phẩm mới được nhập riêng tại mục Kho hàng.
- Giá vốn chỉ có tại `GET /api/v1/products/{id}/management` dành cho Staff/Admin; API sản phẩm công khai không trả giá vốn.

## Kiểm thử

MySQL phải đang chạy. Cấu hình `TEST_DB_USERNAME` và `TEST_DB_PASSWORD` riêng. Profile test luôn dùng database **techstore_test**, không lấy `DB_NAME` của dev.

```powershell
$env:JAVA_HOME = 'C:/path/to/jdk-21'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-backend.ps1
node scripts/test-frontend.mjs
```

Script tạo và nạp fixture vào `techstore_test` nếu database chưa tồn tại. Nếu đã tồn tại, script giữ nguyên dữ liệu. Các test tích hợp hiện dựa vào ID và tài khoản của seed; không dùng database này làm môi trường thao tác hằng ngày. Phần lớn test rollback; test đồng thời tạo fixture riêng và dọn trong `finally`. Khi test DB đã được chuẩn bị, có thể chạy `backend/mvnw.cmd test` từ thư mục `backend/`.

## Đổi môi trường triển khai

Backend dùng profile `prod` qua `SPRING_PROFILES_ACTIVE=prod`, lấy credentials từ môi trường và chỉ validate schema. Cấu hình database/schema trước khi chạy.

Frontend đọc thẻ sau trong `<head>` của từng trang nếu cần API khác cổng/host:

```html
<meta name="api-base-url" content="https://api.example.com/api/v1">
```

Nếu không có, frontend dùng giao thức và hostname hiện tại với cổng 8080. CORS hiện cho phép các origin localhost; khi triển khai tên miền thật cần cấu hình danh sách origin tương ứng trong `CorsConfig`.

