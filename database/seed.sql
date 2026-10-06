-- ====================================================================
-- TechStore E-Commerce Seed Data
-- Passwords for demo users are: 'password123'
-- BCrypt Hash: $2a$10$V/xNOHtQkvHd3vndvEtxKe9vLBVDahr0c4UwI210CMjXy9nnloLoi
-- ====================================================================

USE techstore_db;

SET NAMES 'utf8mb4';
SET CHARACTER SET utf8mb4;
SET character_set_connection = 'utf8mb4';

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Roles
INSERT INTO roles (id, name) VALUES
(1, 'ROLE_CUSTOMER'),
(2, 'ROLE_STAFF'),
(3, 'ROLE_ADMIN')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 2. Users (Password: password123)
INSERT INTO users (id, email, phone, password, full_name, avatar_url, status, created_at) VALUES
(1, 'admin@techstore.com', '0901000001', '$2a$10$V/xNOHtQkvHd3vndvEtxKe9vLBVDahr0c4UwI210CMjXy9nnloLoi', 'Nguyễn Quản Trị', 'https://ui-avatars.com/api/?name=Admin', 'ACTIVE', NOW()),
(2, 'staff@techstore.com', '0901000002', '$2a$10$V/xNOHtQkvHd3vndvEtxKe9vLBVDahr0c4UwI210CMjXy9nnloLoi', 'Trần Nhân Viên', 'https://ui-avatars.com/api/?name=Staff', 'ACTIVE', NOW()),
(3, 'customer1@gmail.com', '0901000003', '$2a$10$V/xNOHtQkvHd3vndvEtxKe9vLBVDahr0c4UwI210CMjXy9nnloLoi', 'Lê Khách Hàng', 'https://ui-avatars.com/api/?name=Customer+One', 'ACTIVE', NOW()),
(4, 'customer2@gmail.com', '0901000004', '$2a$10$V/xNOHtQkvHd3vndvEtxKe9vLBVDahr0c4UwI210CMjXy9nnloLoi', 'Phạm Khách Mua', 'https://ui-avatars.com/api/?name=Customer+Two', 'ACTIVE', NOW())
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), password = VALUES(password);

-- 3. User Roles
INSERT INTO user_roles (user_id, role_id) VALUES
(1, 3), -- admin has ROLE_ADMIN
(1, 2), -- admin also has ROLE_STAFF
(2, 2), -- staff has ROLE_STAFF
(3, 1), -- customer1 has ROLE_CUSTOMER
(4, 1)  -- customer2 has ROLE_CUSTOMER
ON DUPLICATE KEY UPDATE user_id = VALUES(user_id);

-- 4. Addresses
INSERT INTO addresses (id, user_id, recipient_name, phone, street_address, ward, district, city, is_default, created_at) VALUES
(1, 3, 'Lê Khách Hàng', '0901000003', '123 Đường Cầu Giấy', 'Dịch Vọng', 'Cầu Giấy', 'Hà Nội', TRUE, NOW()),
(2, 4, 'Phạm Khách Mua', '0901000004', '456 Nguyễn Huệ', 'Bến Nghé', 'Quận 1', 'TP. Hồ Chí Minh', TRUE, NOW())
ON DUPLICATE KEY UPDATE recipient_name = VALUES(recipient_name);

