"""
HƯỚNG DẪN ĐỒNG BỘ ẢNH LÊN CLOUDINARY CHO DỰ ÁN TECHSTORE
=========================================================
Script này đọc danh sách sản phẩm từ `crawled_cellphones.json`,
tự động upload toàn bộ ảnh lên tài khoản Cloudinary của bạn,
và xuất ra file SQL mới `import_cellphones_cloudinary.sql` để nạp vào MySQL.

CÁCH DÙNG:
1. Mở Terminal trong thư mục techstore:
     py sync_to_cloudinary.py
2. Nhập 3 thông số Cloud Name, API Key, API Secret từ Cloudinary khi được hỏi
   (hoặc điền trực tiếp vào dòng 35-37 bên dưới).
"""

import json
import time
import os
import sys

# Đảm bảo in tiếng Việt chuẩn trên Windows
sys.stdout.reconfigure(encoding='utf-8')

try:
    import cloudinary
    import cloudinary.uploader
except ImportError:
    print("[!] Chưa cài đặt thư viện cloudinary.")
    print("    Vui lòng mở terminal và chạy: py -m pip install cloudinary")
    sys.exit(1)

# ==========================================
# CẤU HÌNH CLOUDINARY (LẤY TỪ DASHBOARD CLOUDINARY)
# ==========================================
CLOUD_NAME = os.getenv("CLOUDINARY_CLOUD_NAME", "YOUR_CLOUD_NAME")
API_KEY = os.getenv("CLOUDINARY_API_KEY", "YOUR_API_KEY")
API_SECRET = os.getenv("CLOUDINARY_API_SECRET", "YOUR_API_SECRET")

INPUT_JSON = "crawled_cellphones.json"
OUTPUT_JSON = "crawled_cellphones_cloudinary.json"
OUTPUT_SQL = "import_cellphones_cloudinary.sql"
CACHE_FILE = "cloudinary_url_cache.json"

def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_cache(cache):
    with open(CACHE_FILE, 'w', encoding='utf-8') as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)

def upload_image_to_cloudinary(url, cache):
    """Upload ảnh từ URL mạng lên Cloudinary (có bộ nhớ đệm chống upload trùng lặp)"""
    if not url or not url.startswith('http'):
        return url

    # Nếu đã upload ảnh này trước đó, lấy luôn từ cache
    if url in cache:
        return cache[url]

    try:
        # Cloudinary tự động tải ảnh từ URL gốc về server của họ
        res = cloudinary.uploader.upload(
            url,
            folder="techstore/products",
            use_filename=False,
            unique_filename=True,
            resource_type="image"
        )
        secure_url = res.get("secure_url")
        if secure_url:
            cache[url] = secure_url
            save_cache(cache)
            return secure_url
    except Exception as e:
        print(f"    [X] Lỗi upload ảnh {url[:50]}...: {e}")
        return url # Giữ lại URL cũ nếu lỗi

    return url

BRANDS_MAP = [
    (1, 'Apple', ['apple', 'macbook', 'iphone', 'ipad', 'airpods', 'apple watch', 'mac ']),
    (2, 'Samsung', ['samsung', 'galaxy']),
    (3, 'Dell', ['dell']),
    (4, 'Asus', ['asus', 'rog', 'tuf', 'vivobook', 'zenbook']),
    (5, 'Acer', ['acer', 'nitro', 'predator', 'aspire']),
    (6, 'Lenovo', ['lenovo', 'thinkpad', 'ideapad', 'legion', 'yoga', 'loq']),
    (7, 'MSI', ['msi', 'katana', 'cyborg', 'modern', 'stealth']),
    (8, 'HP', ['hp', 'pavilion', 'victus', 'omen', 'envy']),
    (9, 'Xiaomi', ['xiaomi', 'redmi', 'poco']),
    (10, 'Oppo', ['oppo']),
    (11, 'Sony', ['sony', 'playstation']),
    (12, 'JBL', ['jbl']),
    (13, 'Anker', ['anker', 'soundcore']),
    (14, 'Logitech', ['logitech']),
    (15, 'LG', ['lg', 'ultragear', 'gram']),
    (16, 'Garmin', ['garmin', 'fenix', 'forerunner']),
    (17, 'Marshall', ['marshall']),
    (18, 'Baseus', ['baseus']),
    (19, 'Ugreen', ['ugreen']),
    (20, 'Huawei', ['huawei']),
    (21, 'Amazfit', ['amazfit']),
    (22, 'Soundpeats', ['soundpeats']),
    (23, 'Vivo', ['vivo']),
    (24, 'Realme', ['realme']),
]

