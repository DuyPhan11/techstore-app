import { ProductApi } from "../../js/api/product-api.js";
import { updateCartBadge } from "../../js/api/cart-api.js";
import { renderProductCard } from "../../js/components/product-card.js";
import { isAuthenticated, isAdmin, isStaff, getCurrentUser, logout } from "../../js/auth/auth.js";

// Application state
const state = {
    keyword: "",
    categoryId: null,
    brandId: null,
    minPrice: null,
    maxPrice: null,
    sortBy: "createdAt",
    sortDir: "desc",
    page: 0,
    size: 12,
    totalPages: 0,
    totalElements: 0,
    categories: [],
    brands: [],
    isLoading: false
};

// DOM Elements
const dom = {
    authContainer: document.getElementById("nav-auth-container"),
    staffActionContainer: document.getElementById("staff-action-container"),
    btnOpenCreateModal: document.getElementById("btn-open-create-modal"),
    filterKeyword: document.getElementById("filter-keyword"),
    categoryFilterList: document.getElementById("category-filter-list"),
    brandFilterList: document.getElementById("brand-filter-list"),
    filterMinPrice: document.getElementById("filter-min-price"),
    filterMaxPrice: document.getElementById("filter-max-price"),
    btnApplyPrice: document.getElementById("btn-apply-price"),
    btnClearFilters: document.getElementById("btn-clear-filters"),
    btnEmptyReset: document.getElementById("btn-empty-reset"),
    sortSelect: document.getElementById("sort-select"),
    totalCount: document.getElementById("total-products-count"),
    activeChips: document.getElementById("active-filter-chips"),
    loadingState: document.getElementById("loading-state"),
    errorState: document.getElementById("error-state"),
    errorMessage: document.getElementById("error-message"),
    btnRetry: document.getElementById("btn-retry"),
    emptyState: document.getElementById("empty-state"),
    productGrid: document.getElementById("product-grid"),
    paginationContainer: document.getElementById("pagination-container"),
    paginationList: document.getElementById("pagination-list"),
    // Modal
    productModalEl: document.getElementById("productModal"),
    productForm: document.getElementById("product-form"),
    modalTitle: document.getElementById("productModalLabel"),
    modalProductId: document.getElementById("modal-product-id"),
    modalName: document.getElementById("modal-name"),
    modalSku: document.getElementById("modal-sku"),
    modalCategory: document.getElementById("modal-category"),
    modalBrand: document.getElementById("modal-brand"),
    modalPrice: document.getElementById("modal-price"),
    modalCostPrice: document.getElementById("modal-cost-price"),
    modalImage: document.getElementById("modal-image"),
    modalDescription: document.getElementById("modal-description"),
    modalSpecifications: document.getElementById("modal-specifications"),
    modalAlert: document.getElementById("modal-alert"),
    saveSpinner: document.getElementById("save-spinner")
};

let productModal = null;
let searchDebounceTimer = null;

// Initialize
document.addEventListener("DOMContentLoaded", async () => {
    if (dom.productModalEl && window.bootstrap) {
        productModal = new window.bootstrap.Modal(dom.productModalEl);
    }

    renderNavbar();
    readUrlParams();
    setupEventListeners();

    await loadFilters();
    await loadProducts();
});