-- 5. Categories
INSERT INTO categories (id, name, slug, description, image_url, status, created_at) VALUES
(1, 'Điện Thoại', 'dien-thoai', 'Điện thoại thông minh Smartphone mới nhất', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=300', 'ACTIVE', NOW()),
(2, 'Laptop', 'laptop', 'Máy tính xách tay văn phòng, đồ họa, gaming', 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=300', 'ACTIVE', NOW()),
(3, 'Tablet', 'tablet', 'Máy tính bảng phục vụ học tập và sáng tạo', 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=300', 'ACTIVE', NOW()),
(4, 'Phụ Kiện', 'phu-kien', 'Tai nghe, củ sạc, cáp sạc, phụ kiện công nghệ', 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300', 'ACTIVE', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- 6. Brands
INSERT INTO brands (id, name, slug, logo_url, description, status, created_at) VALUES
(1, 'Apple', 'apple', 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg', 'Thương hiệu Apple cao cấp từ Mỹ', 'ACTIVE', NOW()),
(2, 'Samsung', 'samsung', 'https://upload.wikimedia.org/wikipedia/commons/2/24/Samsung_Logo.svg', 'Tập đoàn công nghệ hàng đầu Hàn Quốc', 'ACTIVE', NOW()),
(3, 'Dell', 'dell', 'https://upload.wikimedia.org/wikipedia/commons/4/48/Dell_Logo.svg', 'Laptop Dell bền bỉ, hiệu năng cao', 'ACTIVE', NOW()),
(4, 'Asus', 'asus', 'https://upload.wikimedia.org/wikipedia/commons/2/2e/ASUS_Logo.svg', 'Thương hiệu máy tính Asus Đài Loan', 'ACTIVE', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- 7. Branches
INSERT INTO branches (id, name, phone, address, status, created_at) VALUES
(1, 'TechStore Chi Nhánh Hà Nội', '024-3888-9999', 'Số 68 Đường Cầu Giấy, Quận Cầu Giấy, Hà Nội', 'ACTIVE', NOW()),
(2, 'TechStore Chi Nhánh TP.HCM', '028-3999-8888', 'Số 120 Đường Nguyễn Thị Minh Khai, Quận 3, TP. Hồ Chí Minh', 'ACTIVE', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name), address = VALUES(address);

-- 8. Products
INSERT INTO products (id, category_id, brand_id, name, slug, sku, price, cost_price, description, specifications, status, created_at) VALUES
(1, 1, 1, 'iPhone 15 Pro Max 256GB Titan Tự Nhiên', 'iphone-15-pro-max-256gb', 'APL-IP15PM-256', 29990000.00, 26000000.00, 'iPhone 15 Pro Max khung viền titan siêu nhẹ, chip A17 Pro đỉnh cao, camera tiềm vọng zoom quang 5x ấn tượng.', '{"Màn hình": "6.7 inch Super Retina XDR", "Chip": "Apple A17 Pro 3nm", "RAM": "8GB", "Bộ nhớ": "256GB", "Pin": "4422 mAh"}', 'ACTIVE', NOW()),
(2, 2, 1, 'MacBook Pro 14 M3 Pro 18GB/512GB Space Black', 'macbook-pro-14-m3-pro', 'APL-MBP14-M3P', 49990000.00, 44000000.00, 'MacBook Pro 14 inch trang bị chip M3 Pro mạnh mẽ, màn hình Liquid Retina XDR 120Hz sắc nét đỉnh cao.', '{"Màn hình": "14.2 inch Liquid Retina XDR", "CPU": "Apple M3 Pro 11 Core", "GPU": "14 Core", "RAM": "18GB", "Ổ cứng": "512GB SSD"}', 'ACTIVE', NOW()),
(3, 1, 2, 'Samsung Galaxy S24 Ultra 12GB/256GB Titan Xám', 'samsung-galaxy-s24-ultra', 'SS-S24U-256', 27990000.00, 24000000.00, 'Galaxy S24 Ultra tích hợp Galaxy AI thông minh vượt trội, bút S-Pen tiện lợi, chip Snapdragon 8 Gen 3 for Galaxy.', '{"Màn hình": "6.8 inch Dynamic AMOLED 2X", "Chip": "Snapdragon 8 Gen 3 for Galaxy", "RAM": "12GB", "Bộ nhớ": "256GB", "Camera": "200MP + 50MP + 12MP + 10MP"}', 'ACTIVE', NOW()),
(4, 2, 3, 'Dell XPS 15 9530 Core i7-13700H / 16GB / 512GB / RTX 4050', 'dell-xps-15-9530', 'DELL-XPS15-9530', 42990000.00, 38000000.00, 'Dell XPS 15 thiết kế nhôm nguyên khối viền siêu mỏng, hiệu năng đồ họa ấn tượng cho chuyên gia sáng tạo nội dung.', '{"Màn hình": "15.6 inch FHD+ OLED", "CPU": "Intel Core i7-13700H", "RAM": "16GB DDR5", "VGA": "NVIDIA GeForce RTX 4050 6GB", "SSD": "512GB"}', 'ACTIVE', NOW()),
(5, 4, 1, 'Tai nghe AirPods Pro 2 MagSafe USB-C', 'airpods-pro-2-usb-c', 'APL-APP2-USBC', 5690000.00, 4800000.00, 'Tai nghe AirPods Pro 2 chống ồn chủ động gấp 2 lần, cổng sạc Type-C chuẩn mới, thời lượng pin bền bỉ.', '{"Chống ồn": "Chủ động ANC thế hệ mới", "Chip": "Apple H2", "Cổng sạc": "USB-C & MagSafe", "Thời lượng pin": "Lên tới 30 giờ kèm hộp"}', 'ACTIVE', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description), specifications = VALUES(specifications);

-- 9. Product Images
INSERT INTO product_images (id, product_id, image_url, is_primary, display_order) VALUES
(1, 1, 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=500', TRUE, 1),
(2, 2, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500', TRUE, 1),
(3, 3, 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=500', TRUE, 1),
(4, 4, 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=500', TRUE, 1),
(5, 5, 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=500', TRUE, 1)
ON DUPLICATE KEY UPDATE image_url = VALUES(image_url);

-- 10. Inventories
INSERT INTO inventories (id, product_id, branch_id, quantity, min_stock_alert) VALUES
(1, 1, 1, 50, 5), -- iPhone 15 PM tại Hà Nội
(2, 1, 2, 40, 5), -- iPhone 15 PM tại TP.HCM
(3, 2, 1, 20, 3), -- MacBook Pro tại Hà Nội
(4, 2, 2, 15, 3), -- MacBook Pro tại TP.HCM
(5, 3, 1, 35, 5), -- Galaxy S24U tại Hà Nội
(6, 3, 2, 30, 5), -- Galaxy S24U tại TP.HCM
(7, 4, 1, 15, 2), -- Dell XPS tại Hà Nội
(8, 4, 2, 10, 2), -- Dell XPS tại TP.HCM
(9, 5, 1, 100, 10), -- AirPods Pro tại Hà Nội
(10, 5, 2, 80, 10)  -- AirPods Pro tại TP.HCM
ON DUPLICATE KEY UPDATE quantity = VALUES(quantity);

-- 11. Carts
INSERT INTO carts (id, user_id, created_at) VALUES
(1, 3, NOW()),
(2, 4, NOW())
ON DUPLICATE KEY UPDATE user_id = VALUES(user_id);

-- 12. Coupons
INSERT INTO coupons (id, code, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, used_count, start_date, end_date, is_active, created_at) VALUES
(1, 'TECH10', 'PERCENTAGE', 10.00, 5000000.00, 2000000.00, 100, 0, '2026-01-01 00:00:00', '2026-12-31 23:59:59', TRUE, NOW()),
(2, 'WELCOME50K', 'FIXED_AMOUNT', 50000.00, 500000.00, 50000.00, 500, 0, '2026-01-01 00:00:00', '2026-12-31 23:59:59', TRUE, NOW())
ON DUPLICATE KEY UPDATE code = VALUES(code);

SET FOREIGN_KEY_CHECKS = 1;
