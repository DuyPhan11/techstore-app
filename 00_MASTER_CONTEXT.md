# MASTER PROMPT — AI AGENT VIBE CODING WEBSITE BÁN THIẾT BỊ CÔNG NGHỆ

> Mục tiêu: dùng file này làm "luật dự án" cho AI Agent/Coding Agent (Cursor, Windsurf, Claude Code, Copilot Agent, Cline, Roo Code, Gemini Code Assist...) để xây dựng website bán thiết bị công nghệ theo yêu cầu đồ án.
>
> **Cách dùng:** Không nên đưa toàn bộ task lớn cho Agent trong một lần. Hãy dùng `00_MASTER_CONTEXT.md` làm context cố định, sau đó lần lượt gửi các prompt ở phần `PHASE PROMPTS`.

---

# 1. VAI TRÒ CỦA AI AGENT

Bạn là Senior Full-Stack Developer + Software Architect.

Nhiệm vụ của bạn là hỗ trợ xây dựng một website thương mại điện tử bán thiết bị công nghệ gồm:

- Điện thoại
- Laptop
- Tablet
- Phụ kiện
- Danh mục sản phẩm
- Thương hiệu
- Chi nhánh/kho
- Giỏ hàng
- Đặt hàng
- Thanh toán giả lập/sandbox
- Khuyến mãi
- Đánh giá sản phẩm
- Quản lý người dùng
- Quản lý nhân viên
- Quản trị hệ thống
- Dashboard/thống kê doanh thu

Đây là dự án học tập nhưng code phải được tổ chức theo hướng thực tế, dễ mở rộng, dễ debug và dễ trình bày với giảng viên.

---

# 2. STACK CÔNG NGHỆ — KHÔNG TỰ Ý ĐỔI

## Backend

- Java 21
- Spring Boot 3.x
- Spring Web / Spring MVC
- Spring Data JPA
- Hibernate
- Spring Security
- JWT Authentication
- Bean Validation / Jakarta Validation
- MySQL 8.x
- Maven
- Lombok
- Jackson
- BCrypt
- SLF4J + Logback
- JUnit 5
- Mockito
- MockMvc

## Frontend

Không dùng React, Vue, Angular hoặc TypeScript.

Sử dụng thống nhất:

- HTML5
- CSS3
- JavaScript ES6+
- JavaScript Modules (`type="module"`)
- Fetch API
- LocalStorage chỉ cho dữ liệu client phù hợp, không lưu mật khẩu
- Responsive Design
- Có thể dùng Bootstrap 5 nếu cần UI nhanh, nhưng không được trộn thêm framework frontend khác.
- Có thể dùng Chart.js cho dashboard thống kê.

## Database

- MySQL 8.x
- Charset: `utf8mb4`
- Engine: InnoDB
- Foreign Key
- Transaction
- Index cho các trường thường xuyên tìm kiếm/lọc
- Không lưu mật khẩu plaintext.

## API

Backend cung cấp REST API JSON.

Frontend chỉ giao tiếp với backend thông qua HTTP/REST API.

Không viết SQL trực tiếp trong JavaScript.

Không để frontend truy cập database.

---

# 3. NGUYÊN TẮC KIẾN TRÚC

Sử dụng kiến trúc:

Frontend
    ↓
REST API
    ↓
Controller
    ↓
Service
    ↓
Repository
    ↓
JPA/Hibernate
    ↓
MySQL

Backend:

Controller
→ nhận request, validate input cơ bản, trả HTTP response.

Service
→ xử lý business logic.

Repository
→ truy cập database.

Entity
→ ánh xạ database.

DTO
→ request/response API.

Mapper
→ chuyển Entity ↔ DTO.

Security
→ authentication + authorization.

Exception
→ xử lý lỗi tập trung.

Config
→ cấu hình hệ thống.

Không đặt business logic phức tạp trong Controller.

Không trả Entity trực tiếp ra API nếu có thể tránh.

Không để frontend phụ thuộc vào cấu trúc database.

---

# 4. CẤU TRÚC PROJECT CHUẨN

Dùng monorepo:

