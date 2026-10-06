import { ProductApi } from "../../js/api/product-api.js";
import { ReviewApi } from "../../js/api/review-api.js";
import { CartApi, updateCartBadge } from "../../js/api/cart-api.js";
import { formatCurrency } from "../../js/components/product-card.js";
import { isAuthenticated, isAdmin, getCurrentUser, logout } from "../../js/auth/auth.js";

// DOM Elements
const dom = {
    authContainer: document.getElementById("nav-auth-container"),
    breadcrumbName: document.getElementById("breadcrumb-product-name"),
    loadingState: document.getElementById("detail-loading"),
    errorState: document.getElementById("detail-error"),
    errorTitle: document.getElementById("error-title"),
    errorDesc: document.getElementById("error-desc"),
    detailView: document.getElementById("product-detail-view"),
    // Product info
    mainImage: document.getElementById("main-product-image"),
    thumbnailStrip: document.getElementById("gallery-thumbnail-strip"),
    stockBadge: document.getElementById("detail-stock-badge"),
    categoryBadge: document.getElementById("detail-category-badge"),
    brandBadge: document.getElementById("detail-brand-badge"),
    productName: document.getElementById("detail-product-name"),
    sku: document.getElementById("detail-sku"),
    price: document.getElementById("detail-price"),
    stockText: document.getElementById("detail-stock-text"),
    qtyInput: document.getElementById("qty-input"),
    btnQtyMinus: document.getElementById("btn-qty-minus"),
    btnQtyPlus: document.getElementById("btn-qty-plus"),
    maxStockHint: document.getElementById("max-stock-hint"),
    btnAddToCart: document.getElementById("btn-add-to-cart"),
    btnBuyNow: document.getElementById("btn-buy-now"),
    description: document.getElementById("detail-description"),
    specificationsTbody: document.getElementById("specifications-tbody")
};

let currentProduct = null;

// Initialize
document.addEventListener("DOMContentLoaded", async () => {
    renderNavbar();
    setupQuantityEvents();

    const urlParams = new URLSearchParams(window.location.search);
    let productId = urlParams.get("id");
    let productSlug = urlParams.get("slug");

    if (!productId && !productSlug) {
        const cachedId = localStorage.getItem("techstore_last_viewed_product_id");
        if (cachedId) {
            productId = cachedId;
            try {
                const newUrl = window.location.pathname + "?id=" + productId;
                window.history.replaceState({}, "", newUrl);
            } catch (e) {}
        }
    }

    if (!productId && !productSlug) {
        showError("Không tìm thấy sản phẩm", "Đường dẫn không hợp lệ hoặc thiếu mã sản phẩm.");
        return;
    }

    if (productId) {
        try {
            localStorage.setItem("techstore_last_viewed_product_id", productId);
        } catch (e) {}
    }

    await loadProductDetail(productId, productSlug);
});