// Render Navbar Auth State
function renderNavbar() {
    if (!dom.authContainer) return;

    if (isAuthenticated()) {
        const user = getCurrentUser();
        const displayName = user?.fullName || user?.email || "Tài khoản";
        const canManage = isAdmin() || isStaff();

        if (canManage && dom.staffActionContainer) {
            dom.staffActionContainer.style.setProperty("display", "flex", "important");
        }

        dom.authContainer.innerHTML = `
            <a href="../cart/cart.html" class="btn btn-outline-primary position-relative">
                <i class="bi bi-cart3"></i>
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" id="cart-badge">
                    0
                </span>
            </a>
            <div class="dropdown">
                <button class="btn btn-light border dropdown-toggle d-flex align-items-center gap-2" type="button" data-bs-toggle="dropdown">
                    <i class="bi bi-person-circle text-primary fs-5"></i>
                    <span class="fw-semibold">${escapeHtml(displayName)}</span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-sm">
                    <li><h6 class="dropdown-header">Xin chào, ${escapeHtml(displayName)}</h6></li>
                    <li><a class="dropdown-item" href="../orders/my-orders.html"><i class="bi bi-bag me-2"></i>Đơn mua của tôi</a></li>
                    ${isAdmin() ? '<li><a class="dropdown-item text-primary" href="../admin/admin-orders.html"><i class="bi bi-speedometer2 me-2"></i>Quản trị đơn hàng</a></li>' : ''}
                    <li><hr class="dropdown-divider"></li>
                    <li><button class="dropdown-item text-danger" id="btn-logout"><i class="bi bi-box-arrow-right me-2"></i>Đăng xuất</button></li>
                </ul>
            </div>
        `;

        document.getElementById("btn-logout")?.addEventListener("click", () => {
            logout();
            window.location.reload();
        });

        updateCartBadge();
    }
}

// Read parameters from URL query string
function readUrlParams() {
    const params = new URLSearchParams(window.location.search);
    if (params.has("keyword")) {
        state.keyword = params.get("keyword").trim();
        if (dom.filterKeyword) dom.filterKeyword.value = state.keyword;
    }
    if (params.has("categoryId")) {
        state.categoryId = Number(params.get("categoryId")) || null;
    }
    if (params.has("brandId")) {
        state.brandId = Number(params.get("brandId")) || null;
    }
    if (params.has("minPrice")) {
        state.minPrice = Number(params.get("minPrice")) || null;
        if (dom.filterMinPrice) dom.filterMinPrice.value = state.minPrice;
    }
    if (params.has("maxPrice")) {
        state.maxPrice = Number(params.get("maxPrice")) || null;
        if (dom.filterMaxPrice) dom.filterMaxPrice.value = state.maxPrice;
    }
    if (params.has("sort")) {
        const sortVal = params.get("sort");
        const parts = sortVal.split(",");
        if (parts.length === 2) {
            state.sortBy = parts[0];
            state.sortDir = parts[1];
            if (dom.sortSelect) dom.sortSelect.value = sortVal;
        }
    }
    if (params.has("page")) {
        state.page = Math.max(Number(params.get("page")) || 0, 0);
    }
}

// Sync current state to URL
function syncUrlParams() {
    const params = new URLSearchParams();
    if (state.keyword) params.set("keyword", state.keyword);
    if (state.categoryId) params.set("categoryId", state.categoryId);
    if (state.brandId) params.set("brandId", state.brandId);
    if (state.minPrice) params.set("minPrice", state.minPrice);
    if (state.maxPrice) params.set("maxPrice", state.maxPrice);
    if (state.sortBy && state.sortDir) params.set("sort", `${state.sortBy},${state.sortDir}`);
    if (state.page > 0) params.set("page", state.page);

    const queryString = params.toString();
    const newUrl = window.location.pathname + (queryString ? "?" + queryString : "");
    window.history.replaceState({}, "", newUrl);
}