```text
tech-store/
│
├── backend/
│   ├── pom.xml
│   ├── README.md
│   ├── .env.example
│   │
│   └── src/
│       ├── main/
│       │   ├── java/com/techstore/
│       │   │   ├── TechStoreApplication.java
│       │   │   │
│       │   │   ├── config/
│       │   │   │   ├── SecurityConfig.java
│       │   │   │   ├── CorsConfig.java
│       │   │   │   ├── JacksonConfig.java
│       │   │   │   └── DataInitializer.java
│       │   │   │
│       │   │   ├── security/
│       │   │   │   ├── JwtService.java
│       │   │   │   ├── JwtAuthenticationFilter.java
│       │   │   │   ├── CustomUserDetailsService.java
│       │   │   │   └── SecurityConstants.java
│       │   │   │
│       │   │   ├── common/
│       │   │   │   ├── exception/
│       │   │   │   ├── response/
│       │   │   │   ├── validation/
│       │   │   │   └── util/
│       │   │   │
│       │   │   ├── auth/
│       │   │   │   ├── controller/
│       │   │   │   ├── dto/
│       │   │   │   └── service/
│       │   │   │
│       │   │   ├── user/
│       │   │   │   ├── controller/
│       │   │   │   ├── dto/
│       │   │   │   ├── entity/
│       │   │   │   ├── repository/
│       │   │   │   └── service/
│       │   │   │
│       │   │   ├── product/
│       │   │   │   ├── controller/
│       │   │   │   ├── dto/
│       │   │   │   ├── entity/
│       │   │   │   ├── repository/
│       │   │   │   └── service/
│       │   │   │
│       │   │   ├── category/
│       │   │   ├── brand/
│       │   │   ├── branch/
│       │   │   ├── inventory/
│       │   │   ├── cart/
│       │   │   ├── order/
│       │   │   ├── payment/
│       │   │   ├── promotion/
│       │   │   ├── review/
│       │   │   ├── dashboard/
│       │   │   └── file/
│       │   │
│       │   └── resources/
│       │       ├── application.properties
│       │       ├── application-dev.properties
│       │       ├── application-test.properties
│       │       ├── application-prod.properties
│       │       └── db/
│       │           └── migration/
│       │
│       └── test/
│           └── java/com/techstore/
│
├── frontend/
│   ├── index.html
│   │
│   ├── pages/
│   │   ├── auth/
│   │   ├── products/
│   │   ├── cart/
│   │   ├── checkout/
│   │   ├── orders/
│   │   ├── account/
│   │   └── admin/
│   │
│   ├── assets/
│   │   ├── images/
│   │   └── icons/
│   │
│   ├── css/
│   │   ├── reset.css
│   │   ├── variables.css
│   │   ├── global.css
│   │   ├── components.css
│   │   ├── responsive.css
│   │   └── pages/
│   │
│   └── js/
│       ├── config.js
│       ├── api/
│       │   ├── api-client.js
│       │   ├── auth-api.js
│       │   ├── product-api.js
│       │   ├── cart-api.js
│       │   ├── order-api.js
│       │   ├── review-api.js
│       │   ├── promotion-api.js
│       │   ├── admin-api.js
│       │   └── dashboard-api.js
│       │
│       ├── auth/
│       │   ├── auth.js
│       │   └── guard.js
│       │
│       ├── components/
│       │   ├── navbar.js
│       │   ├── footer.js
│       │   ├── product-card.js
│       │   ├── modal.js
│       │   ├── toast.js
│       │   └── pagination.js
│       │
│       ├── pages/
│       │   ├── home.js
│       │   ├── product-list.js
│       │   ├── product-detail.js
│       │   ├── cart.js
│       │   ├── checkout.js
│       │   ├── orders.js
│       │   ├── account.js
│       │   └── admin/
│       │
│       └── utils/
│           ├── formatter.js
│           ├── validator.js
│           ├── storage.js
│           └── constants.js
│
├── database/
│   ├── schema.sql
│   ├── seed.sql
│   └── README.md
│
├── docs/
│   ├── architecture.md
│   ├── api-spec.md
│   ├── database.md
│   ├── setup.md
│   └── development-log.md
│
├── .gitignore
├── README.md
└── docker-compose.yml
```

---

# 5. QUY TẮC CODE BẮT BUỘC

## 5.1 Backend

- Java package: `com.techstore`
- Class name PascalCase.
- Method/variable camelCase.
- Constant UPPER_SNAKE_CASE.
- Dùng `BigDecimal` cho tiền.
- Dùng enum cho role/status/type có tập giá trị cố định.
- Không dùng `double` cho tiền.
- Dùng DTO cho API.
- Dùng `@Valid`.
- Dùng `@Transactional` cho các nghiệp vụ cần tính toàn vẹn.
- Không expose password.
- Password phải BCrypt.
- Không hard-code secret JWT.
- Không hard-code database password.
- Có Global Exception Handler.
- API phải trả HTTP status phù hợp.
- Không catch Exception vô nghĩa.
- Không dùng `System.out.println` cho logging production code.

## 5.2 Frontend

- JavaScript ES6+.
- Tách API call khỏi UI logic.
- Không viết toàn bộ JavaScript vào HTML.
- Không viết CSS hàng trăm dòng trực tiếp trong HTML.
- Không duplicate code nếu có thể tạo component/util.
- API URL lấy từ `config.js`.
- Hiển thị loading/error/empty state.
- Validate form phía frontend nhưng backend vẫn phải validate lại.
- Không lưu password vào LocalStorage.
- Token phải được xử lý tập trung.

## 5.3 Database

- Tên bảng snake_case.
- Primary key dùng BIGINT.
- Foreign key rõ ràng.
- Có created_at / updated_at cho các bảng phù hợp.
- Có index cho email, phone, product name, SKU/code và các trường filter phổ biến.
- Không xóa dữ liệu nghiệp vụ quan trọng một cách tùy tiện; ưu tiên soft delete khi phù hợp.

---

# 6. ACTOR VÀ PHÂN QUYỀN

## Guest

Được:

- Xem trang chủ
- Tìm kiếm sản phẩm
- Lọc sản phẩm
- Xem chi tiết sản phẩm
- Đăng ký
- Đăng nhập

## Customer

Được:

- Tất cả chức năng Guest
- Quản lý hồ sơ
- Quản lý địa chỉ
- Giỏ hàng
- Đặt hàng
- Thanh toán
- Áp dụng coupon
- Xem lịch sử đơn hàng
- Hủy đơn khi còn trạng thái cho phép
- Đánh giá sản phẩm đã mua

## Staff

Được:

- Quản lý sản phẩm
- Quản lý danh mục
- Quản lý thương hiệu
- Quản lý khuyến mãi
- Quản lý đơn hàng
- Cập nhật trạng thái đơn hàng

## Admin

Được:

- Toàn bộ quyền Staff
- Quản lý Customer
- Quản lý Staff
- Khóa/mở khóa tài khoản
- Dashboard
- Thống kê doanh thu

---

# 7. YÊU CẦU CHỨC NĂNG PHẢI IMPLEMENT

## Authentication

- FR01 Đăng ký
- FR02 Đăng nhập
- FR03 Quên/khôi phục mật khẩu
- FR04 Quản lý thông tin cá nhân
- FR05 Quản lý địa chỉ
- FR06 RBAC
- FR07 Khóa/mở khóa tài khoản

## Catalog

- FR08 Category CRUD
- FR09 Brand CRUD
- FR10 Branch/Warehouse CRUD
- Theo dõi tồn kho theo branch

## Product

- FR11 Tạo sản phẩm
- FR12 Cập nhật sản phẩm
- FR13 Ẩn/xóa sản phẩm
- FR14 Nhiều ảnh/sản phẩm
- FR15 Search
- FR16 Filter
- FR17 Product detail

## Cart / Order / Payment

- FR18 Add cart
- FR19 Update/delete cart
- FR20 Checkout/create order
- FR21 Coupon
- FR22 COD + online payment giả lập/sandbox
- FR23 Order history
- FR24 Cancel order

## Review

- FR25 Create review
- FR26 View review

## Promotion

- FR27 Create coupon
- FR28 Update/disable coupon

## Order Admin

- FR29 List/filter orders
- FR30 Update order status

## User/Staff Admin

- FR31 Manage users
- FR32 Manage staff

## Dashboard

- FR33 Revenue statistics
- FR34 Dashboard overview

---

# 8. CÁC USE CASE

Phải giữ logic nghiệp vụ tương ứng:

- UC01 – Đăng ký
- UC02 – Đăng nhập
- UC03 – Khôi phục mật khẩu
- UC04 – Tìm kiếm và lọc sản phẩm
- UC05 – Xem chi tiết sản phẩm
- UC06 – Quản lý giỏ hàng
- UC07 – Đặt hàng và thanh toán
- UC08 – Xem lịch sử và hủy đơn
- UC09 – Đánh giá, bình luận
- UC10 – Chỉnh sửa thông tin người dùng
- UC11 – Quản lý sản phẩm
- UC12 – Quản lý danh mục và thương hiệu
- UC13 – Quản lý khuyến mãi
- UC14 – Quản lý đơn hàng
- UC15 – Quản lý người dùng
- UC16 – Quản lý nhân viên
- UC17 – Xem thống kê doanh thu

---

# 9. QUY TẮC NGHIỆP VỤ QUAN TRỌNG

## Account

- Email hoặc số điện thoại đăng ký phải unique.
- Customer đăng ký mặc định role CUSTOMER.
- Password hash bằng BCrypt.
- Account bị khóa không được đăng nhập.

## Product

Product có tối thiểu:

- id
- name
- sku
- barcode/code nếu cần
- price
- costPrice
- description
- specifications
- category
- brand
- status
- images
- createdAt
- updatedAt

## Inventory

Tồn kho phải theo branch.

Khi checkout:

1. Kiểm tra tồn kho.
2. Tính tổng tiền.
3. Áp dụng coupon nếu hợp lệ.
4. Tạo order.
5. Tạo order items.
6. Trừ tồn kho.
7. Commit transaction.

Không được để xảy ra bán vượt tồn kho.

## Order Status

Có thể dùng:

```text
PENDING
CONFIRMED
SHIPPING
COMPLETED
CANCELLED
PAYMENT_PENDING
```

Không cho Customer hủy order đã SHIPPING hoặc COMPLETED.

Khi hủy order hợp lệ, hoàn tồn kho.

## Review

Chỉ Customer đã mua và order COMPLETED mới được review sản phẩm.

## Coupon

Coupon cần kiểm tra:

- tồn tại
- active
- thời gian hiệu lực
- điều kiện đơn hàng
- giới hạn giảm
- loại giảm %

hoặc số tiền cố định.

## Payment

Trong phạm vi đồ án:

- COD
- ONLINE_MOCK

Không cần tích hợp cổng thanh toán thật nếu chưa được yêu cầu.

---

# 10. API DESIGN

Prefix:

```text
/api/v1
```

Ví dụ:

```text
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password

GET    /api/v1/products
GET    /api/v1/products/{id}
POST   /api/v1/products
PUT    /api/v1/products/{id}
DELETE /api/v1/products/{id}

GET    /api/v1/categories
POST   /api/v1/categories
PUT    /api/v1/categories/{id}
DELETE /api/v1/categories/{id}

GET    /api/v1/brands
POST   /api/v1/brands
PUT    /api/v1/brands/{id}
DELETE /api/v1/brands/{id}

GET    /api/v1/cart
POST   /api/v1/cart/items
PUT    /api/v1/cart/items/{productId}
DELETE /api/v1/cart/items/{productId}

POST   /api/v1/orders
GET    /api/v1/orders/my
GET    /api/v1/orders/{id}
POST   /api/v1/orders/{id}/cancel

POST   /api/v1/reviews
GET    /api/v1/products/{productId}/reviews

GET    /api/v1/admin/orders
PUT    /api/v1/admin/orders/{id}/status

GET    /api/v1/admin/users
PUT    /api/v1/admin/users/{id}/status

GET    /api/v1/admin/staff
POST   /api/v1/admin/staff

GET    /api/v1/admin/dashboard
GET    /api/v1/admin/dashboard/revenue
```

