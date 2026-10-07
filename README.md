# ⚡ TechStore — Hệ Thống Thương Mại Điện Tử Thiết Bị Công Nghệ

Hệ thống bán lẻ thiết bị công nghệ đa nền tảng hiện đại bao gồm **Backend Spring Boot 3 REST API**, **Ứng dụng di động Flutter (Android / iOS / Web / Windows)** và **Website bán hàng & Quản trị (HTML/Bootstrap 5/ES Modules)**.

---

## 🌟 Điểm Nổi Bật & Công Nghệ

| Thành phần | Công nghệ chính | Tính năng nổi bật |
| :--- | :--- | :--- |
| **Backend REST API** | Java 21, Spring Boot 3.4.3, Spring Data JPA, Spring Security, JWT, BCrypt, Spring Mail | Tối ưu truy vấn N+1 (EntityGraph, Bulk Batching), phân quyền Role-based, xác thực OTP qua Gmail, tích hợp Gemini AI, Cloudinary upload ảnh |
| **Mobile App** | Flutter 3.x, Dart, Provider, Material 3 | Đa nền tảng (Android/iOS/Web/Windows), xác thực Google & OTP, giỏ hàng, đặt hàng, quản lý đơn hàng vuốt tab mượt mà, mua lại sản phẩm, trợ lý AI tư vấn |
| **Web Frontend** | HTML5, CSS3, Vanilla JS ES Modules, Bootstrap 5, Chart.js | Không cần build tool phức tạp, giao diện khách hàng và Dashboard Admin trực quan với biểu đồ doanh thu |
| **Cơ sở dữ liệu** | MySQL 8 (Aiven Cloud Database / Local) | Thiết kế chuẩn hóa quan hệ (3NF), khóa bi quan/lạc quan tránh race-condition tồn kho & coupon |
| **Triển khai Cloud** | Render (Web Service), UptimeRobot | Backend đã được deploy tự động trên Render, giám sát liveness 24/7 với UptimeRobot |

---

## 📱 Tính Năng Chính Của Ứng Dụng

### 1. Phía Khách Hàng (Customer)
- **Xác thực an toàn:** Đăng ký / Đăng nhập bằng JWT, đăng nhập Google, kích hoạt tài khoản và lấy lại mật khẩu qua mã OTP gửi về Email.
- **Khám phá sản phẩm:** Danh mục đa dạng, lọc theo giá/thương hiệu/danh mục, tìm kiếm nhanh không độ trễ, xem chi tiết thông số kỹ thuật và hình ảnh.
- **Trợ lý mua sắm AI:** Tích hợp Google Gemini AI hỗ trợ tư vấn cấu hình, so sánh và gợi ý sản phẩm phù hợp ngân sách.
- **Giỏ hàng & Thanh toán:** Thêm/sửa/xóa sản phẩm, áp dụng mã giảm giá (Coupon), chọn chi nhánh nhận hàng, hỗ trợ thanh toán COD và chuyển khoản giả lập (ONLINE_MOCK).
- **Quản lý đơn mua:** Xem danh sách đơn hàng hỗ trợ thao tác vuốt qua lại giữa các tab trạng thái (*Tất cả, Chờ xử lý, Đã xác nhận, Đang giao, Hoàn tất, Đổi trả, Đã hủy*), xem chi tiết hóa đơn, bấm vào món hàng để xem lại sản phẩm, tính năng **Mua lại nhanh** cho các sản phẩm đã mua trước đó.
- **Hồ sơ cá nhân:** Quản lý thông tin, sổ địa chỉ nhận hàng, danh sách yêu thích (Wishlist).

### 2. Phía Quản Trị (Admin & Nhân Viên)
- **Dashboard tổng quan:** Biểu đồ thống kê doanh thu, đơn hàng mới, sản phẩm bán chạy.
- **Quản lý sản phẩm & Kho:** Thêm/sửa sản phẩm, upload ảnh Cloudinary, quản lý tồn kho theo từng chi nhánh, quản lý giá vốn & giá bán.
- **Quản lý đơn hàng:** Tiếp nhận, duyệt đơn, chuyển trạng thái giao hàng, xử lý hoàn hủy và tự động hoàn trả tồn kho.
- **Quản lý khuyến mãi & Banner:** Tạo và quản lý mã giảm giá (Coupon), quản lý banner quảng cáo hiển thị trên trang chủ.
- **Quản lý người dùng:** Phân quyền khách hàng, nhân viên và quản trị viên.

---

## 📂 Cấu Trúc Thư Mục Dự Án

```text
techstore/
├── backend/                       # Backend Spring Boot 3
│   ├── src/main/java/com/techstore/
│   │   ├── config/                # Cấu hình Security, CORS, Cloudinary, Gemini AI
│   │   ├── controller/            # REST API Controllers (/api/v1/...)
│   │   ├── dto/                   # Request / Response DTOs
│   │   ├── entity/                # JPA Entities & Table Mappings
│   │   ├── repository/            # Spring Data JPA Repositories
│   │   ├── service/               # Business Logic & Implementations
│   │   └── specification/         # Dynamic search & filter queries
│   └── pom.xml
├── techapp/                       # Ứng dụng di động Flutter
│   ├── lib/
│   │   ├── config/                # API Config (Render Production & Localhost)
│   │   ├── models/                # Data Models
│   │   ├── providers/             # State Management (Auth, Cart, Product, Order)
│   │   ├── screens/               # Màn hình (Home, Auth, Order, Product, Admin...)
│   │   ├── services/              # API Client HTTP Services
│   │   └── widgets/               # Reusable Widgets & UI Components
│   ├── assets/                    # Icons, hình ảnh & fonts
│   └── pubspec.yaml
├── frontend/                      # Web bán hàng & Admin HTML/JS
│   ├── js/                        # ES Modules (API clients, components, auth)
│   ├── pages/                     # Giao diện khách hàng và Admin
│   └── css/                       # Stylesheets
├── database/                      # Cơ sở dữ liệu
│   ├── schema.sql                 # Cấu trúc bảng MySQL
│   └── seed.sql                   # Dữ liệu mẫu ban đầu
├── scripts/                       # Scripts khởi động và kiểm thử tự động
└── README.md
```