// Setup Event Listeners
function setupEventListeners() {
    // Keyword search with debounce
    dom.filterKeyword?.addEventListener("input", (e) => {
        clearTimeout(searchDebounceTimer);
        searchDebounceTimer = setTimeout(() => {
            state.keyword = e.target.value.trim();
            state.page = 0;
            syncUrlParams();
            loadProducts();
        }, 400);
    });

    // Price range apply
    dom.btnApplyPrice?.addEventListener("click", () => {
        const minVal = dom.filterMinPrice?.value ? Number(dom.filterMinPrice.value) : null;
        const maxVal = dom.filterMaxPrice?.value ? Number(dom.filterMaxPrice.value) : null;
        state.minPrice = minVal;
        state.maxPrice = maxVal;
        state.page = 0;
        syncUrlParams();
        loadProducts();
    });

    // Clear filters
    dom.btnClearFilters?.addEventListener("click", clearAllFilters);
    dom.btnEmptyReset?.addEventListener("click", clearAllFilters);

    // Sort selection change
    dom.sortSelect?.addEventListener("change", (e) => {
        const [sortBy, sortDir] = e.target.value.split(",");
        state.sortBy = sortBy;
        state.sortDir = sortDir;
        state.page = 0;
        syncUrlParams();
        loadProducts();
    });

    // Retry button on error
    dom.btnRetry?.addEventListener("click", () => {
        loadProducts();
    });

    // Staff/Admin Open Create Modal
    dom.btnOpenCreateModal?.addEventListener("click", () => {
        openCreateModal();
    });

    // Form submit in Modal
    dom.productForm?.addEventListener("submit", handleSaveProduct);
}

function clearAllFilters() {
    state.keyword = "";
    state.categoryId = null;
    state.brandId = null;
    state.minPrice = null;
    state.maxPrice = null;
    state.page = 0;

    if (dom.filterKeyword) dom.filterKeyword.value = "";
    if (dom.filterMinPrice) dom.filterMinPrice.value = "";
    if (dom.filterMaxPrice) dom.filterMaxPrice.value = "";

    // Reset radio/checkbox selections
    document.querySelectorAll("input[name='categoryFilter']").forEach(r => r.checked = (r.value === "all"));
    document.querySelectorAll("input[name='brandFilter']").forEach(r => r.checked = (r.value === "all"));

    syncUrlParams();
    loadProducts();
}

// Load Categories & Brands
async function loadFilters() {
    try {
        const [catRes, brandRes] = await Promise.all([
            ProductApi.getCategories("ACTIVE").catch(() => ({ data: [] })),
            ProductApi.getBrands("ACTIVE").catch(() => ({ data: [] }))
        ]);

        state.categories = catRes?.data || [];
        state.brands = brandRes?.data || [];

        renderCategoryFilter(state.categories);
        renderBrandFilter(state.brands);
        populateModalDropdowns(state.categories, state.brands);
    } catch (err) {
        console.error("Lỗi khi tải danh mục và thương hiệu:", err);
    }
}

function renderCategoryFilter(categories) {
    if (!dom.categoryFilterList) return;

    let html = `
        <div class="form-check">
            <input class="form-check-input category-radio" type="radio" name="categoryFilter" id="cat-all" value="all" ${!state.categoryId ? "checked" : ""}>
            <label class="form-check-label small" for="cat-all">Tất cả danh mục</label>
        </div>
    `;

    categories.forEach(cat => {
        const isChecked = state.categoryId === cat.id;
        html += `
            <div class="form-check">
                <input class="form-check-input category-radio" type="radio" name="categoryFilter" id="cat-${cat.id}" value="${cat.id}" ${isChecked ? "checked" : ""}>
                <label class="form-check-label small" for="cat-${cat.id}">${escapeHtml(cat.name)}</label>
            </div>
        `;
    });

    dom.categoryFilterList.innerHTML = html;

    dom.categoryFilterList.querySelectorAll(".category-radio").forEach(radio => {
        radio.addEventListener("change", (e) => {
            const val = e.target.value;
            state.categoryId = val === "all" ? null : Number(val);
            state.page = 0;
            syncUrlParams();
            loadProducts();
        });
    });
}