Agent được phép điều chỉnh endpoint nếu cần, nhưng phải cập nhật `docs/api-spec.md` và frontend API layer tương ứng.

---

# 11. DATABASE GỢI Ý

Các bảng chính:

```text
users
roles
user_roles

addresses

categories
brands

products
product_images
product_specifications

branches
inventories

carts
cart_items

orders
order_items

payments

coupons
coupon_usages

reviews

password_reset_tokens

audit_logs
```

Không nhất thiết phải tạo mọi bảng ngay từ đầu.

Agent phải thiết kế quan hệ dựa trên yêu cầu nghiệp vụ trước khi code.

---

# 12. AUTHENTICATION

Sử dụng JWT.

Flow:

```text
Login
  ↓
Backend validate username/password
  ↓
BCrypt password check
  ↓
Generate JWT
  ↓
Frontend nhận token
  ↓
Frontend gửi:
Authorization: Bearer <token>
  ↓
JwtAuthenticationFilter
  ↓
Spring Security
  ↓
Controller
```

Không tạo session authentication nếu không có lý do rõ ràng.

JWT secret lấy từ environment variable.

---

# 13. RESPONSE FORMAT API

Nên thống nhất:

Success:

```json
{
  "success": true,
  "message": "Success",
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": "Email không hợp lệ"
  }
}
```

Không trả stack trace cho frontend.

---

# 14. FRONTEND ARCHITECTURE

Frontend dùng Vanilla JS nhưng phải có tổ chức rõ ràng.

Ví dụ:

```text
HTML
 ↓
Page JS
 ↓
API Module
 ↓
Fetch
 ↓
Spring Boot REST API
```

Ví dụ `product-list.js` không tự viết URL API lung tung.

Thay vào đó:

```javascript
import { getProducts } from "../api/product-api.js";
```

`product-api.js`:

```javascript
import { apiRequest } from "./api-client.js";

export function getProducts(params = {}) {
    return apiRequest("/products", {
        method: "GET",
        params
    });
}
```

---

# 15. FRONTEND PAGE MAP

## Public

```text
/
├── index.html
├── products.html
├── product-detail.html
├── login.html
└── register.html
```

## Customer

```text
customer/
├── profile.html
├── addresses.html
├── cart.html
├── checkout.html
├── orders.html
├── order-detail.html
└── reviews.html
```

## Admin

```text
admin/
├── dashboard.html
├── products.html
├── product-form.html
├── categories.html
├── brands.html
├── branches.html
├── inventory.html
├── orders.html
├── promotions.html
├── users.html
└── staff.html
```

---

# 16. UI/UX

Phong cách:

- Website bán thiết bị công nghệ hiện đại.
- Responsive.
- Desktop-first nhưng mobile phải sử dụng được.
- Navbar.
- Search bar.
- Product cards.
- Product detail.
- Cart.
- Checkout.
- Admin sidebar.
- Dashboard cards.
- Tables.
- Modal.
- Toast notification.
- Loading state.
- Empty state.
- Error state.

Không cần làm UI quá cầu kỳ nếu ảnh hưởng tiến độ chức năng.

Ưu tiên:

1. Đúng nghiệp vụ.
2. API chạy đúng.
3. Database đúng.
4. Authentication đúng.
5. UI rõ ràng.
6. Sau cùng mới polish giao diện.

---

# 17. SECURITY

Bắt buộc:

- BCrypt.
- JWT.
- RBAC.
- Validate input.
- CORS cấu hình đúng.
- Không SQL Injection.
- Không expose password.
- Không trả sensitive information.
- Không tin dữ liệu từ frontend.
- Backend phải tự kiểm tra quyền.
- Customer chỉ xem/sửa dữ liệu của chính mình.
- Staff/Admin mới được truy cập API quản trị tương ứng.
- Admin-only endpoint phải có role ADMIN.
- Không cho frontend quyết định quyền bằng cách chỉ ẩn button.

---

# 18. TRANSACTION / CONCURRENCY

Các nghiệp vụ cần transaction:

```text
Checkout
Cancel Order
Update Inventory
Payment confirmation
```

Ví dụ checkout:

```text
BEGIN TRANSACTION

Check product stock
↓
Validate coupon
↓
Calculate total
↓
Create order
↓
Create order items
↓
Decrease inventory
↓
Create payment

COMMIT
```

Nếu một bước lỗi:

```text
ROLLBACK
```

Mục tiêu: không tạo order thành công nhưng không trừ kho, hoặc ngược lại.

---

# 19. ERROR HANDLING

Dùng:

```java
@RestControllerAdvice
```

Có các exception phù hợp:

```text
ResourceNotFoundException
BadRequestException
UnauthorizedException
ForbiddenException
ConflictException
InsufficientStockException
InvalidCouponException
```

HTTP status:

```text
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
500 Internal Server Error
```

---

# 20. TEST

Backend tối thiểu cần test:

- Authentication
- Product service
- Cart service
- Checkout
- Coupon
- Inventory
- Order cancellation
- Role authorization

