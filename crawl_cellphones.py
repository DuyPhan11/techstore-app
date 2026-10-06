import urllib.request
import re
import json
import time
import os
import sys

# Đảm bảo in tiếng Việt chuẩn trên Windows terminal
sys.stdout.reconfigure(encoding='utf-8')

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
}

# Danh mục mở rộng toàn diện bao gồm cả các thiết bị mới và phụ kiện công nghệ
SUBCATEGORIES_MAP = {
    'laptop': [
        'https://cellphones.com.vn/laptop.html',
        'https://cellphones.com.vn/laptop/mac.html',
        'https://cellphones.com.vn/laptop/asus.html',
        'https://cellphones.com.vn/laptop/lenovo.html',
        'https://cellphones.com.vn/laptop/acer.html',
        'https://cellphones.com.vn/laptop/dell.html',
        'https://cellphones.com.vn/laptop/hp.html',
        'https://cellphones.com.vn/laptop/msi.html',
        'https://cellphones.com.vn/laptop/lg.html',
    ],
    'mobile': [
        'https://cellphones.com.vn/mobile.html',
        'https://cellphones.com.vn/mobile/apple.html',
        'https://cellphones.com.vn/mobile/samsung.html',
        'https://cellphones.com.vn/mobile/xiaomi.html',
        'https://cellphones.com.vn/mobile/oppo.html',
        'https://cellphones.com.vn/mobile/realme.html',
        'https://cellphones.com.vn/mobile/vivo.html',
    ],
    'tablet': [
        'https://cellphones.com.vn/tablet.html',
        'https://cellphones.com.vn/tablet/ipad.html',
        'https://cellphones.com.vn/tablet/samsung.html',
        'https://cellphones.com.vn/tablet/xiaomi.html',
    ],
    'audio': [
        'https://cellphones.com.vn/thiet-bi-am-thanh/tai-nghe/tai-nghe-bluetooth.html',
        'https://cellphones.com.vn/thiet-bi-am-thanh/loa/loa-bluetooth.html',
        'https://cellphones.com.vn/thiet-bi-am-thanh/tai-nghe.html',
        'https://cellphones.com.vn/thiet-bi-am-thanh/loa.html',
    ],
    'accessories': [
        'https://cellphones.com.vn/phu-kien/pin-du-phong.html',
        'https://cellphones.com.vn/phu-kien/sac-dien-thoai.html',
        'https://cellphones.com.vn/phu-kien/sac-dien-thoai/cap-dien-thoai.html',
        'https://cellphones.com.vn/phu-kien/chuot-ban-phim-may-tinh.html',
        'https://cellphones.com.vn/phu-kien/balo-tui-chong-soc-laptop.html',
        'https://cellphones.com.vn/phu-kien/the-nho-usb-otg.html',
    ],
    'smartwatch': [
        'https://cellphones.com.vn/do-choi-cong-nghe/dong-ho-the-thao.html',
        'https://cellphones.com.vn/do-choi-cong-nghe/dong-ho-thong-minh-nghe-goi.html',
        'https://cellphones.com.vn/do-choi-cong-nghe/dong-ho-thong-minh-chong-nuoc.html',
        'https://cellphones.com.vn/do-choi-cong-nghe.html',
    ],
    'monitors': [
        'https://cellphones.com.vn/man-hinh.html',
        'https://cellphones.com.vn/man-hinh/asus.html',
        'https://cellphones.com.vn/man-hinh/dell.html',
        'https://cellphones.com.vn/man-hinh/samsung.html',
        'https://cellphones.com.vn/man-hinh/lg.html',
    ],
}

# Danh sách danh mục đen (bỏ qua trang danh mục hoặc trang phụ)
EXCLUDE_SLUGS = {
    'laptop', 'mobile', 'tablet', 'phu-kien', 'thiet-bi-am-thanh', 'man-hinh',
    'tivi', 'tu-lanh', 'do-choi-cong-nghe', 'may-tinh-de-ban', 'nha-thong-minh',
    'hang-cu', 'cart', 'tin-tuc', 'chinh-sach', 'lien-he', 'hoi-dap', 'tra-cuu',
    'apple', 'samsung', 'xiaomi', 'oppo', 'dell', 'asus', 'acer', 'lenovo', 'msi', 'hp',
    'may-in', 'dien-may', 'linh-kien', 'danh-sach-khuyen-mai', 'uu-dai-smember',
    'tra-gop', 'bao-hanh', 'tos', 'do-gia-dung', 'smember', 'so-sanh', 'vat-refund',
    'chinh-sach-giao-hang', 'quy-che-hoat-dong', 'lien-he-hop-tac', 'dich-vu'
}