function renderBrandFilter(brands) {
    if (!dom.brandFilterList) return;

    let html = `
        <div class="form-check">
            <input class="form-check-input brand-radio" type="radio" name="brandFilter" id="brand-all" value="all" ${!state.brandId ? "checked" : ""}>
            <label class="form-check-label small" for="brand-all">Tất cả thương hiệu</label>
        </div>
    `;

    brands.forEach(b => {
        const isChecked = state.brandId === b.id;
        html += `
            <div class="form-check">
                <input class="form-check-input brand-radio" type="radio" name="brandFilter" id="brand-${b.id}" value="${b.id}" ${isChecked ? "checked" : ""}>
                <label class="form-check-label small" for="brand-${b.id}">${escapeHtml(b.name)}</label>
            </div>
        `;
    });

    dom.brandFilterList.innerHTML = html;

    dom.brandFilterList.querySelectorAll(".brand-radio").forEach(radio => {
        radio.addEventListener("change", (e) => {
            const val = e.target.value;
            state.brandId = val === "all" ? null : Number(val);
            state.page = 0;
            syncUrlParams();
            loadProducts();
        });
    });
}

function populateModalDropdowns(categories, brands) {
    if (dom.modalCategory) {
        dom.modalCategory.innerHTML = '<option value="">Chọn danh mục...</option>' +
            categories.map(c => `<option value="${c.id}">${escapeHtml(c.name)}</option>`).join("");
    }
    if (dom.modalBrand) {
        dom.modalBrand.innerHTML = '<option value="">Chọn thương hiệu...</option>' +
            brands.map(b => `<option value="${b.id}">${escapeHtml(b.name)}</option>`).join("");
    }
}

// Load Products
async function loadProducts() {
    setLoading(true);
    hideError();
    hideEmpty();

    renderActiveChips();

    try {
        const params = {
            page: state.page,
            size: state.size,
            sortBy: state.sortBy,
            sortDir: state.sortDir
        };
        if (state.keyword) params.keyword = state.keyword;
        if (state.categoryId) params.categoryId = state.categoryId;
        if (state.brandId) params.brandId = state.brandId;
        if (state.minPrice !== null && !isNaN(state.minPrice)) params.minPrice = state.minPrice;
        if (state.maxPrice !== null && !isNaN(state.maxPrice)) params.maxPrice = state.maxPrice;

        const response = await ProductApi.getProducts(params);
        const pageData = response?.data;

        const items = pageData?.content || [];
        state.totalPages = pageData?.totalPages || 0;
        state.totalElements = pageData?.totalElements || 0;

        if (dom.totalCount) dom.totalCount.textContent = state.totalElements;

        if (items.length === 0) {
            showEmpty();
            if (dom.productGrid) dom.productGrid.innerHTML = "";
            renderPagination(0, 0);
        } else {
            renderProductGrid(items);
            renderPagination(pageData.pageNumber, pageData.totalPages);
        }
    } catch (err) {
        console.error("Lỗi khi tải sản phẩm:", err);
        showError(err.message || "Đã xảy ra lỗi khi lấy danh sách sản phẩm.");
    } finally {
        setLoading(false);
    }
}

function renderProductGrid(products) {
    if (!dom.productGrid) return;
    dom.productGrid.innerHTML = "";

    products.forEach(product => {
        const cardNode = renderProductCard(product, {
            detailUrlPrefix: window.location.pathname.endsWith(".html") ? "./product-detail.html" : "./product-detail"
        });
        dom.productGrid.appendChild(cardNode);
    });

    // Attach staff action events (edit, delete)
    dom.productGrid.querySelectorAll(".btn-edit-product").forEach(btn => {
        btn.addEventListener("click", (e) => {
            e.preventDefault();
            const id = btn.getAttribute("data-id");
            openEditModal(id);
        });
    });

    dom.productGrid.querySelectorAll(".btn-delete-product").forEach(btn => {
        btn.addEventListener("click", (e) => {
            e.preventDefault();
            const id = btn.getAttribute("data-id");
            const name = btn.getAttribute("data-name");
            handleDeleteProduct(id, name);
        });
    });
}

