# Database TechStore

MySQL 8, InnoDB, utf8mb4. `schema.sql` định nghĩa 20 bảng, `seed.sql` chứa tài khoản demo và dữ liệu sản phẩm/kho/coupon.

- Dev: `techstore_db` (có thể đổi bằng DB_NAME).
- Test: `techstore_test`, tách riêng và dùng TEST_DB_USERNAME/TEST_DB_PASSWORD.
- Production: cấu hình DB_HOST/DB_PORT/DB_NAME/DB_USERNAME/DB_PASSWORD, Hibernate chỉ validate schema.

`schema.sql` có DROP TABLE. Chỉ dùng để khởi tạo database mới hoặc môi trường có thể dựng lại, không chạy lại trên dữ liệu cần giữ.

Script `scripts/test-backend.ps1` tự tạo database test và nạp seed khi database chưa có; không reset database đã tồn tại. Không chạy trực tiếp schema.sql/seed.sql để chuẩn bị test vì chúng chỉ định `USE techstore_db`.

Hướng dẫn cấu hình và chạy đầy đủ nằm ở README.md tại thư mục gốc.
