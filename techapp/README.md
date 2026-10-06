# TechStore Mobile App (Flutter)

Ứng dụng thương mại điện tử di động bán thiết bị công nghệ TechStore, được xây dựng bằng **Flutter**, kết nối trực tiếp với backend **Spring Boot 3.x REST API** có sẵn trong dự án.

---

## 📱 Tính Năng Đã Xây Dựng

1. **Xác thực & Người dùng (Authentication):**
   - Đăng ký tài khoản mới (`/api/v1/auth/register`)
   - Đăng nhập JWT (`/api/v1/auth/login`) với tính năng ghi nhớ phiên qua `SharedPreferences`
   - Gợi ý tài khoản mẫu (Customer, Admin) để kiểm thử nhanh
   - Xem thông tin tài khoản, vai trò và đăng xuất.

2. **Trang Chủ (Home Screen):**
   - Diagnostic status bar: Hiển thị trạng thái kết nối Backend Online/Offline realtime (`/api/v1/health`)
   - Hero banner khuyến mãi phong cách công nghệ
   - Danh mục sản phẩm nổi bật (Điện thoại, Laptop, Tablet, Phụ kiện...)
   - Danh sách thương hiệu (Apple, Samsung, Asus, Dell...)
   - Danh sách sản phẩm mới nhất & nút thêm nhanh vào giỏ.

3. **Danh Sách Sản Phẩm & Bộ Lọc (Catalog):**
   - Tìm kiếm từ khóa sản phẩm với thanh Search
   - Modal bộ lọc đa năng: lọc theo Danh mục, Thương hiệu, Khoảng giá (Min - Max)
   - Sắp xếp linh hoạt: Mới nhất, Giá tăng dần, Giá giảm dần, Tên A-Z
   - Phân trang dạng lưới 2 cột mượt mà.

4. **Chi Tiết Sản Phẩm (Product Detail):**
   - Thư viện hình ảnh với ảnh chính và thumbnails
   - Tình trạng tồn kho, mã SKU, thương hiệu, giá bán chuẩn VNĐ (`₫`)
   - Mô tả chi tiết và bảng thông số kỹ thuật (Specifications)
   - Bộ chọn số lượng (+/-)
   - Nút **Thêm vào giỏ** & **Mua ngay**
   - Đánh giá sản phẩm (Reviews): điểm trung bình, danh sách bình luận và form gửi đánh giá khi đã mua hàng.

5. **Giỏ Hàng (Shopping Cart):**
   - Xem danh sách sản phẩm trong giỏ, huy hiệu số lượng trên icon giỏ hàng
   - Tăng/giảm số lượng trực tiếp
   - Xóa từng món hoặc xóa toàn bộ giỏ
   - Tóm tắt tổng tiền.

6. **Thanh Toán & Đặt Hàng (Checkout):**
   - Nhập thông tin người nhận: Họ tên, Số điện thoại, Địa chỉ nhận hàng
   - Chọn Chi nhánh kho phục vụ (`/api/v1/branches`)
   - Kiểm tra và áp dụng Mã giảm giá / Voucher khuyến mãi realtime (`/api/v1/checkout/validate-coupon`)
   - Chọn phương thức thanh toán: COD (Tiền mặt khi nhận hàng) hoặc Chuyển khoản giả lập (ONLINE_MOCK)
   - Màn hình đặt hàng thành công (`OrderSuccessScreen`) với mã đơn hàng.

7. **Quản Lý Đơn Hàng (Orders):**
   - Quản lý đơn mua theo các tab: Tất cả, Chờ xử lý, Đang giao, Hoàn tất, Đã hủy
   - Xem chi tiết đơn: Thông tin nhận hàng, chi nhánh, phương thức thanh toán, chi tiết từng món
   - Chức năng **Hủy đơn hàng** kèm nhập lý do khi đơn đang ở trạng thái chờ xác nhận.

8. **Cấu Hình API Linh Hoạt (Dynamic API Config):**
   - Tự động nhận diện nền tảng:
     - Android Emulator: `http://10.0.2.2:8080/api/v1`
     - Windows App / Web / iOS: `http://localhost:8080/api/v1`
   - Cho phép đổi URL API trực tiếp trong mục **Tài khoản** -> **Cấu hình API Backend** khi test trên điện thoại thật qua mạng WiFi nội bộ (ví dụ: `http://172.16.30.111:8080/api/v1`).

---

## 🛠️ Cấu Trúc Thư Mục

```
techapp/lib/
├── config/
│   ├── api_config.dart          # Base URL & Endpoints
│   ├── app_colors.dart          # Bảng màu chuẩn TechStore Web (#0D6EFD...)
│   └── app_theme.dart           # ThemeData Material 3
├── models/
│   ├── brand_model.dart
│   ├── branch_model.dart
│   ├── cart_model.dart
│   ├── category_model.dart
│   ├── coupon_model.dart
│   ├── order_model.dart
│   ├── product_model.dart
│   ├── review_model.dart
│   └── user_model.dart
├── providers/
│   ├── auth_provider.dart       # Quản lý phiên đăng nhập và token
│   ├── cart_provider.dart       # Quản lý giỏ hàng và số lượng
│   └── product_provider.dart    # Quản lý catalog, filter, search
├── services/
│   ├── api_service.dart         # HTTP Client tập trung, auto bearer token
│   ├── auth_service.dart
│   ├── cart_service.dart
│   ├── checkout_service.dart
│   ├── order_service.dart
│   ├── product_service.dart
│   └── review_service.dart
├── utils/
│   ├── currency_format.dart     # Định dạng tiền tệ VNĐ và ngày tháng
│   └── toast_helper.dart        # Thông báo SnackBar
├── widgets/
│   ├── empty_state.dart         # View trạng thái rỗng
│   ├── product_card.dart        # Card hiển thị sản phẩm
│   └── quantity_selector.dart   # Bộ chọn tăng giảm số lượng
└── screens/
    ├── auth/                    # Login, Register
    ├── cart/                    # CartScreen
    ├── checkout/                # CheckoutScreen, OrderSuccessScreen
    ├── home/                    # HomeScreen
    ├── order/                   # MyOrdersScreen, OrderDetailScreen
    ├── product/                 # ProductListScreen, ProductDetailScreen
    ├── profile/                 # ProfileScreen
    └── main_navigation_screen.dart # Thanh điều hướng BottomNavigationBar
```

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

### Bước 1: Khởi động Backend Spring Boot
Từ thư mục gốc dự án:
```cmd
start-backend.bat
```
Hoặc:
```cmd
cd backend
mvn spring-boot:run
```

### Bước 2: Chạy Ứng Dụng Flutter
Chuyển vào thư mục `techapp`:
```cmd
cd techapp
```

- Chạy trên **Windows**:
  ```cmd
  flutter run -d windows
  ```
- Chạy trên **Android Emulator**:
  ```cmd
  flutter run -d emulator-5554
  ```
- Chạy trên **Trình duyệt Chrome (Web)**:
  ```cmd
  flutter run -d chrome
  ```
- Chạy trên **Thiết bị thật qua WiFi**:
  Khởi động app, vào tab **Tài khoản** -> **Cấu hình API Backend**, nhập IP máy tính của bạn (ví dụ: `http://172.16.30.111:8080/api/v1`).
