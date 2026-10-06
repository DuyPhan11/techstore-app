import { isAdmin, isStaff } from "../auth/auth.js";

/**
 * Product Card Component
 * Renders consistent, responsive product card with formatting, image fallback, stock status and staff controls
 */
export function formatCurrency(amount) {
    if (amount === null || amount === undefined) return "0 ₫";
    return new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND"
    }).format(amount);
}

export function renderProductCard(product, options = {}) {
    const isHtmlPath = window.location.pathname.endsWith(".html");
    const defaultPrefix = isHtmlPath ? "./product-detail.html" : "./product-detail";
    const {
        detailUrlPrefix = defaultPrefix
    } = options;

    const primaryImage = product.primaryImageUrl || "https://placehold.co/400x300?text=No+Image";
    const hasStock = (product.totalStock || 0) > 0;
    const canManage = isAdmin() || isStaff();

    const categoryName = product.category?.name || "Công nghệ";
    const brandName = product.brand?.name || "";

    const card = document.createElement("div");
    card.className = "col-12 col-sm-6 col-md-4 col-lg-3 d-flex";
    card.setAttribute("data-product-id", product.id);

    card.innerHTML = `
        <div class="card h-100 w-100 shadow-sm border-0 product-card position-relative d-flex flex-column">
            ${canManage ? `
                <div class="position-absolute top-0 end-0 m-2 z-2 dropdown">
                    <button class="btn btn-sm btn-light rounded-circle shadow-sm border" type="button" data-bs-toggle="dropdown" title="Quản lý sản phẩm">
                        <i class="bi bi-three-dots-vertical"></i>
                    </button>
                    <ul class="dropdown-menu dropdown-menu-end shadow">
                        <li><h6 class="dropdown-header">Quản trị viên</h6></li>
                        <li><a class="dropdown-item btn-edit-product" href="#" data-id="${product.id}"><i class="bi bi-pencil me-2 text-primary"></i>Chỉnh sửa</a></li>
                        <li><a class="dropdown-item btn-delete-product text-danger" href="#" data-id="${product.id}" data-name="${escapeHtml(product.name)}"><i class="bi bi-trash me-2"></i>Ẩn / Xóa</a></li>
                    </ul>
                </div>
            ` : ""}

            <div class="product-image-container position-relative overflow-hidden bg-light text-center p-3">
                <a href="${detailUrlPrefix}?id=${product.id}" class="d-block text-decoration-none">
                    <img src="${escapeHtml(primaryImage)}" 
                         alt="${escapeHtml(product.name)}" 
                         class="img-fluid product-img rounded"
                         loading="lazy"
                         onerror="this.onerror=null; this.src='https://placehold.co/400x300?text=Image+Not+Found';">
                </a>
                <span class="badge ${hasStock ? "bg-success" : "bg-secondary"} position-absolute bottom-0 start-0 m-2">
                    ${hasStock ? `<i class="bi bi-check-circle me-1"></i>Còn hàng (${product.totalStock})` : "Hết hàng"}
                </span>
            </div>

            <div class="card-body d-flex flex-column p-3">
                <div class="d-flex align-items-center justify-content-between mb-2">
                    <span class="badge bg-light text-primary border small">${escapeHtml(categoryName)}</span>
                    ${brandName ? `<span class="badge bg-light text-dark border small">${escapeHtml(brandName)}</span>` : ""}
                </div>

                <h6 class="card-title mb-1 flex-grow-1">
                    <a href="${detailUrlPrefix}?id=${product.id}" class="text-dark text-decoration-none product-title" title="${escapeHtml(product.name)}">
                        ${escapeHtml(product.name)}
                    </a>
                </h6>
                <p class="text-muted small mb-2 font-monospace">SKU: ${escapeHtml(product.sku)}</p>

                <div class="d-flex align-items-baseline justify-content-between mt-auto pt-2 border-top">
                    <div>
                        <span class="fs-5 fw-bold text-danger">${formatCurrency(product.price)}</span>
                    </div>
                </div>

                <div class="d-grid gap-2 mt-3">
                    <a href="${detailUrlPrefix}?id=${product.id}" class="btn btn-outline-primary btn-sm">
                        <i class="bi bi-eye me-1"></i> Xem chi tiết
                    </a>
                </div>
            </div>
        </div>
    `;

    card.querySelectorAll("a[href*='product-detail']").forEach(a => {
        a.addEventListener("click", () => {
            try {
                localStorage.setItem("techstore_last_viewed_product_id", product.id);
            } catch (e) {}
        });
    });

    return card;
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