# Các từ khóa giả định hoặc sản phẩm tin đồn ở footer CellphoneS
FAKE_PATTERNS = ['iphone-18', 'iphone-17', 'z-flip-8', 'z-fold-8', 'find-x9']

# Bảng nhận diện 24 thương hiệu công nghệ phổ biến
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

def fetch_html(url):
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=12) as response:
            return response.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"  [Lỗi tải {url}]: {e}")
        return None

def extract_links_from_single_page(html):
    """Trích xuất danh sách link sản phẩm hợp lệ, xử lý cả template cũ lẫn template cpsui mới"""
    # 1. Tìm qua class product__link (template danh mục cũ)
    p1 = re.findall(r'href=["\']((?:https://cellphones\.com\.vn)?/[a-zA-Z0-9\-]+\.html)["\'][^>]*class=["\'][^"\']*product__link', html)
    
    # 2. Tìm qua mọi thẻ <a> kết thúc bằng .html (template cpsui mới)
    p2 = re.findall(r'<a[^>]+href=["\']((?:https://cellphones\.com\.vn)?/?[a-zA-Z0-9\-]+\.html)["\']', html)
    
    candidates = p1 if len(p1) >= 5 else p2
    valid = []
    seen = set()
    
    for raw in candidates:
        path = raw.replace('https://cellphones.com.vn', '').strip('/')
        if '/' in path or not path.endswith('.html'):
            continue
            
        slug = path.replace('.html', '')
        if slug.lower() in EXCLUDE_SLUGS:
            continue
        if any(f in slug.lower() for f in FAKE_PATTERNS):
            continue
            
        full_url = f"https://cellphones.com.vn/{path}"
        if full_url not in seen:
            seen.add(full_url)
            valid.append(full_url)
            
    return valid

def get_product_links(category_key_or_url='all', limit=50):
    """
    Thu thập link sản phẩm:
    Hỗ trợ: 'all', 'laptop', 'mobile', 'tablet', 'audio', 'accessories', 'smartwatch', 'monitors'
    hoặc trực tiếp bất kỳ URL nào của CellphoneS.
    """
    unique_links = []
    seen = set()
    
    if category_key_or_url == 'all':
        # Phối hợp đều các danh mục
        urls_to_scan = []
        for cat_key in ['laptop', 'mobile', 'audio', 'accessories', 'tablet', 'monitors', 'smartwatch']:
            urls_to_scan.extend(SUBCATEGORIES_MAP[cat_key])
    elif category_key_or_url in SUBCATEGORIES_MAP:
        urls_to_scan = SUBCATEGORIES_MAP[category_key_or_url]
    else:
        # Nhận diện theo từ khóa trong URL hoặc quét trực tiếp URL đó
        matched = False
        for key, sub_urls in SUBCATEGORIES_MAP.items():
            if key in category_key_or_url.lower():
                urls_to_scan = sub_urls
                matched = True
                break
        if not matched:
            urls_to_scan = [category_key_or_url]
            
    print(f"[*] Bắt đầu thu thập link sản phẩm (Mục tiêu: {limit} sản phẩm)...")
    
    for page_url in urls_to_scan:
        print(f"  -> Quét trang: {page_url}")
        html = fetch_html(page_url)
        if not html:
            continue
            
        links = extract_links_from_single_page(html)
        added_count = 0
        for l in links:
            if l not in seen:
                seen.add(l)
                unique_links.append(l)
                added_count += 1
                if len(unique_links) >= limit:
                    break
                    
        print(f"     (+{added_count} link mới | Đã thu thập: {len(unique_links)}/{limit})")
        if len(unique_links) >= limit:
            break
        time.sleep(0.5)
        
    print(f"[✓] Quét link hoàn tất: Thu thập được {len(unique_links)} sản phẩm hợp lệ.\n")
    return unique_links