Ưu tiên test nghiệp vụ quan trọng.

Ví dụ:

```text
Customer checkout khi đủ stock → success

Customer checkout khi thiếu stock → fail

Customer hủy order PENDING → success

Customer hủy order SHIPPING → fail

Customer review sản phẩm chưa mua → fail

Admin truy cập dashboard → success

Customer truy cập admin dashboard → 403
```

---

# 21. SEED DATA

Tạo dữ liệu mẫu để demo:

Roles:

```text
CUSTOMER
STAFF
ADMIN
```

Tạo:

- 1 Admin
- 1 Staff
- 2–3 Customer
- Categories
- Brands
- Products
- Branches
- Inventory
- Coupons
- Orders
- Reviews

Password demo chỉ dùng cho môi trường local/dev và phải ghi rõ trong README.

---

# 22. ENVIRONMENT

Không commit secret.

Ví dụ:

```text
DB_URL=
DB_USERNAME=
DB_PASSWORD=
JWT_SECRET=
```

`.env.example` chỉ chứa placeholder.

---

# 23. GIT

Commit theo chức năng:

```text
feat(auth): implement registration
feat(auth): implement login with jwt
feat(product): implement product crud
feat(cart): implement cart management
feat(order): implement checkout
feat(admin): implement product management
fix(order): prevent overselling
refactor(product): extract product mapper
test(order): add checkout tests
```

Không commit:

```text
.idea/
target/
node_modules/
.env
*.log
```

---

# 24. QUY TẮC LÀM VIỆC CỦA AI AGENT

Đây là phần QUAN TRỌNG NHẤT.

## Trước khi code

AI phải:

1. Đọc `00_MASTER_CONTEXT.md`.
2. Đọc cấu trúc project hiện tại.
3. Kiểm tra code đã tồn tại.
4. Không tạo duplicate class/file.
5. Kiểm tra dependency hiện tại.
6. Kiểm tra API đã có.
7. Kiểm tra database hiện tại.
8. Xác định dependency của task.

Không được tự ý rewrite toàn bộ project.

## Khi code

Mỗi task phải:

1. Nói ngắn gọn mình sẽ thay đổi gì.
2. Liệt kê file sẽ tạo/sửa.
3. Code.
4. Kiểm tra compile.
5. Chạy test liên quan.
6. Nếu có lỗi, sửa lỗi.
7. Tóm tắt file đã thay đổi.
8. Nêu cách chạy/kiểm tra.

## Không được

- Tự ý đổi Spring Boot sang framework khác.
- Tự ý đổi MySQL sang MongoDB.
- Tự ý đổi Vanilla JS sang React/Vue.
- Tự ý đổi Java version.
- Tự ý thêm microservices.
- Tự ý thêm Docker nếu chưa cần.
- Tự ý thêm Redis nếu chưa có yêu cầu.
- Tự ý thêm payment gateway thật.
- Tự ý thay đổi business rule.
- Tự ý xóa code đang hoạt động.
- Tạo file duplicate.
- Tạo API không có lý do.
- Bỏ qua validation.
- Bỏ qua authorization.

Nếu thấy requirement mâu thuẫn, phải chỉ ra trước khi sửa.

---

# 25. DEFINITION OF DONE

Một feature chỉ được coi là hoàn thành khi:

```text
[ ] Backend compile
[ ] Database hoạt động
[ ] Entity đúng
[ ] Repository đúng
[ ] Service đúng
[ ] Controller đúng
[ ] DTO đúng
[ ] Validation đúng
[ ] Authorization đúng
[ ] API test được
[ ] Frontend gọi đúng API
[ ] Loading state
[ ] Error state
[ ] Success state
[ ] Responsive cơ bản
[ ] Không hard-code secret
[ ] Không duplicate code
[ ] README/docs cập nhật nếu cần
```

---

# 26. PHASE PLAN

Không code toàn bộ project một lần.

## Phase 0 — Project foundation

Mục tiêu:

- Tạo repo.
- Backend Spring Boot.
- Frontend HTML/CSS/JS.
- MySQL.
- Maven.
- CORS.
- Environment.
- README.
- Git.
- Basic API response.
- Global exception.

## Phase 1 — Database + Entity

Tạo:

- User
- Role
- Address
- Category
- Brand
- Product
- ProductImage
- Branch
- Inventory

Sau đó tạo database schema.

## Phase 2 — Authentication

Implement:

- Register
- Login
- JWT
- BCrypt
- Role
- Account lock
- Security config
- Frontend login/register

## Phase 3 — Product catalog

Implement:

- Product CRUD
- Category CRUD
- Brand CRUD
- Search
- Filter
- Product detail
- Images

## Phase 4 — Customer profile

Implement:

- Profile
- Change password
- Address CRUD
- Avatar

## Phase 5 — Cart

Implement:

- Add cart
- Update quantity
- Remove item
- Stock validation
- Cart total

## Phase 6 — Checkout

Implement:

- Address
- Coupon
- COD
- Mock online payment
- Order
- Order items
- Inventory transaction

## Phase 7 — Order management

Customer:

- Order history
- Order detail
- Cancel order

Staff/Admin:

- List orders
- Filter
- Update status

## Phase 8 — Review

Implement:

- Review
- Rating
- Review validation
- Product review list

## Phase 9 — Promotion

Implement:

- Coupon CRUD
- Validation
- Apply coupon

## Phase 10 — Admin

Implement:

- Users
- Staff
- Lock/unlock
- Product management
- Category
- Brand
- Branch
- Inventory
- Promotion
- Order

## Phase 11 — Dashboard

Implement:

- Total revenue
- Total orders
- Cancelled orders
- New customers
- Best-selling products
- Revenue by date
- Revenue by category
- Revenue by branch

## Phase 12 — Testing + polish

- Unit tests
- Integration tests
- API tests
- Security test
- UI polish
- Responsive
- Error handling
- README
- Demo data

---

# 27. PROMPT MỖI PHASE

## PROMPT 00 — PHÂN TÍCH PROJECT

```text
Đọc toàn bộ 00_MASTER_CONTEXT.md trước.

Chưa được code.

Hãy:
1. Phân tích yêu cầu.
2. Phân tích dependency giữa các module.
3. Đề xuất thứ tự implementation.
4. Kiểm tra các điểm có thể gây conflict.
5. Đề xuất database entity/relationship.
6. Đề xuất API architecture.
7. Đề xuất frontend page architecture.
8. Liệt kê milestone.

Không tự ý thay đổi technology stack.
Không code cho đến khi phân tích xong.
```

---

## PROMPT 01 — FOUNDATION

```text
Đọc 00_MASTER_CONTEXT.md.

Implement Phase 0 — Project Foundation.

Yêu cầu:
- Spring Boot 3.x
- Java 21
- Maven
- MySQL
- REST API
- Global exception handling
- CORS
- application-dev.properties
- application-test.properties
- application-prod.properties
- .env.example
- README
- frontend HTML/CSS/JS ES6 modules

Tạo cấu trúc thư mục chuẩn.

Sau khi code:
1. Chạy compile.
2. Kiểm tra backend startup.
3. Kiểm tra frontend mở được.
4. Báo cáo file đã tạo.
5. Báo cáo lỗi nếu có.
```

---

## PROMPT 02 — DATABASE

```text
Đọc 00_MASTER_CONTEXT.md.

Implement database foundation.

Thiết kế:
- users
- roles
- user_roles
- addresses
- categories
- brands
- products
- product_images
- branches
- inventories
- carts
- cart_items
- orders
- order_items
- payments
- coupons
- coupon_usages
- reviews
- password_reset_tokens
- audit_logs

Trước tiên hãy phân tích ERD.

Sau đó:
1. Tạo Entity.
2. Tạo enum.
3. Tạo Repository.
4. Tạo schema.sql hoặc migration.
5. Tạo seed data cơ bản.
6. Kiểm tra relationship.
7. Kiểm tra compile.

Không code business logic phức tạp ở phase này.
```

---

## PROMPT 03 — AUTH

```text
Implement authentication.

Features:
- Register
- Login
- JWT
- BCrypt
- Role CUSTOMER/STAFF/ADMIN
- Account active/locked
- Forgot password/reset password ở mức phù hợp với đồ án

Backend:
- DTO
- Service
- Controller
- Security
- JWT filter
- Validation
- Exception handling

Frontend:
- login.html
- register.html
- auth.js
- auth-api.js
- guard.js

Test:
- register success
- duplicate email/phone
- wrong password
- locked account
- role authorization
```

---

## PROMPT 04 — PRODUCT

```text
Implement Product Catalog.

Backend:
- Product CRUD
- Category CRUD
- Brand CRUD
- Product image
- Search
- Filter
- Pagination
- Sorting nếu cần

Frontend:
- products.html
- product-detail.html
- product-list.js
- product-detail.js
- product-api.js
- product-card.js

Yêu cầu:
- Guest được xem sản phẩm.
- Staff/Admin quản lý sản phẩm.
- Customer không được gọi API admin.
- Có loading/error/empty state.
```

---

## PROMPT 05 — CART

```text
Implement Cart.

Customer:
- Get cart
- Add product
- Update quantity
- Remove item
- Clear cart
- Calculate subtotal

Backend phải kiểm tra:
- Authentication
- Product tồn tại
- Product active
- Stock đủ

Frontend:
- cart.html
- cart.js
- cart-api.js

Không cho frontend tự quyết định stock.
```

---

## PROMPT 06 — CHECKOUT

```text
Implement checkout.

Flow:

Cart
→ Checkout
→ Address
→ Coupon
→ Payment method
→ Validate stock
→ Create order
→ Create order items
→ Decrease inventory
→ Create payment
→ Clear cart

Dùng transaction.

Hỗ trợ:
- COD
- ONLINE_MOCK

Test kỹ trường hợp:
- thiếu stock
- coupon hết hạn
- coupon không đủ điều kiện
- checkout thành công
- rollback khi lỗi
```

---

## PROMPT 07 — ORDER

```text
Implement Order Management.

Customer:
- My orders
- Order detail
- Cancel order

Staff/Admin:
- List orders
- Filter
- View detail
- Update status

Business rule:
- Customer chỉ được hủy order còn cho phép.
- Không hủy SHIPPING/COMPLETED.
- Cancel hợp lệ phải hoàn inventory.
- Không cho COMPLETED quay ngược trạng thái.

Frontend cần cập nhật UI theo status.
```

---

## PROMPT 08 — REVIEW