// Render Navbar Auth State
function renderNavbar() {
    if (!dom.authContainer) return;

    if (isAuthenticated()) {
        const user = getCurrentUser();
        const displayName = user?.fullName || user?.email || "Tài khoản";

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

// Fetch Product Detail
async function loadProductDetail(id, slug) {
    setLoading(true);
    hideError();

    try {
        let response;
        if (id) {
            response = await ProductApi.getProductById(id);
        } else {
            response = await ProductApi.getProductBySlug(slug);
        }

        currentProduct = response?.data;
        if (!currentProduct) {
            showError("Không tìm thấy sản phẩm", "Sản phẩm không tồn tại trong hệ thống.");
            return;
        }

        renderProduct(currentProduct);
        await initReviews(currentProduct.id);
    } catch (err) {
        console.error("Lỗi khi tải chi tiết sản phẩm:", err);
        showError("Không thể tải thông tin sản phẩm", err.message || "Lỗi kết nối máy chủ.");
    } finally {
        setLoading(false);
    }
}

// Render Product Data to DOM
function renderProduct(product) {
    document.title = `${product.name} - TechStore`;
    if (dom.breadcrumbName) dom.breadcrumbName.textContent = product.name;

    // Header & Badges
    if (dom.productName) dom.productName.textContent = product.name;
    if (dom.sku) dom.sku.textContent = product.sku;
    if (dom.categoryBadge) dom.categoryBadge.textContent = product.category?.name || "Danh mục";
    if (dom.brandBadge) dom.brandBadge.textContent = product.brand?.name || "Thương hiệu";
    if (dom.price) dom.price.textContent = formatCurrency(product.price);

    // Stock
    const stock = product.totalStock || 0;
    const hasStock = stock > 0;

    if (dom.stockBadge) {
        dom.stockBadge.className = `badge position-absolute top-0 start-0 m-3 px-3 py-2 fs-6 ${hasStock ? "bg-success" : "bg-secondary"}`;
        dom.stockBadge.textContent = hasStock ? "Còn hàng" : "Hết hàng";
    }

    if (dom.stockText) {
        dom.stockText.innerHTML = hasStock
            ? `<span class="text-success fw-bold"><i class="bi bi-check-circle me-1"></i>Còn hàng (${stock} sản phẩm sẵn có)</span>`
            : `<span class="text-danger fw-bold"><i class="bi bi-x-circle me-1"></i>Tạm hết hàng</span>`;
    }

    if (dom.maxStockHint) {
        dom.maxStockHint.textContent = hasStock ? `(Tối đa ${stock})` : "";
    }

    // Disable purchase if out of stock
    if (dom.qtyInput) {
        dom.qtyInput.max = stock;
        dom.qtyInput.disabled = !hasStock;
        dom.qtyInput.value = hasStock ? 1 : 0;
    }
    if (dom.btnQtyMinus) dom.btnQtyMinus.disabled = !hasStock;
    if (dom.btnQtyPlus) dom.btnQtyPlus.disabled = !hasStock;
    if (dom.btnAddToCart) dom.btnAddToCart.disabled = !hasStock;
    if (dom.btnBuyNow) dom.btnBuyNow.disabled = !hasStock;

    // Gallery
    renderGallery(product.images);

    // Description
    if (dom.description) {
        dom.description.textContent = product.description || "Chưa có mô tả chi tiết cho sản phẩm này.";
    }

    // Specifications
    renderSpecifications(product.specifications);

    // Show View
    if (dom.detailView) dom.detailView.style.display = "block";
}

// Render Gallery with thumbnails
function renderGallery(images = []) {
    if (!dom.mainImage) return;

    const fallbackImg = "https://placehold.co/600x450?text=No+Image";
    const imgList = (images && images.length > 0)
        ? images
        : [{ imageUrl: fallbackImg, isPrimary: true }];

    const primaryImgObj = imgList.find(i => i.isPrimary) || imgList[0];
    dom.mainImage.src = primaryImgObj.imageUrl;
    dom.mainImage.onerror = () => { dom.mainImage.src = fallbackImg; };

    if (!dom.thumbnailStrip) return;
    dom.thumbnailStrip.innerHTML = "";

    if (imgList.length > 1) {
        imgList.forEach((img, idx) => {
            const thumb = document.createElement("img");
            thumb.src = img.imageUrl;
            thumb.className = `gallery-thumbnail shadow-sm ${img.imageUrl === primaryImgObj.imageUrl ? "active" : ""}`;
            thumb.alt = `Thumbnail ${idx + 1}`;
            thumb.onerror = () => { thumb.src = fallbackImg; };

            thumb.addEventListener("click", () => {
                dom.mainImage.src = img.imageUrl;
                dom.thumbnailStrip.querySelectorAll(".gallery-thumbnail").forEach(t => t.classList.remove("active"));
                thumb.classList.add("active");
            });

            dom.thumbnailStrip.appendChild(thumb);
        });
    }
}

// Render Specifications Table
function renderSpecifications(specString) {
    if (!dom.specificationsTbody) return;
    dom.specificationsTbody.innerHTML = "";

    if (!specString || !specString.trim()) {
        dom.specificationsTbody.innerHTML = '<tr><td colspan="2" class="text-muted text-center py-3">Chưa có thông số kỹ thuật</td></tr>';
        return;
    }

    let specsObj = null;
    try {
        specsObj = JSON.parse(specString);
    } catch {
        // Not JSON, display as line items
        const lines = specString.split("\n");
        lines.forEach(line => {
            const parts = line.split(":");
            if (parts.length >= 2) {
                const tr = document.createElement("tr");
                tr.innerHTML = `<th>${escapeHtml(parts[0].trim())}</th><td>${escapeHtml(parts.slice(1).join(":").trim())}</td>`;
                dom.specificationsTbody.appendChild(tr);
            } else if (line.trim()) {
                const tr = document.createElement("tr");
                tr.innerHTML = `<td colspan="2">${escapeHtml(line.trim())}</td>`;
                dom.specificationsTbody.appendChild(tr);
            }
        });
        return;
    }

    if (specsObj && typeof specsObj === "object") {
        Object.entries(specsObj).forEach(([key, val]) => {
            const tr = document.createElement("tr");
            tr.innerHTML = `<th>${escapeHtml(key)}</th><td>${escapeHtml(val)}</td>`;
            dom.specificationsTbody.appendChild(tr);
        });
    }
}

// Setup Quantity Increment / Decrement
function setupQuantityEvents() {
    dom.btnQtyMinus?.addEventListener("click", () => {
        let val = Number(dom.qtyInput?.value) || 1;
        if (val > 1) {
            dom.qtyInput.value = val - 1;
        }
    });

    dom.btnQtyPlus?.addEventListener("click", () => {
        let val = Number(dom.qtyInput?.value) || 1;
        const max = Number(dom.qtyInput?.max) || 99;
        if (val < max) {
            dom.qtyInput.value = val + 1;
        }
    });

    dom.qtyInput?.addEventListener("change", () => {
        let val = Number(dom.qtyInput.value);
        const max = Number(dom.qtyInput.max) || 99;
        if (isNaN(val) || val < 1) val = 1;
        if (val > max) val = max;
        dom.qtyInput.value = val;
    });

    // Add to cart click
    dom.btnAddToCart?.addEventListener("click", async () => {
        if (!isAuthenticated()) {
            if (confirm("Bạn cần đăng nhập để thêm sản phẩm vào giỏ hàng. Chuyển đến trang Đăng nhập ngay?")) {
                window.location.href = `../auth/login.html?redirect=${encodeURIComponent(window.location.href)}`;
            }
            return;
        }

        const qty = Number(dom.qtyInput?.value) || 1;
        const btn = dom.btnAddToCart;
        const originalHtml = btn.innerHTML;

        try {
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status"></span> Đang thêm...';
            
            await CartApi.addToCart(currentProduct.id, qty);
            await updateCartBadge();
            
            btn.className = "btn btn-success btn-lg flex-grow-1 py-3";
            btn.innerHTML = '<i class="bi bi-check-circle me-2"></i> Đã thêm vào giỏ!';

            setTimeout(() => {
                btn.className = "btn btn-primary btn-lg flex-grow-1 py-3";
                btn.innerHTML = originalHtml;
                btn.disabled = false;
            }, 1800);
        } catch (err) {
            btn.disabled = false;
            btn.innerHTML = originalHtml;
            alert(err.message || "Không thể thêm sản phẩm vào giỏ hàng.");
        }
    });

    dom.btnBuyNow?.addEventListener("click", async () => {
        if (!isAuthenticated()) {
            window.location.href = `../auth/login.html?redirect=${encodeURIComponent(window.location.href)}`;
            return;
        }

        const qty = Number(dom.qtyInput?.value) || 1;
        try {
            await CartApi.addToCart(currentProduct.id, qty);
            await updateCartBadge();
            window.location.href = "../cart/cart.html";
        } catch (err) {
            alert(err.message || "Không thể thêm sản phẩm để mua ngay.");
        }
    });
}

// UI States
function setLoading(loading) {
    if (dom.loadingState) dom.loadingState.style.display = loading ? "block" : "none";
    if (dom.detailView && loading) dom.detailView.style.display = "none";
}

function showError(title, desc) {
    setLoading(false);
    if (dom.breadcrumbName) dom.breadcrumbName.textContent = title || "Lỗi";
    if (dom.errorState) {
        dom.errorState.style.display = "block";
        if (dom.errorTitle) dom.errorTitle.textContent = title;
        if (dom.errorDesc) dom.errorDesc.textContent = desc;
    }
    if (dom.detailView) dom.detailView.style.display = "none";
}

function hideError() {
    if (dom.errorState) dom.errorState.style.display = "none";
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

// ==========================================
// Product Reviews & Ratings Implementation
// ==========================================

let editReviewModalInstance = null;

async function initReviews(productId) {
    setupEditReviewModal(productId);
    await loadReviews(productId, 0);
    await checkAndRenderReviewForm(productId);
}

async function loadReviews(productId, page = 0) {
    const loadingEl = document.getElementById("reviews-loading");
    const emptyEl = document.getElementById("reviews-empty");
    const listEl = document.getElementById("reviews-list");
    const paginationEl = document.getElementById("reviews-pagination");

    if (loadingEl) loadingEl.classList.remove("d-none");
    if (emptyEl) emptyEl.classList.add("d-none");
    if (listEl) listEl.innerHTML = "";
    if (paginationEl) paginationEl.classList.add("d-none");

    try {
        const res = await ReviewApi.getProductReviews(productId, page, 10);
        const data = res.data;
        const reviews = data.reviews?.content || [];

        // Update rating summary header
        const avgScoreEl = document.getElementById("rating-average-score");
        const totalCountEl = document.getElementById("rating-total-count");
        const starsVisualEl = document.getElementById("rating-stars-visual");

        if (avgScoreEl) avgScoreEl.textContent = Number(data.averageRating || 0).toFixed(1);
        if (totalCountEl) totalCountEl.textContent = `${data.totalReviews || 0} lượt đánh giá`;
        if (starsVisualEl) starsVisualEl.innerHTML = renderStarRating(data.averageRating || 0);

        if (loadingEl) loadingEl.classList.add("d-none");

        if (reviews.length === 0) {
            if (emptyEl) emptyEl.classList.remove("d-none");
            return;
        }

        renderReviewsList(reviews, productId);

        if (data.reviews?.totalPages > 1 && paginationEl) {
            renderReviewsPagination(data.reviews.totalPages, data.reviews.number, productId);
            paginationEl.classList.remove("d-none");
        }
    } catch (err) {
        if (loadingEl) loadingEl.classList.add("d-none");
        console.warn("Could not load reviews:", err);
    }
}

async function checkAndRenderReviewForm(productId) {
    const container = document.getElementById("review-submission-container");
    if (!container) return;

    if (!isAuthenticated()) {
        container.innerHTML = `
            <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
                <div>
                    <h6 class="fw-bold mb-1"><i class="bi bi-pencil-square me-2 text-primary"></i>Bạn đã mua sản phẩm này?</h6>
                    <p class="text-muted small mb-0">Đăng nhập tài khoản đã mua hàng để gửi đánh giá và nhận xét.</p>
                </div>
                <a href="../auth/login.html?redirect=${encodeURIComponent(window.location.pathname + window.location.search)}" class="btn btn-outline-primary btn-sm px-3">
                    <i class="bi bi-box-arrow-in-right me-1"></i>Đăng nhập để đánh giá
                </a>
            </div>
        `;
        return;
    }

    try {
        const res = await ReviewApi.checkEligibility(productId);
        const eligibility = res.data;

        if (!eligibility.eligible) {
            container.innerHTML = `
                <div class="d-flex align-items-center gap-3 text-secondary">
                    <i class="bi bi-info-circle fs-4 text-primary"></i>
                    <div>
                        <h6 class="fw-bold mb-1">Đánh giá sản phẩm</h6>
                        <p class="mb-0 small">${escapeHtml(eligibility.reason)}</p>
                    </div>
                </div>
            `;
            return;
        }

        // User is eligible! Render Review Form
        container.innerHTML = `
            <form id="createReviewForm">
                <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                    <h6 class="fw-bold mb-0 text-dark">
                        <i class="bi bi-pencil-square text-primary me-2"></i>Viết đánh giá của bạn
                        ${eligibility.orderCode ? `<span class="badge bg-success-subtle text-success border border-success-subtle ms-2 fw-normal">Đơn hàng #${escapeHtml(eligibility.orderCode)}</span>` : ''}
                    </h6>
                    <div class="d-flex align-items-center gap-2">
                        <span class="small fw-semibold text-muted">Chọn số sao:</span>
                        <div class="d-flex gap-1 text-warning fs-5" id="createStarRatingPicker">
                            <i class="bi bi-star-fill star-pick" data-val="1" style="cursor:pointer;"></i>
                            <i class="bi bi-star-fill star-pick" data-val="2" style="cursor:pointer;"></i>
                            <i class="bi bi-star-fill star-pick" data-val="3" style="cursor:pointer;"></i>
                            <i class="bi bi-star-fill star-pick" data-val="4" style="cursor:pointer;"></i>
                            <i class="bi bi-star-fill star-pick" data-val="5" style="cursor:pointer;"></i>
                        </div>
                        <input type="hidden" id="createRatingValue" value="5">
                    </div>
                </div>

                <div class="mb-3">
                    <textarea class="form-control" id="createCommentText" rows="3" placeholder="Chia sẻ cảm nhận chi tiết về chất lượng sản phẩm, hiệu năng, đóng gói..." required minlength="5" maxlength="1000"></textarea>
                    <div class="form-text text-muted small">Tối thiểu 5 ký tự. Đánh giá sẽ được hiển thị công khai.</div>
                </div>

                <div class="text-end">
                    <button type="submit" class="btn btn-primary px-4" id="btnSubmitReview">
                        <span class="spinner-border spinner-border-sm d-none me-1" id="submitReviewSpinner"></span>
                        <i class="bi bi-send me-1"></i>Gửi đánh giá
                    </button>
                </div>
            </form>
        `;

        setupStarPicker("createStarRatingPicker", "createRatingValue");

        document.getElementById("createReviewForm")?.addEventListener("submit", async (e) => {
            e.preventDefault();
            const rating = Number(document.getElementById("createRatingValue").value);
            const comment = document.getElementById("createCommentText").value.trim();
            const submitBtn = document.getElementById("btnSubmitReview");
            const spinner = document.getElementById("submitReviewSpinner");

            if (!comment || comment.length < 5) {
                alert("Vui lòng nhập nhận xét ít nhất 5 ký tự.");
                return;
            }

            submitBtn.disabled = true;
            spinner?.classList.remove("d-none");

            try {
                await ReviewApi.createReview(productId, {
                    rating,
                    comment,
                    orderId: eligibility.orderId
                });
                alert("Cảm ơn bạn đã gửi đánh giá cho sản phẩm!");
                await initReviews(productId);
            } catch (err) {
                alert(err.message || "Không thể gửi đánh giá.");
            } finally {
                submitBtn.disabled = false;
                spinner?.classList.add("d-none");
            }
        });

    } catch (err) {
        container.innerHTML = `<div class="text-danger small">${escapeHtml(err.message || "Không thể kiểm tra điều kiện đánh giá.")}</div>`;
    }
}

function setupStarPicker(pickerId, inputId) {
    const container = document.getElementById(pickerId);
    const input = document.getElementById(inputId);
    if (!container || !input) return;

    const stars = container.querySelectorAll(".star-pick");
    const updateStars = (val) => {
        input.value = val;
        stars.forEach(s => {
            const sVal = Number(s.getAttribute("data-val"));
            if (sVal <= val) {
                s.className = "bi bi-star-fill star-pick";
            } else {
                s.className = "bi bi-star star-pick";
            }
        });
    };

    stars.forEach(s => {
        s.addEventListener("click", () => {
            const val = Number(s.getAttribute("data-val"));
            updateStars(val);
        });
    });
}

function renderReviewsList(reviews, productId) {
    const listEl = document.getElementById("reviews-list");
    if (!listEl) return;

    listEl.innerHTML = reviews.map(rev => {
        const canDelete = rev.isOwner || isAdmin();
        const canEdit = rev.isOwner;
        const dateStr = formatDateTime(rev.createdAt);

        return `
            <div class="card border rounded-3 p-3 bg-white">
                <div class="d-flex justify-content-between align-items-start gap-2 mb-2">
                    <div class="d-flex align-items-center gap-3">
                        <img src="${rev.userAvatar || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(rev.userName)}" alt="${escapeHtml(rev.userName)}" class="rounded-circle" width="42" height="42">
                        <div>
                            <div class="d-flex align-items-center gap-2">
                                <h6 class="mb-0 fw-bold text-dark">${escapeHtml(rev.userName)}</h6>
                                <span class="badge bg-success-subtle text-success border border-success-subtle small fw-normal py-1 px-2">
                                    <i class="bi bi-patch-check-fill me-1"></i>Đã mua tại TechStore
                                </span>
                            </div>
                            <div class="d-flex align-items-center gap-2 mt-1">
                                <div class="text-warning small">${renderStarRating(rev.rating)}</div>
                                <span class="text-muted small">&bull; ${dateStr}</span>
                            </div>
                        </div>
                    </div>

                    ${(canEdit || canDelete) ? `
                        <div class="dropdown">
                            <button class="btn btn-sm btn-link text-muted p-0" type="button" data-bs-toggle="dropdown">
                                <i class="bi bi-three-dots-vertical"></i>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end shadow-sm">
                                ${canEdit ? `<li><button class="dropdown-item btn-edit-review" data-id="${rev.id}" data-rating="${rev.rating}" data-comment="${escapeHtml(rev.comment)}"><i class="bi bi-pencil me-2"></i>Chỉnh sửa</button></li>` : ''}
                                ${canDelete ? `<li><button class="dropdown-item text-danger btn-delete-review" data-id="${rev.id}"><i class="bi bi-trash me-2"></i>Xóa đánh giá</button></li>` : ''}
                            </ul>
                        </div>
                    ` : ''}
                </div>

                <p class="mb-0 text-secondary mt-1 lh-base">${escapeHtml(rev.comment)}</p>
            </div>
        `;
    }).join("");

    // Attach Edit & Delete events
    listEl.querySelectorAll(".btn-edit-review").forEach(btn => {
        btn.addEventListener("click", () => {
            const id = btn.getAttribute("data-id");
            const rating = Number(btn.getAttribute("data-rating"));
            const comment = btn.getAttribute("data-comment");
            openEditReviewModal(id, rating, comment);
        });
    });

    listEl.querySelectorAll(".btn-delete-review").forEach(btn => {
        btn.addEventListener("click", async () => {
            const id = btn.getAttribute("data-id");
            if (!confirm("Bạn có chắc chắn muốn xóa đánh giá này?")) return;
            try {
                await ReviewApi.deleteReview(id);
                alert("Đã xóa đánh giá thành công.");
                await initReviews(productId);
            } catch (err) {
                alert(err.message || "Không thể xóa đánh giá.");
            }
        });
    });
}

function setupEditReviewModal(productId) {
    const modalEl = document.getElementById("editReviewModal");
    if (modalEl && typeof bootstrap !== "undefined") {
        editReviewModalInstance = new bootstrap.Modal(modalEl);
    }

    setupStarPicker("editStarRatingPicker", "editRatingValue");

    document.getElementById("btnSaveEditReview")?.addEventListener("click", async () => {
        const reviewId = document.getElementById("editReviewId").value;
        const rating = Number(document.getElementById("editRatingValue").value);
        const comment = document.getElementById("editCommentTextarea").value.trim();

        if (!comment || comment.length < 5) {
            alert("Vui lòng nhập nhận xét ít nhất 5 ký tự.");
            return;
        }

        const saveBtn = document.getElementById("btnSaveEditReview");
        const spinner = document.getElementById("editReviewSpinner");
        saveBtn.disabled = true;
        spinner?.classList.remove("d-none");

        try {
            await ReviewApi.updateReview(reviewId, { rating, comment });
            editReviewModalInstance?.hide();
            alert("Cập nhật đánh giá thành công!");
            await initReviews(productId);
        } catch (err) {
            alert(err.message || "Không thể cập nhật đánh giá.");
        } finally {
            saveBtn.disabled = false;
            spinner?.classList.add("d-none");
        }
    });
}

function openEditReviewModal(id, rating, comment) {
    document.getElementById("editReviewId").value = id;
    document.getElementById("editRatingValue").value = rating;
    document.getElementById("editCommentTextarea").value = comment;

    const stars = document.querySelectorAll("#editStarRatingPicker .star-pick");
    stars.forEach(s => {
        const sVal = Number(s.getAttribute("data-val"));
        s.className = sVal <= rating ? "bi bi-star-fill star-pick" : "bi bi-star star-pick";
    });

    editReviewModalInstance?.show();
}

function renderReviewsPagination(totalPages, activePage, productId) {
    const list = document.getElementById("reviews-pagination-list");
    if (!list) return;

    let html = "";
    for (let i = 0; i < totalPages; i++) {
        html += `
            <li class="page-item ${i === activePage ? 'active' : ''}">
                <button class="page-link" data-page="${i}">${i + 1}</button>
            </li>
        `;
    }
    list.innerHTML = html;
    list.querySelectorAll(".page-link").forEach(btn => {
        btn.addEventListener("click", () => {
            const page = Number(btn.getAttribute("data-page"));
            loadReviews(productId, page);
        });
    });
}

function renderStarRating(rating) {
    const rounded = Math.round(rating || 0);
    let html = "";
    for (let i = 1; i <= 5; i++) {
        html += i <= rounded ? '<i class="bi bi-star-fill"></i>' : '<i class="bi bi-star"></i>';
    }
    return html;
}

function formatDateTime(dateString) {
    if (!dateString) return "";
    const date = new Date(dateString);
    return date.toLocaleDateString("vi-VN", {
        day: "2-digit",
        month: "2-digit",
        year: "numeric"
    });
}