def parse_product_detail(product_url):
    """Phân tích chi tiết một sản phẩm: Tên, giá, hình ảnh, thông số kỹ thuật, hãng, loại"""
    html = fetch_html(product_url)
    if not html:
        return None
        
    scripts = re.findall(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>', html, re.DOTALL)
    
    product_data = None
    brand = "Khác"
    category = "Công nghệ"
    
    for s in scripts:
        try:
            data = json.loads(s.strip())
            if data.get('@type') == 'Product':
                product_data = data
            elif data.get('@type') == 'BreadcrumbList':
                elements = data.get('itemListElement', [])
                if len(elements) >= 3:
                    category = elements[1].get('item', {}).get('name', category)
                    brand = elements[2].get('item', {}).get('name', brand)
        except Exception:
            continue
            
    if not product_data or not product_data.get('name'):
        return None
        
    # Lấy thông số kỹ thuật (additionalProperty)
    specs = {}
    for prop in product_data.get('additionalProperty', []):
        name = prop.get('name')
        val = prop.get('value')
        if name and val:
            specs[name] = val
            
    # Lấy giá
    offers = product_data.get('offers', {})
    price = 0.0
    if isinstance(offers, dict):
        try:
            price = float(offers.get('price', 0))
        except (ValueError, TypeError):
            price = 0.0
            
    # Lấy danh sách toàn bộ ảnh gallery (3 - 5 ảnh chi tiết các góc máy)
    primary_img = product_data.get('image')
    gallery_imgs = []
    seen_imgs = set()
    
    if primary_img:
        clean_primary = primary_img.replace('/200x/', '/x/')
        seen_imgs.add(clean_primary)
        gallery_imgs.append(clean_primary)
        
    # Tìm các ảnh chi tiết độ phân giải cao trong mã nguồn
    raw_catalog_imgs = re.findall(r'media/catalog/product/([a-zA-Z0-9_\-\./]+\.(?:png|jpg|jpeg|webp))', html)
    for img_path in raw_catalog_imgs:
        if any(b in img_path.lower() for b in ['frame', 'icon', 'badge', 'banner', 'logo']):
            continue
        full_img_url = f"https://cdn2.cellphones.com.vn/x/media/catalog/product/{img_path}"
        if full_img_url not in seen_imgs:
            seen_imgs.add(full_img_url)
            gallery_imgs.append(full_img_url)
            if len(gallery_imgs) >= 5: # Giới hạn tối đa 5 ảnh đẹp nhất mỗi sản phẩm
                break

    import hashlib
    slug = product_url.split('/')[-1].replace('.html', '')
    sku_hash = hashlib.md5(slug.encode('utf-8')).hexdigest()[:6].upper()
    sku = f"CP-{slug[:10].upper().replace('-', '')}-{sku_hash}"
    
    return {
        'name': product_data.get('name'),
        'slug': slug,
        'sku': sku,
        'price': price,
        'cost_price': price * 0.85 if price > 0 else 0,
        'primary_image': gallery_imgs[0] if gallery_imgs else primary_img,
        'images': gallery_imgs,
        'description': product_data.get('description', ''),
        'category_name': category,
        'brand_name': brand,
        'specifications': json.dumps(specs, ensure_ascii=False),
        'origin_url': product_url
    }

def detect_category_id(cat_name, prod_name):
    """
    Theo seed.sql của TechStore:
    1: Điện Thoại
    2: Laptop
    3: Tablet
    4: Phụ Kiện (Tai nghe, Loa, Sạc cáp, Pin sạc, Chuột, Phím, Đồng hồ, Màn hình...)
    """
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
    return 1 # Mặc định Điện Thoại

def detect_brand_id(brand_name, prod_name):
    """Nhận diện thương hiệu tự động dựa trên bảng 24 hãng công nghệ"""
    text = f"{brand_name} {prod_name}".lower()
    for brand_id, name, keywords in BRANDS_MAP:
        if any(k in text for k in keywords):
            return brand_id
    return 4 # Mặc định Asus nếu không nhận diện được

def save_to_json(products, filepath):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(products, f, ensure_ascii=False, indent=2)
    print(f"[✓] Đã xuất {len(products)} sản phẩm ra file JSON: {filepath}")

def save_to_sql(products, filepath):
    """Xuất file .sql an toàn tuyệt đối chống trùng lặp dữ liệu vào MySQL TechStore"""
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write("-- DỮ LIỆU CÀO TỰ ĐỘNG TỪ CELLPHONES CHO DỰ ÁN TECHSTORE\n")
        f.write("-- An toàn 100%: Chạy bao nhiêu lần cũng KHÔNG bị trùng lặp dữ liệu\n")
        f.write("-- Ngày cào: " + time.strftime("%Y-%m-%d %H:%M:%S") + "\n\n")
        
        # 1. Đảm bảo 24 thương hiệu phổ biến đã có trong bảng brands
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

        # 2. Thêm từng sản phẩm vào bảng products, product_images và inventories
        f.write("-- 2. Danh sách sản phẩm\n")
        for i, p in enumerate(products, 1):
            name_escaped = p['name'].replace("'", "''")
            desc_escaped = p['description'].replace("'", "''")
            specs_escaped = p['specifications'].replace("'", "''")
            slug = p['slug']
            sku = p['sku']
            price = p['price']
            cost_price = p['cost_price']
            img = p['primary_image'] or ''
            
            # Tự động nhận diện category_id và brand_id chính xác
            cat_id = detect_category_id(p.get('category_name', ''), p['name'])
            brand_id = detect_brand_id(p.get('brand_name', ''), p['name'])
            
            f.write(f"-- [{i}/{len(products)}] {p['name']} (Cat: {cat_id}, Brand: {brand_id})\n")
            f.write(f"INSERT INTO products (name, slug, sku, price, cost_price, description, specifications, status, category_id, brand_id, created_at, updated_at) "
                    f"VALUES ('{name_escaped}', '{slug}', '{sku}', {price}, {cost_price}, '{desc_escaped}', '{specs_escaped}', 'ACTIVE', {cat_id}, {brand_id}, NOW(), NOW()) "
                    f"ON DUPLICATE KEY UPDATE category_id = {cat_id}, brand_id = {brand_id}, price = {price}, specifications = '{specs_escaped}';\n")
            
            # Xóa ảnh cũ trước khi nạp lại để chống duplicate ảnh khi chạy nhiều lần
            f.write(f"DELETE pi FROM product_images pi JOIN products p ON pi.product_id = p.id WHERE p.sku = '{sku}';\n")
            
            # Thêm danh sách ảnh gallery
            images = p.get('images', [])
            if not images and img:
                images = [img]
                
            for order_idx, img_url in enumerate(images):
                is_primary = 1 if order_idx == 0 else 0
                f.write(f"INSERT INTO product_images (product_id, image_url, is_primary, display_order) "
                        f"SELECT p.id, '{img_url}', {is_primary}, {order_idx} FROM products p WHERE p.sku = '{sku}';\n")
                        
            # Thêm tồn kho mẫu tại 2 chi nhánh (Hà Nội & TP.HCM)
            f.write(f"INSERT INTO inventories (product_id, branch_id, quantity, min_stock_alert) "
                    f"SELECT p.id, 1, 25, 3 FROM products p WHERE p.sku = '{sku}' "
                    f"AND NOT EXISTS (SELECT 1 FROM inventories inv WHERE inv.product_id = p.id AND inv.branch_id = 1);\n")
            f.write(f"INSERT INTO inventories (product_id, branch_id, quantity, min_stock_alert) "
                    f"SELECT p.id, 2, 20, 3 FROM products p WHERE p.sku = '{sku}' "
                    f"AND NOT EXISTS (SELECT 1 FROM inventories inv WHERE inv.product_id = p.id AND inv.branch_id = 2);\n\n")
            
    print(f"[✓] Đã xuất {len(products)} sản phẩm ra file SQL: {filepath}")

def main():
    print("=" * 68)
    print("      TOOL CÀO DỮ LIỆU CELLPHONES MỞ RỘNG - DỰ ÁN TECHSTORE")
    print("=" * 68)
    
    # Hỗ trợ tham số dòng lệnh nếu truyền: py crawl_cellphones.py [category] [limit]
    category_choice = 'all'
    limit_products = 50
    
    if len(sys.argv) >= 2:
        category_choice = sys.argv[1].lower()
    if len(sys.argv) >= 3:
        try:
            limit_products = int(sys.argv[2])
        except ValueError:
            limit_products = 50
            
    # Nếu chạy trực tiếp không có tham số dòng lệnh, mở menu tương tác
    if len(sys.argv) < 2 and sys.stdin.isatty():
        print("DANH SÁCH DANH MỤC HỖ TRỢ:")
        print("  1. Tất cả (All - Cào đầy đủ mọi danh mục, chia đều dữ liệu)")
        print("  2. Điện thoại (Mobile - iPhone, Samsung, Xiaomi, Oppo...)")
        print("  3. Laptop (MacBook, Dell, Asus, Lenovo, Acer, MSI, HP...)")
        print("  4. Máy tính bảng (Tablet - iPad, Galaxy Tab, Poco Pad...)")
        print("  5. Thiết bị âm thanh (Audio - Tai nghe bluetooth, Loa di động...)")
        print("  6. Phụ kiện (Accessories - Pin dự phòng, Cáp sạc, Chuột, Bàn phím...)")
        print("  7. Đồng hồ thông minh (Smartwatch - Thể thao, đo sức khỏe, nghe gọi...)")
        print("  8. Màn hình máy tính (Monitors - LG, Dell, Samsung, Asus...)")
        print("-" * 68)
        
        choice_map = {
            '1': 'all',
            '2': 'mobile',
            '3': 'laptop',
            '4': 'tablet',
            '5': 'audio',
            '6': 'accessories',
            '7': 'smartwatch',
            '8': 'monitors'
        }
        
        user_choice = input("Chọn danh mục cần cào [1-8] (Mặc định: 1): ").strip()
        category_choice = choice_map.get(user_choice, 'all')
        
        user_limit = input(f"Nhập số lượng sản phẩm cần lấy (Mặc định: 50): ").strip()
        if user_limit.isdigit() and int(user_limit) > 0:
            limit_products = int(user_limit)
            
    cat_display_names = {
        'all': 'Tất cả các danh mục',
        'mobile': 'Điện thoại',
        'laptop': 'Laptop',
        'tablet': 'Máy tính bảng',
        'audio': 'Thiết bị âm thanh (Tai nghe, Loa)',
        'accessories': 'Phụ kiện (Sạc cáp, Pin DP, Chuột phím)',
        'smartwatch': 'Đồng hồ thông minh',
        'monitors': 'Màn hình máy tính'
    }
    
    print("-" * 68)
    print(f"• Danh mục lựa chọn : {cat_display_names.get(category_choice, category_choice)}")
    print(f"• Số lượng mục tiêu : {limit_products} sản phẩm")
    print("-" * 68)
    
    # 1. Thu thập link sản phẩm
    links = get_product_links(category_choice, limit=limit_products)
    if not links:
        print("[!] Không tìm thấy sản phẩm nào. Vui lòng kiểm tra lại đường mạng hoặc danh mục.")
        return
        
    # 2. Phân tích chi tiết từng sản phẩm
    crawled_products = []
    print(f"[*] Bắt đầu cào thông tin chi tiết cho {len(links)} sản phẩm...")
    for idx, link in enumerate(links, 1):
        print(f"[{idx}/{len(links)}] Đang xử lý: {link}")
        item = parse_product_detail(link)
        if item:
            print(f"   -> [OK] {item['name'][:42]}... | {item['price']:,.0f} đ | Hãng: {item['brand_name']}")
            crawled_products.append(item)
        else:
            print(f"   -> [Bỏ qua - Không parse được thông tin]")
        time.sleep(1) # Nghỉ 1s tránh bị giới hạn tốc độ kết nối
        
    # 3. Xuất ra file JSON và SQL
    output_json = 'crawled_cellphones.json'
    output_sql = 'import_cellphones.sql'
    save_to_json(crawled_products, output_json)
    save_to_sql(crawled_products, output_sql)
    
    print("\n" + "=" * 68)
    print("🎉 HOÀN TẤT THÀNH CÔNG!")
    print(f"• Tổng sản phẩm đã cào : {len(crawled_products)}/{len(links)}")
    print(f"• File JSON dữ liệu   : {os.path.abspath(output_json)}")
    print(f"• File SQL nạp MySQL  : {os.path.abspath(output_sql)}")
    print(f"• Đồng bộ Cloudinary  : Chạy 'py sync_to_cloudinary.py' nếu bạn muốn đổi sang ảnh CDN!")
    print("=" * 68)

if __name__ == '__main__':
    main()