```text
Implement Review.

Rule:
- Login required.
- Customer phải đã mua sản phẩm.
- Order phải COMPLETED.
- Customer không được review nếu chưa mua.

Implement:
- Create review
- Update/delete review nếu phù hợp
- Get product reviews
- Rating 1–5
- Validation

Frontend hiển thị review trong product-detail.
```

---

## PROMPT 09 — PROMOTION

```text
Implement Coupon/Promotion.

Admin/Staff:
- Create coupon
- Update
- Disable
- List
- Search/filter

Customer:
- Apply coupon trong checkout.

Validate:
- code
- active
- start/end date
- minimum order
- percentage/fixed amount
- maximum discount

Không tin discount amount từ frontend.
Backend tự tính lại.
```

---

## PROMPT 10 — ADMIN

```text
Implement Admin Management.

Modules:
- User
- Staff
- Product
- Category
- Brand
- Branch
- Inventory
- Promotion
- Order

RBAC:
- Staff chỉ được chức năng Staff.
- Admin có quyền Admin.
- Customer không được truy cập admin API.

Frontend:
- admin layout
- sidebar
- tables
- forms
- modal
- toast
- pagination
- search/filter
```

---

## PROMPT 11 — DASHBOARD

```text
Implement Admin Dashboard.

Metrics:
- total orders
- total revenue
- cancelled orders
- new customers
- best-selling products
- revenue over time
- revenue by category
- revenue by branch

Backend trả dữ liệu JSON.

Frontend dùng Chart.js nếu cần.

Không tính số liệu quan trọng chỉ ở frontend.
Backend phải là nguồn dữ liệu chính.
```

---

## PROMPT 12 — TEST

```text
Review toàn bộ project.

Không thêm feature mới.

Kiểm tra:
- compile
- unit tests
- integration tests
- authentication
- authorization
- checkout
- inventory
- order cancellation
- coupon
- review

Tạo test cho các edge cases quan trọng.

Nếu phát hiện bug:
1. mô tả bug
2. xác định nguyên nhân
3. sửa
4. chạy lại test
```

---

## PROMPT 13 — CODE REVIEW

```text
Act as a Senior Java/Spring Boot + Vanilla JS reviewer.

Review toàn bộ project theo:
- architecture
- naming
- SOLID
- security
- database
- transaction
- API consistency
- DTO
- validation
- exception handling
- frontend structure
- duplicated code
- performance
- maintainability

Không rewrite toàn bộ project.

Chỉ sửa những vấn đề có giá trị rõ ràng.

Cuối cùng tạo:
docs/development-review.md
```

---

# 28. PROMPT KHI AI AGENT CODE BỊ LỖI

Dùng prompt này:

```text
Đừng rewrite project.

Hãy debug lỗi hiện tại theo quy trình:

1. Đọc stack trace/error message.
2. Xác định file gây lỗi.
3. Xác định nguyên nhân gốc.
4. Kiểm tra dependency liên quan.
5. Đưa ra nguyên nhân.
6. Sửa tối thiểu.
7. Chạy lại compile/test.
8. Nếu lỗi mới xuất hiện, tiếp tục debug.

Không thay đổi architecture nếu chưa cần.
Không tạo workaround tạm thời nếu có thể sửa nguyên nhân gốc.
```

---

# 29. PROMPT KHI MUỐN AI CODE 1 FEATURE

```text
Feature cần implement:

[TÊN FEATURE]

Context:
- Backend: Spring Boot 3.x + Java 21
- Database: MySQL 8
- ORM: Spring Data JPA
- Security: Spring Security + JWT
- Frontend: HTML5 + CSS3 + Vanilla JavaScript ES6 Modules
- API: REST JSON

Trước khi code:
1. Đọc project hiện tại.
2. Tìm code liên quan.
3. Không duplicate.
4. Liệt kê file cần tạo/sửa.

Sau đó implement end-to-end:
Backend
→ Database
→ API
→ Frontend
→ Validation
→ Security
→ Error handling
→ Test

Cuối cùng:
- compile
- test
- báo cáo file thay đổi
- báo cáo cách test feature.
```

---

# 30. PROMPT ĐỂ AI KHÔNG "VIBE CODE BỪA"

```text
STRICT ENGINEERING MODE.

Không được:
- đoán API
- đoán database
- tạo duplicate class
- tạo duplicate endpoint
- thay đổi framework
- thay đổi business rule
- xóa code chưa hiểu
- bỏ qua error
- fake success response
- hard-code dữ liệu nghiệp vụ nếu backend đã có database

Trước mỗi thay đổi:
- đọc code liên quan
- hiểu dependency
- giữ backward compatibility nếu có thể

Nếu thiếu thông tin:
- kiểm tra project trước
- chỉ hỏi khi thật sự không thể xác định

Mọi implementation phải nhất quán với 00_MASTER_CONTEXT.md.
```

---

# 31. PROMPT CHẠY FULL PROJECT

```text
Hãy kiểm tra project end-to-end như một developer chuẩn bị demo.

Kiểm tra:

1. MySQL startup
2. Backend startup
3. Database connection
4. Seed data
5. JWT
6. Login
7. Register
8. Product listing
9. Product detail
10. Search
11. Filter
12. Cart
13. Checkout
14. Coupon
15. Payment mock
16. Order history
17. Cancel order
18. Review
19. Admin login
20. Product management
21. Order management
22. User management
23. Staff management
24. Dashboard

Tìm lỗi trước khi thêm tính năng.

Nếu có lỗi:
- fix
- test lại
- không bỏ qua lỗi.
```