---

## 🚀 Hướng Dẫn Khởi Chạy

### Cách 1: Chạy App Flutter (Đã kết nối sẵn Cloud Backend Render)

Ứng dụng Flutter đã được cấu hình mặc định kết nối trực tiếp đến Backend Cloud trên **Render** (`https://techstore-backend-aa7t.onrender.com/api/v1`), do đó bạn **không cần cài đặt Java hay MySQL** trên máy để test app.

1. **Clone repository về máy:**
   ```bash
   git clone https://github.com/DuyPhan11/techstore-app.git
   cd techstore-app/techapp
   ```

2. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng:**
   - Mở máy ảo Android Emulator hoặc cắm điện thoại thật vào máy tính.
   - Chạy lệnh:
     ```bash
     flutter run
     ```

4. **Build file APK cài trực tiếp vào điện thoại Android:**
   ```bash
   flutter build apk --release
   ```
   *File cài đặt sẽ nằm tại: `techapp/build/app/outputs/flutter-apk/app-release.apk`.*

---

### Cách 2: Chạy Toàn Bộ Hệ Thống Cục Bộ (Localhost)

#### Yêu Cầu Môi Trường
- **Java:** JDK 21 trở lên
- **Node.js:** v18+ và npm
- **Database:** MySQL 8.x
- **Flutter SDK:** 3.x+ (nếu chạy mobile app)

#### 1. Cấu hình Cơ sở dữ liệu MySQL
Tạo database và nạp dữ liệu mẫu:
```sql
CREATE DATABASE techstore_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE techstore_db;
SOURCE database/schema.sql;
SOURCE database/seed.sql;
```

#### 2. Cấu hình Biến Môi Trường Backend
Tạo file `.env` tại thư mục gốc của dự án (hoặc thư mục `backend/`) với nội dung:
```properties
# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=techstore_db
DB_USERNAME=root
DB_PASSWORD=mat_khau_mysql_cua_ban

# Server & Security
PORT=8080
JWT_SECRET=your_super_secret_key_at_least_256_bits_long_for_hmac_sha256
FRONTEND_URL=http://localhost:5500

# Gmail SMTP (Gửi mã OTP qua email)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_FROM=TechStore <your_email@gmail.com>
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_google_app_password
MAIL_SMTP_AUTH=true
MAIL_STARTTLS=true

# Tùy chọn: Cloudinary & AI
GEMINI_API_KEY=your_gemini_api_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
```

#### 3. Khởi chạy Backend
```bash
cd backend
./mvnw spring-boot:run
```
*Backend sẽ chạy tại `http://localhost:8080` (Kiểm tra sức khỏe hệ thống: `http://localhost:8080/api/v1/health`).*

#### 4. Khởi chạy Web Frontend
Mở một cửa sổ dòng lệnh khác tại thư mục gốc:
```bash
npx serve -l 5500 frontend
```
*Truy cập website tại: `http://localhost:5500`.*

#### 5. Chuyển Flutter App về Local Backend (Nếu muốn)
Trong file `techapp/lib/config/api_config.dart`, chuyển:
```dart
static const bool useLocalBackend = true;
```

---

## 🔑 Tài Khoản Thử Nghiệm

Dữ liệu mẫu (`seed.sql`) cung cấp sẵn các tài khoản demo sau (mật khẩu chung: `password123`):

| Vai trò | Email đăng nhập | Mật khẩu | Quyền hạn |
| :--- | :--- | :--- | :--- |
| **Quản trị viên (Admin)** | `admin@techstore.com` | `password123` | Toàn quyền quản trị hệ thống, nhân viên, sản phẩm, doanh thu |
| **Nhân viên (Staff)** | `staff@techstore.com` | `password123` | Xử lý đơn hàng, quản lý kho hàng và danh mục sản phẩm |
| **Khách hàng 1 (Customer)** | `customer1@gmail.com` | `password123` | Mua hàng, xem đơn hàng, đánh giá sản phẩm |
| **Khách hàng 2 (Customer)** | `customer2@gmail.com` | `password123` | Khách hàng trải nghiệm mua sắm |

---

## 🔒 Quy Chuẩn Bảo Mật

- **Mật khẩu:** Mã hóa 1 chiều bằng thuật toán BCrypt.
- **Xác thực:** JSON Web Token (JWT) có chữ ký HMAC-SHA256, hạn sử dụng và cơ chế thu hồi.
- **Khóa dữ liệu:** Sử dụng kỹ thuật bi quan (`PESSIMISTIC_WRITE`) khi thanh toán đơn hàng để triệt tiêu tình trạng mua vượt tồn kho (overselling) và dùng quá số lần voucher.
- **Biến môi trường:** Tuyệt đối không commit file `.env` chứa mật khẩu hoặc API Key bí mật lên kho mã nguồn.

---

## 👥 Tác Giả & Đóng Góp

- Dự án được phát triển và duy trì bởi **TechStore Team**.
- Mọi góp ý hoặc báo lỗi vui lòng mở **Issue** hoặc tạo **Pull Request** trên repository.