function renderActiveChips() {
    if (!dom.activeChips) return;
    const chips = [];

    if (state.keyword) {
        chips.push(`Từ khóa: "${escapeHtml(state.keyword)}"`);
    }
    if (state.categoryId) {
        const cat = state.categories.find(c => c.id === state.categoryId);
        if (cat) chips.push(`Danh mục: ${escapeHtml(cat.name)}`);
    }
    if (state.brandId) {
        const brand = state.brands.find(b => b.id === state.brandId);
        if (brand) chips.push(`Thương hiệu: ${escapeHtml(brand.name)}`);
    }
    if (state.minPrice || state.maxPrice) {
        const minStr = state.minPrice ? Number(state.minPrice).toLocaleString("vi-VN") + "đ" : "0đ";
        const maxStr = state.maxPrice ? Number(state.maxPrice).toLocaleString("vi-VN") + "đ" : "∞";
        chips.push(`Giá: ${minStr} - ${maxStr}`);
    }

    if (chips.length === 0) {
        dom.activeChips.innerHTML = "";
        return;
    }

    dom.activeChips.innerHTML = chips.map(label => `
        <span class="badge bg-white text-dark border shadow-sm py-2 px-3 small d-inline-flex align-items-center gap-2">
            ${label}
        </span>
    `).join("");
}

function renderPagination(currentPage, totalPages) {
    if (!dom.paginationContainer || !dom.paginationList) return;

    if (totalPages <= 1) {
        dom.paginationContainer.style.display = "none";
        return;
    }

    dom.paginationContainer.style.display = "flex";
    let html = "";

    // Previous button
    html += `
        <li class="page-item ${currentPage === 0 ? "disabled" : ""}">
            <a class="page-link" href="#" data-page="${currentPage - 1}" aria-label="Previous">
                <span aria-hidden="true">&laquo;</span>
            </a>
        </li>
    `;

    for (let i = 0; i < totalPages; i++) {
        // Show window around current page
        if (i === 0 || i === totalPages - 1 || Math.abs(i - currentPage) <= 2) {
            html += `
                <li class="page-item ${i === currentPage ? "active" : ""}">
                    <a class="page-link" href="#" data-page="${i}">${i + 1}</a>
                </li>
            `;
        } else if (Math.abs(i - currentPage) === 3) {
            html += `<li class="page-item disabled"><span class="page-link">...</span></li>`;
        }
    }

    // Next button
    html += `
        <li class="page-item ${currentPage >= totalPages - 1 ? "disabled" : ""}">
            <a class="page-link" href="#" data-page="${currentPage + 1}" aria-label="Next">
                <span aria-hidden="true">&raquo;</span>
            </a>
        </li>
    `;

    dom.paginationList.innerHTML = html;

    dom.paginationList.querySelectorAll("a.page-link").forEach(link => {
        link.addEventListener("click", (e) => {
            e.preventDefault();
            const targetPage = Number(link.getAttribute("data-page"));
            if (!isNaN(targetPage) && targetPage >= 0 && targetPage < totalPages && targetPage !== currentPage) {
                state.page = targetPage;
                syncUrlParams();
                loadProducts();
                window.scrollTo({ top: 0, behavior: "smooth" });
            }
        });
    });
}

// UI States
function setLoading(loading) {
    state.isLoading = loading;
    if (dom.loadingState) dom.loadingState.style.display = loading ? "flex" : "none";
    if (dom.productGrid) dom.productGrid.style.display = loading ? "none" : "flex";
}

function showError(msg) {
    if (dom.errorState) {
        dom.errorState.classList.remove("d-none");
        dom.errorState.classList.add("d-flex");
        if (dom.errorMessage) dom.errorMessage.textContent = msg;
    }
    if (dom.productGrid) dom.productGrid.innerHTML = "";
    if (dom.paginationContainer) dom.paginationContainer.classList.add("d-none");
}

function hideError() {
    if (dom.errorState) {
        dom.errorState.classList.add("d-none");
        dom.errorState.classList.remove("d-flex");
    }
}

