import { AdminApi } from '../../js/api/admin-api.js';

let modal;
let onSaved;
let opening = false;

function setup() {
    if (modal) return;
    document.body.insertAdjacentHTML('beforeend', `
    <div class="modal fade" id="productEditor" tabindex="-1" aria-labelledby="productEditorTitle" aria-hidden="true">
      <div class="modal-dialog modal-lg modal-dialog-scrollable"><form class="modal-content" id="productEditorForm">
        <div class="modal-header"><h5 class="modal-title" id="productEditorTitle">Sản phẩm</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Đóng"></button></div>
        <div class="modal-body">
          <div class="alert alert-danger d-none" id="productEditorError" role="alert"></div>
          <input type="hidden" name="id">
          <div class="row g-3">
            <div class="col-12"><label class="form-label" for="pe-name">Tên sản phẩm</label><input id="pe-name" name="name" class="form-control" required maxlength="200"></div>
            <div class="col-md-6"><label class="form-label" for="pe-sku">SKU</label><input id="pe-sku" name="sku" class="form-control" required maxlength="50"></div>
            <div class="col-md-6"><label class="form-label" for="pe-slug">Slug (để trống để tự tạo)</label><input id="pe-slug" name="slug" class="form-control" maxlength="255"></div>
            <div class="col-md-6"><label class="form-label" for="pe-price">Giá bán (₫)</label><input id="pe-price" name="price" class="form-control" type="number" min="0.01" step="0.01" required></div>
            <div class="col-md-6"><label class="form-label" for="pe-cost">Giá vốn (₫)</label><input id="pe-cost" name="costPrice" class="form-control" type="number" min="0.01" step="0.01" required></div>
            <div class="col-md-6"><label class="form-label" for="pe-category">Danh mục</label><select id="pe-category" name="categoryId" class="form-select" required></select></div>
            <div class="col-md-6"><label class="form-label" for="pe-brand">Thương hiệu</label><select id="pe-brand" name="brandId" class="form-select" required></select></div>
            <div class="col-12"><label class="form-label" for="pe-status">Trạng thái</label><select id="pe-status" name="status" class="form-select"><option value="ACTIVE">Đang kinh doanh</option><option value="INACTIVE">Ngừng kinh doanh</option></select></div>
            <div class="col-12"><label class="form-label" for="pe-description">Mô tả</label><textarea id="pe-description" name="description" class="form-control" rows="3"></textarea></div>
            <div class="col-12"><label class="form-label" for="pe-specs">Thông số kỹ thuật</label><textarea id="pe-specs" name="specifications" class="form-control" rows="4" placeholder="Màn hình: 6.7 inch&#10;RAM: 8 GB"></textarea><div class="form-text">Nhập mỗi thông số một dòng hoặc giữ nguyên dữ liệu hiện có.</div></div>
            <div class="col-12"><label class="form-label" for="pe-images">Ảnh sản phẩm</label><textarea id="pe-images" name="images" class="form-control" rows="3" placeholder="https://example.com/product.jpg"></textarea><div class="form-text">Mỗi dòng một URL ảnh HTTP/HTTPS. Ảnh đầu tiên là ảnh chính; bỏ dòng để xóa ảnh.</div><div id="productImagePreview" class="d-flex flex-wrap gap-2 mt-2"></div></div>
          </div>
        </div>
        <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button><button type="submit" class="btn btn-primary">Lưu sản phẩm</button></div>
      </form></div>
    </div>`);
    const el = document.getElementById('productEditor');
    modal = new bootstrap.Modal(el);
    el.querySelector('form').addEventListener('submit', save);
    el.querySelector('[name="images"]').addEventListener('input', preview);
}

function imageUrls() {
    return document.getElementById('productEditorForm').elements.images.value.split(/\r?\n/).map(v => v.trim()).filter(Boolean);
}

function validImageUrl(value) {
    try { return ['http:', 'https:'].includes(new URL(value).protocol); } catch { return false; }
}

function preview() {
    const container = document.getElementById('productImagePreview');
    container.replaceChildren();
    imageUrls().filter(validImageUrl).forEach((url, index) => {
        const img = document.createElement('img');
        img.src = url;
        img.alt = index === 0 ? 'Ảnh chính' : `Ảnh ${index + 1}`;
        img.width = 72;
        img.height = 72;
        img.className = 'rounded border';
        img.style.objectFit = 'cover';
        container.append(img);
    });
}

export async function openProductEditor(id, saved) {
    if (opening) return;
    opening = true;
    try {
        setup();
        const results = await Promise.allSettled([
            AdminApi.getCategories(), AdminApi.getBrands(), id ? AdminApi.getProductById(id) : Promise.resolve({ data: {} })
        ]);
        const failure = results.find(r => r.status === 'rejected');
        if (failure) throw failure.reason;
        const [categories, brands, result] = results.map(r => r.value);
        const form = document.getElementById('productEditorForm');
        form.reset();
        const product = result.data;
        for (const [name, items] of [['categoryId', categories.data], ['brandId', brands.data]]) {
            const select = form.elements[name];
            select.replaceChildren(new Option('Chọn...', ''));
            (items || []).forEach(item => select.add(new Option(item.name, item.id)));
        }
        for (const key of ['id', 'name', 'sku', 'slug', 'price', 'costPrice', 'description', 'specifications']) {
            form.elements[key].value = product[key] ?? '';
        }
        form.elements.status.value = product.status || 'ACTIVE';
        form.elements.categoryId.value = product.category?.id ?? '';
        form.elements.brandId.value = product.brand?.id ?? '';
        form.elements.images.value = [...(product.images || [])].sort((a, b) => Number(b.isPrimary) - Number(a.isPrimary)).map(img => img.imageUrl).join('\n');
        document.getElementById('productEditorTitle').textContent = id ? 'Sửa sản phẩm' : 'Thêm sản phẩm';
        document.getElementById('productEditorError').classList.add('d-none');
        onSaved = saved;
        preview();
        modal.show();
    } finally { opening = false; }
}

async function save(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const button = form.querySelector('[type="submit"]');
    if (button.disabled) return;
    const errorBox = document.getElementById('productEditorError');
    errorBox.classList.add('d-none');
    button.disabled = true;
    try {
        const payload = Object.fromEntries(new FormData(form));
        const id = payload.id;
        delete payload.id;
        for (const key of ['name', 'sku', 'slug']) payload[key] = payload[key].trim();
        for (const key of ['price', 'costPrice', 'categoryId', 'brandId']) payload[key] = Number(payload[key]);
        const urls = imageUrls();
        if (urls.some(url => !validImageUrl(url))) throw new Error('URL ảnh phải bắt đầu bằng http:// hoặc https://.');
        payload.images = urls.map((imageUrl, displayOrder) => ({ imageUrl, displayOrder, isPrimary: displayOrder === 0 }));
        await (id ? AdminApi.updateProduct(id, payload) : AdminApi.createProduct(payload));
        modal.hide();
    } catch (error) {
        errorBox.textContent = Object.values(error.data?.errors || {}).join(' • ') || error.message;
        errorBox.classList.remove('d-none');
        return;
    } finally { button.disabled = false; }
    try { await onSaved?.(); } catch { alert('Đã lưu sản phẩm. Vui lòng tải lại danh sách.'); }
}