def detect_category_id(cat_name, prod_name):
    text = f"{cat_name} {prod_name}".lower()
    if 'laptop' in text or 'macbook' in text:
        return 2
    elif 'tablet' in text or 'ipad' in text or 'máy tính bảng' in text:
        return 3
    elif any(k in text for k in [
        'tai nghe', 'loa', 'sạc', 'cáp', 'chuột', 'bàn phím', 'phụ kiện', 'ốp lưng',
        'pin dự phòng', 'đồng hồ', 'watch', 'màn hình', 'sound', 'audio', 'headphone',
        'earphone', 'airpods', 'hub', 'củ sạc', 'dây sạc', 'vòng đeo tay', 'band'
    ]):
        return 4
    return 1

def detect_brand_id(brand_name, prod_name):
    text = f"{brand_name} {prod_name}".lower()
    for brand_id, name, keywords in BRANDS_MAP:
        if any(k in text for k in keywords):
            return brand_id
    return 4

def generate_sql(products, filepath):
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write("-- ==========================================================\n")
        f.write("-- DỮ LIỆU TECHSTORE ĐÃ ĐỒNG BỘ ẢNH LÊN CLOUDINARY\n")
        f.write("-- An toàn 100%: Tự động thay thế ảnh cũ bằng link Cloudinary CDN\n")
        f.write("-- Thời gian tạo: " + time.strftime("%Y-%m-%d %H:%M:%S") + "\n")
        f.write("-- ==========================================================\n\n")

        f.write("-- 1. Bổ sung các thương hiệu mở rộng nếu chưa có\n")
        f.write("INSERT INTO brands (id, name, slug, logo_url, description, status, created_at) VALUES\n")
        f.write("(5, 'Acer', 'acer', 'https://upload.wikimedia.org/wikipedia/commons/0/00/Acer_2011.svg', 'Thương hiệu máy tính Acer', 'ACTIVE', NOW()),\n")
        f.write("(6, 'Lenovo', 'lenovo', 'https://upload.wikimedia.org/wikipedia/commons/b/b8/Lenovo_logo_2015.svg', 'Thương hiệu máy tính Lenovo', 'ACTIVE', NOW()),\n")
        f.write("(7, 'MSI', 'msi', 'https://upload.wikimedia.org/wikipedia/commons/a/ae/Micro-Star_International_logo.svg', 'Thương hiệu máy tính MSI', 'ACTIVE', NOW()),\n")
        f.write("(8, 'HP', 'hp', 'https://upload.wikimedia.org/wikipedia/commons/a/ad/HP_logo_2012.svg', 'Thương hiệu máy tính HP', 'ACTIVE', NOW()),\n")
        f.write("(9, 'Xiaomi', 'xiaomi', 'https://upload.wikimedia.org/wikipedia/commons/2/29/Xiaomi_logo.svg', 'Thương hiệu công nghệ Xiaomi', 'ACTIVE', NOW()),\n")
        f.write("(10, 'Oppo', 'oppo', 'https://upload.wikimedia.org/wikipedia/commons/0/0a/OPPO_Logo.svg', 'Thương hiệu công nghệ Oppo', 'ACTIVE', NOW()),\n")
        f.write("(11, 'Sony', 'sony', 'https://upload.wikimedia.org/wikipedia/commons/c/ca/Sony_logo.svg', 'Tập đoàn điện tử Sony Nhật Bản', 'ACTIVE', NOW()),\n")
        f.write("(12, 'JBL', 'jbl', 'https://upload.wikimedia.org/wikipedia/commons/2/23/JBL_logo.svg', 'Thương hiệu âm thanh JBL Harman', 'ACTIVE', NOW()),\n")
        f.write("(13, 'Anker', 'anker', 'https://upload.wikimedia.org/wikipedia/commons/5/52/Anker_logo.svg', 'Thương hiệu phụ kiện sạc Anker Innovations', 'ACTIVE', NOW()),\n")
        f.write("(14, 'Logitech', 'logitech', 'https://upload.wikimedia.org/wikipedia/commons/0/08/Logitech_logo.svg', 'Phụ kiện chuột bàn phím Logitech Thụy Sĩ', 'ACTIVE', NOW()),\n")
        f.write("(15, 'LG', 'lg', 'https://upload.wikimedia.org/wikipedia/commons/2/20/LG_symbol.svg', 'Tập đoàn công nghệ điện tử LG Electronics', 'ACTIVE', NOW()),\n")
        f.write("(16, 'Garmin', 'garmin', 'https://upload.wikimedia.org/wikipedia/commons/c/c2/Garmin_logo.svg', 'Đồng hồ thông minh thể thao Garmin', 'ACTIVE', NOW()),\n")
        f.write("(17, 'Marshall', 'marshall', 'https://upload.wikimedia.org/wikipedia/commons/7/7b/Marshall_Amplification_logo.svg', 'Thương hiệu âm thanh Marshall Anh Quốc', 'ACTIVE', NOW()),\n")
        f.write("(18, 'Baseus', 'baseus', 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Baseus_logo.png/320px-Baseus_logo.png', 'Thương hiệu phụ kiện công nghệ Baseus', 'ACTIVE', NOW()),\n")
        f.write("(19, 'Ugreen', 'ugreen', 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Ugreen_Logo.svg/320px-Ugreen_Logo.svg.png', 'Thương hiệu phụ kiện cáp sạc Ugreen', 'ACTIVE', NOW()),\n")
        f.write("(20, 'Huawei', 'huawei', 'https://upload.wikimedia.org/wikipedia/commons/0/00/Huawei_Logo.svg', 'Tập đoàn viễn thông và thiết bị Huawei', 'ACTIVE', NOW()),\n")
        f.write("(21, 'Amazfit', 'amazfit', 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Amazfit_logo.svg/320px-Amazfit_logo.svg.png', 'Đồng hồ thông minh theo dõi sức khỏe Amazfit', 'ACTIVE', NOW()),\n")
        f.write("(22, 'Soundpeats', 'soundpeats', 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/SoundPEATS_Logo.png/320px-SoundPEATS_Logo.png', 'Tai nghe âm thanh SoundPEATS', 'ACTIVE', NOW()),\n")
        f.write("(23, 'Vivo', 'vivo', 'https://upload.wikimedia.org/wikipedia/commons/e/e5/Vivo_mobile_logo.png', 'Thương hiệu điện thoại thông minh Vivo', 'ACTIVE', NOW()),\n")
        f.write("(24, 'Realme', 'realme', 'https://upload.wikimedia.org/wikipedia/commons/a/a9/Realme_logo.svg', 'Thương hiệu điện thoại thông minh Realme', 'ACTIVE', NOW())\n")
        f.write("ON DUPLICATE KEY UPDATE name = VALUES(name);\n\n")

        f.write("-- 2. Danh sách sản phẩm với link ảnh Cloudinary\n")
        for i, p in enumerate(products, 1):
            name_escaped = p['name'].replace("'", "''")
            desc_escaped = p['description'].replace("'", "''")
            specs_escaped = p['specifications'].replace("'", "''")
            slug = p['slug']
            sku = p['sku']
            price = p['price']
            cost_price = p['cost_price']
            cat_id = detect_category_id(p.get('category_name', ''), p['name'])
            brand_id = detect_brand_id(p.get('brand_name', ''), p['name'])

            f.write(f"-- [{i}/{len(products)}] {p['name']}\n")
            f.write(f"INSERT INTO products (name, slug, sku, price, cost_price, description, specifications, status, category_id, brand_id, created_at, updated_at) "
                    f"VALUES ('{name_escaped}', '{slug}', '{sku}', {price}, {cost_price}, '{desc_escaped}', '{specs_escaped}', 'ACTIVE', {cat_id}, {brand_id}, NOW(), NOW()) "
                    f"ON DUPLICATE KEY UPDATE category_id = {cat_id}, brand_id = {brand_id}, price = {price}, specifications = '{specs_escaped}';\n")

            images = p.get('images', [])
            if not images and p.get('primary_image'):
                images = [p['primary_image']]

            # Xóa các link ảnh cũ để cập nhật link Cloudinary sạch sẽ
            f.write(f"DELETE pi FROM product_images pi JOIN products p ON pi.product_id = p.id WHERE p.sku = '{sku}';\n")

            for order_idx, img_url in enumerate(images):
                is_primary = 1 if order_idx == 0 else 0
                f.write(f"INSERT INTO product_images (product_id, image_url, is_primary, display_order) "
                        f"SELECT p.id, '{img_url}', {is_primary}, {order_idx} FROM products p WHERE p.sku = '{sku}';\n")

            # Tồn kho chi nhánh
            f.write(f"INSERT INTO inventories (product_id, branch_id, quantity, min_stock_alert) "
                    f"SELECT p.id, 1, 20, 3 FROM products p WHERE p.sku = '{sku}' "
                    f"AND NOT EXISTS (SELECT 1 FROM inventories inv WHERE inv.product_id = p.id AND inv.branch_id = 1);\n")
            f.write(f"INSERT INTO inventories (product_id, branch_id, quantity, min_stock_alert) "
                    f"SELECT p.id, 2, 15, 3 FROM products p WHERE p.sku = '{sku}' "
                    f"AND NOT EXISTS (SELECT 1 FROM inventories inv WHERE inv.product_id = p.id AND inv.branch_id = 2);\n\n")