function showEmpty() {
    if (dom.emptyState) dom.emptyState.style.display = "block";
}

function hideEmpty() {
    if (dom.emptyState) dom.emptyState.style.display = "none";
}

// Staff / Admin CRUD Actions
function openCreateModal() {
    dom.productForm?.reset();
    if (dom.modalProductId) dom.modalProductId.value = "";
    if (dom.modalTitle) dom.modalTitle.textContent = "Thêm sản phẩm mới";
    if (dom.modalAlert) dom.modalAlert.classList.add("d-none");
    productModal?.show();
}

async function openEditModal(productId) {
    try {
        const res = await ProductApi.getProductById(productId);
        const product = res?.data;
        if (!product) return;

        if (dom.modalProductId) dom.modalProductId.value = product.id;
        if (dom.modalName) dom.modalName.value = product.name || "";
        if (dom.modalSku) dom.modalSku.value = product.sku || "";
        if (dom.modalCategory) dom.modalCategory.value = product.category?.id || "";
        if (dom.modalBrand) dom.modalBrand.value = product.brand?.id || "";
        if (dom.modalPrice) dom.modalPrice.value = product.price || "";
        if (dom.modalCostPrice) dom.modalCostPrice.value = product.costPrice || product.price || "";
        if (dom.modalDescription) dom.modalDescription.value = product.description || "";
        if (dom.modalSpecifications) dom.modalSpecifications.value = product.specifications || "";

        const primaryImg = product.images?.find(i => i.isPrimary)?.imageUrl || product.images?.[0]?.imageUrl || "";
        if (dom.modalImage) dom.modalImage.value = primaryImg;

        if (dom.modalTitle) dom.modalTitle.textContent = "Chỉnh sửa sản phẩm: " + product.name;
        if (dom.modalAlert) dom.modalAlert.classList.add("d-none");

        productModal?.show();
    } catch (err) {
        alert("Không thể tải thông tin sản phẩm để sửa: " + err.message);
    }
}

async function handleSaveProduct(e) {
    e.preventDefault();
    const id = dom.modalProductId?.value;
    const isEdit = !!id;

    const payload = {
        name: dom.modalName?.value.trim(),
        sku: dom.modalSku?.value.trim(),
        categoryId: Number(dom.modalCategory?.value),
        brandId: Number(dom.modalBrand?.value),
        price: Number(dom.modalPrice?.value),
        costPrice: Number(dom.modalCostPrice?.value),
        description: dom.modalDescription?.value.trim(),
        specifications: dom.modalSpecifications?.value.trim()
    };

    const imageUrl = dom.modalImage?.value.trim();
    if (imageUrl) {
        payload.images = [
            {
                imageUrl: imageUrl,
                isPrimary: true,
                displayOrder: 1
            }
        ];
    }

    if (dom.saveSpinner) dom.saveSpinner.classList.remove("d-none");
    if (dom.modalAlert) dom.modalAlert.classList.add("d-none");

    try {
        if (isEdit) {
            await ProductApi.updateProduct(id, payload);
        } else {
            await ProductApi.createProduct(payload);
        }
        productModal?.hide();
        loadProducts();
    } catch (err) {
        if (dom.modalAlert) {
            dom.modalAlert.textContent = err.message || "Lỗi lưu sản phẩm";
            dom.modalAlert.classList.remove("d-none");
        }
    } finally {
        if (dom.saveSpinner) dom.saveSpinner.classList.add("d-none");
    }
}

async function handleDeleteProduct(id, name) {
    if (!confirm(`Bạn có chắc muốn ẩn/xóa sản phẩm "${name}" không?`)) {
        return;
    }
    try {
        await ProductApi.deleteProduct(id);
        loadProducts();
    } catch (err) {
        alert("Lỗi khi xóa sản phẩm: " + err.message);
    }
}

function escapeHtml(str) {
    if (!str) return "";
    return String(str)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}