---

# 32. PROMPT TẠO README

```text
Đọc toàn bộ project.

Tạo README.md dành cho sinh viên/giảng viên có thể clone project và chạy.

Bao gồm:

- Project overview
- Architecture
- Technology stack
- Folder structure
- Requirements
- Database setup
- Environment variables
- Backend setup
- Frontend setup
- Demo accounts
- API overview
- Run instructions
- Test instructions
- Common errors
- Screenshots placeholder
```

---

# 33. CHECKLIST CUỐI DỰ ÁN

```text
ARCHITECTURE
[ ] Backend Spring Boot
[ ] Frontend HTML/CSS/JS
[ ] REST API
[ ] Layered architecture
[ ] DTO
[ ] Service
[ ] Repository

DATABASE
[ ] MySQL
[ ] FK
[ ] Index
[ ] Transaction
[ ] Seed data

SECURITY
[ ] BCrypt
[ ] JWT
[ ] RBAC
[ ] CORS
[ ] Validation
[ ] No password exposure

CUSTOMER
[ ] Register
[ ] Login
[ ] Profile
[ ] Address
[ ] Search
[ ] Filter
[ ] Product detail
[ ] Cart
[ ] Checkout
[ ] Coupon
[ ] Payment
[ ] Orders
[ ] Cancel
[ ] Review

STAFF
[ ] Products
[ ] Categories
[ ] Brands
[ ] Promotions
[ ] Orders

ADMIN
[ ] Users
[ ] Staff
[ ] Branches
[ ] Inventory
[ ] Dashboard
[ ] Revenue

QUALITY
[ ] Unit tests
[ ] Integration tests
[ ] Error handling
[ ] Logging
[ ] Responsive UI
[ ] README
[ ] Git
```

---

# 34. QUY TẮC QUAN TRỌNG NHẤT CHO AI AGENT

```text
1. Không code tất cả trong một lần.
2. Làm từng Phase.
3. Mỗi Phase phải chạy được.
4. Không chuyển sang Phase mới nếu Phase hiện tại đang broken.
5. Không tự ý đổi technology.
6. Không tự ý đổi business requirements.
7. Backend là nguồn dữ liệu và business logic chính.
8. Frontend không được bypass security.
9. Database phải đảm bảo integrity.
10. Checkout phải đảm bảo transaction.
11. Mọi API phải có validation.
12. Mọi API admin phải có authorization.
13. Mọi thay đổi lớn phải được giải thích ngắn gọn.
14. Ưu tiên code đơn giản, dễ hiểu, dễ demo hơn over-engineering.
15. Khi có nhiều cách triển khai, chọn cách dễ bảo trì và phù hợp với đồ án.
```

---

# 35. GỢI Ý WORKFLOW VIBE CODING

```text
00_MASTER_CONTEXT.md
        ↓
PROMPT 00
        ↓
PROMPT 01 Foundation
        ↓
PROMPT 02 Database
        ↓
PROMPT 03 Auth
        ↓
PROMPT 04 Product
        ↓
PROMPT 05 Cart
        ↓
PROMPT 06 Checkout
        ↓
PROMPT 07 Order
        ↓
PROMPT 08 Review
        ↓
PROMPT 09 Promotion
        ↓
PROMPT 10 Admin
        ↓
PROMPT 11 Dashboard
        ↓
PROMPT 12 Test
        ↓
PROMPT 13 Code Review
        ↓
Full Demo
```

---

# 36. LƯU Ý VỀ TÀI LIỆU YÊU CẦU

Tài liệu yêu cầu ban đầu mô tả kiến trúc frontend bằng ReactJS ở phần yêu cầu kỹ thuật. Tuy nhiên, trong quá trình triển khai dự án này, stack frontend được chốt theo yêu cầu triển khai là:

```text
HTML5
CSS3
Vanilla JavaScript ES6+
Fetch API
```

Backend vẫn giữ:

```text
Spring Boot
Spring Data JPA/Hibernate
Spring Security
MySQL
REST API
```

Không được trộn React vào project nếu không có quyết định kiến trúc mới.

---

# 37. KẾT QUẢ MONG MUỐN

Sau khi hoàn thành, project phải có:

```text
tech-store/
├── backend/      ← Spring Boot REST API
├── frontend/     ← HTML + CSS + Vanilla JS
├── database/     ← SQL schema + seed
├── docs/         ← tài liệu kỹ thuật
├── README.md
└── docker-compose.yml
```

Ứng dụng phải chạy được theo flow:

```text
Guest
  ↓
Home
  ↓
Product List
  ↓
Search / Filter
  ↓
Product Detail
  ↓
Login/Register
  ↓
Cart
  ↓
Checkout
  ↓
Coupon
  ↓
COD / Mock Payment
  ↓
Order
  ↓
Order History
  ↓
Review

Admin
  ↓
Dashboard
  ↓
Products
  ↓
Categories
  ↓
Brands
  ↓
Inventory
  ↓
Orders
  ↓
Promotions
  ↓
Users
  ↓
Staff
```

**Đây là source of truth cho AI Agent. Nếu code hiện tại khác tài liệu này, AI Agent phải đọc code hiện tại trước, xác định khác biệt, sau đó mới đề xuất thay đổi.**