def main():
    global CLOUD_NAME, API_KEY, API_SECRET

    if CLOUD_NAME == "YOUR_CLOUD_NAME" or not CLOUD_NAME:
        print("="*60)
        print("💡 NHẬP THÔNG TIN CLOUDINARY (Lấy từ dashboard Cloudinary của bạn):")
        print("="*60)
        c_name = input("1. Nhập Cloud Name: ").strip()
        a_key = input("2. Nhập API Key: ").strip()
        a_sec = input("3. Nhập API Secret: ").strip()
        
        if not c_name or not a_key or not a_sec:
            print("[!] Bạn chưa nhập đủ thông tin. Script dừng lại.")
            return
            
        CLOUD_NAME = c_name
        API_KEY = a_key
        API_SECRET = a_sec

    # Thiết lập cấu hình cloudinary
    cloudinary.config(
        cloud_name=CLOUD_NAME,
        api_key=API_KEY,
        api_secret=API_SECRET,
        secure=True
    )

    if not os.path.exists(INPUT_JSON):
        print(f"[!] Không tìm thấy file {INPUT_JSON}. Hãy chắc chắn file đang ở cùng thư mục.")
        return

    with open(INPUT_JSON, 'r', encoding='utf-8') as f:
        products = json.load(f)

    print("\n" + "="*60)
    print(f"[*] Đang đọc {len(products)} sản phẩm từ {INPUT_JSON}...")
    cache = load_cache()
    print(f"[*] Đã nạp {len(cache)} link ảnh từ bộ nhớ đệm (cache).")
    print(f"[*] Bắt đầu đồng bộ ảnh lên Cloudinary ({CLOUD_NAME})...")
    print("="*60)

    total_uploaded = 0
    updated_products = []

    for idx, p in enumerate(products, 1):
        print(f"\n[{idx}/{len(products)}] Đang xử lý: {p.get('name')}")
        
        # 1. Upload ảnh chính
        primary = p.get('primary_image')
        new_primary = upload_image_to_cloudinary(primary, cache)
        if new_primary != primary:
            total_uploaded += 1

        # 2. Upload danh sách ảnh gallery
        new_images = []
        for img_url in p.get('images', []):
            up_url = upload_image_to_cloudinary(img_url, cache)
            new_images.append(up_url)
            if up_url != img_url:
                total_uploaded += 1

        p_copy = dict(p)
        p_copy['primary_image'] = new_primary
        p_copy['images'] = new_images
        updated_products.append(p_copy)
        
        # Lưu file JSON cập nhật thường xuyên đề phòng ngắt quãng
        with open(OUTPUT_JSON, 'w', encoding='utf-8') as f_out:
            json.dump(updated_products, f_out, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print(f"[✓] HOÀN TẤT ĐỒNG BỘ LÊN CLOUDINARY!")
    print(f"    - Tổng ảnh mới đã upload: {total_uploaded}")
    print(f"    - Đã xuất JSON mới: {OUTPUT_JSON}")
    
    generate_sql(updated_products, OUTPUT_SQL)
    print(f"    - Đã xuất file SQL: {OUTPUT_SQL}")
    print("="*60)
    print("\n👉 BÂY GIỜ BẠN CHỈ CẦN:")
    print(f"    Mở MySQL Workbench / DBeaver / Terminal và chạy file `{OUTPUT_SQL}`")
    print("    để cập nhật toàn bộ link ảnh Cloudinary sạch sẽ vào database!")

if __name__ == '__main__':
    main()
