import { CartApi, updateCartBadge } from "../../js/api/cart-api.js";
import { formatCurrency } from "../../js/components/product-card.js";
import { isAuthenticated, isAdmin, getCurrentUser, logout } from "../../js/auth/auth.js";

// DOM Elements
const dom = {
    authContainer: document.getElementById("nav-auth-container"),
    unauthState: document.getElementById("unauth-state"),
    cartLoading: document.getElementById("cart-loading"),
    cartEmpty: document.getElementById("cart-empty"),
    cartContent: document.getElementById("cart-content"),
    cartTbody: document.getElementById("cart-items-tbody"),
    btnClearCart: document.getElementById("btn-clear-cart"),
    summaryTotalItems: document.getElementById("summary-total-items"),
    summarySubtotal: document.getElementById("summary-subtotal"),
    summaryGrandTotal: document.getElementById("summary-grand-total"),
    btnCheckout: document.getElementById("btn-checkout"),
    toastEl: document.getElementById("cart-toast"),
    toastBody: document.getElementById("cart-toast-body")
};

let cartToast = null;
let currentCart = null;

// Initialize
document.addEventListener("DOMContentLoaded", async () => {
    if (dom.toastEl && window.bootstrap) {
        cartToast = new window.bootstrap.Toast(dom.toastEl, { delay: 3000 });
    }

    renderNavbar();

    if (!isAuthenticated()) {
        showUnauth();
        return;
    }

    setupEventListeners();
    await loadCart();
});

// Render Navbar Auth
function renderNavbar() {
    if (!dom.authContainer) return;

    if (isAuthenticated()) {
        const user = getCurrentUser();
        const displayName = user?.fullName || user?.email || "Tài khoản";

        dom.authContainer.innerHTML = `
            <a href="./cart.html" class="btn btn-primary position-relative">
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

// Setup Event Listeners
function setupEventListeners() {
    dom.btnClearCart?.addEventListener("click", handleClearCart);

    dom.btnCheckout?.addEventListener("click", () => {
        if (!currentCart || currentCart.items.length === 0) {
            showToast("Giỏ hàng của bạn đang trống!");
            return;
        }

        // Check if any item is out of stock or requested quantity exceeds stock
        const invalidItem = currentCart.items.find(i => !i.inStock || i.quantity > i.availableStock);
        if (invalidItem) {
            showToast(`Sản phẩm "${invalidItem.productName}" không đủ tồn kho khả dụng (${invalidItem.availableStock}). Vui lòng giảm số lượng để thanh toán!`, "danger");
            return;
        }

        window.location.href = "../checkout/checkout.html";
    });
}

// Load Cart Data
async function loadCart() {
    setLoading(true);
    hideEmpty();

    try {
        const response = await CartApi.getCart();
        currentCart = response?.data;

        if (!currentCart || !currentCart.items || currentCart.items.length === 0) {
            showEmpty();
        } else {
            renderCart(currentCart);
        }

        updateCartBadge();
    } catch (err) {
        console.error("Lỗi khi tải giỏ hàng:", err);
        showToast(err.message || "Không thể tải dữ liệu giỏ hàng.", "danger");
    } finally {
        setLoading(false);
    }
}

// Render Cart items table and summary
function renderCart(cart) {
    if (!dom.cartTbody) return;
    dom.cartTbody.innerHTML = "";

    if (dom.btnClearCart) dom.btnClearCart.style.display = "inline-block";
    if (dom.cartContent) dom.cartContent.style.display = "flex";

    cart.items.forEach(item => {
        const tr = document.createElement("tr");
        tr.setAttribute("data-product-id", item.productId);

        const primaryImg = item.primaryImageUrl || "https://placehold.co/100x100?text=No+Image";
        const hasEnoughStock = item.availableStock >= item.quantity;

        tr.innerHTML = `
            <td>
                <div class="d-flex align-items-center gap-3">
                    <img src="${escapeHtml(primaryImg)}" 
                         alt="${escapeHtml(item.productName)}" 
                         class="cart-item-img border"
                         onerror="this.onerror=null; this.src='https://placehold.co/100x100?text=Image';">
                    <div>
                        <h6 class="mb-1">
                            <a href="${window.location.pathname.endsWith('.html') ? '../products/product-detail.html' : '../products/product-detail'}?id=${item.productId}" class="text-dark text-decoration-none fw-semibold">
                                ${escapeHtml(item.productName)}
                            </a>
                        </h6>
                        <div class="small text-muted font-monospace mb-1">SKU: ${escapeHtml(item.productSku)}</div>
                        ${!hasEnoughStock ? `
                            <span class="badge bg-danger">
                                <i class="bi bi-exclamation-circle me-1"></i> Chỉ còn ${item.availableStock} trong kho
                            </span>
                        ` : `
                            <span class="badge bg-light text-success border small">
                                <i class="bi bi-check-circle me-1"></i> Có sẵn ${item.availableStock}
                            </span>
                        `}
                    </div>
                </div>
            </td>
            <td class="text-center fw-medium text-nowrap">
                ${formatCurrency(item.unitPrice)}
            </td>
            <td class="text-center">
                <div class="input-group input-group-sm justify-content-center mx-auto" style="max-width: 120px;">
                    <button class="btn btn-outline-secondary btn-item-minus" type="button" data-product-id="${item.productId}">-</button>
                    <input type="number" class="form-control text-center cart-qty-input" 
                           value="${item.quantity}" min="1" max="${item.availableStock}" 
                           data-product-id="${item.productId}">
                    <button class="btn btn-outline-secondary btn-item-plus" type="button" data-product-id="${item.productId}">+</button>
                </div>
            </td>
            <td class="text-end fw-bold text-danger text-nowrap">
                ${formatCurrency(item.subtotal)}
            </td>
            <td class="text-center">
                <button class="btn btn-link text-danger p-0 btn-remove-item" title="Xóa khỏi giỏ hàng" data-product-id="${item.productId}" data-product-name="${escapeHtml(item.productName)}">
                    <i class="bi bi-trash fs-5"></i>
                </button>
            </td>
        `;

        dom.cartTbody.appendChild(tr);
    });

    // Attach row events
    dom.cartTbody.querySelectorAll(".btn-item-minus").forEach(btn => {
        btn.addEventListener("click", () => {
            const pId = Number(btn.getAttribute("data-product-id"));
            const currentItem = cart.items.find(i => i.productId === pId);
            if (currentItem && currentItem.quantity > 1) {
                handleUpdateQuantity(pId, currentItem.quantity - 1);
            } else if (currentItem && currentItem.quantity === 1) {
                handleRemoveItem(pId, currentItem.productName);
            }
        });
    });

    dom.cartTbody.querySelectorAll(".btn-item-plus").forEach(btn => {
        btn.addEventListener("click", () => {
            const pId = Number(btn.getAttribute("data-product-id"));
            const currentItem = cart.items.find(i => i.productId === pId);
            if (currentItem) {
                if (currentItem.quantity >= currentItem.availableStock) {
                    showToast(`Sản phẩm chỉ còn ${currentItem.availableStock} trong kho!`, "warning");
                    return;
                }
                handleUpdateQuantity(pId, currentItem.quantity + 1);
            }
        });
    });

    dom.cartTbody.querySelectorAll(".cart-qty-input").forEach(input => {
        input.addEventListener("change", () => {
            const pId = Number(input.getAttribute("data-product-id"));
            const currentItem = cart.items.find(i => i.productId === pId);
            let val = Number(input.value);

            if (isNaN(val) || val <= 0) {
                if (currentItem) handleRemoveItem(pId, currentItem.productName);
                return;
            }

            if (currentItem && val > currentItem.availableStock) {
                showToast(`Số lượng yêu cầu vượt quá tồn kho khả dụng (${currentItem.availableStock})!`, "warning");
                input.value = currentItem.quantity;
                return;
            }

            handleUpdateQuantity(pId, val);
        });
    });

    dom.cartTbody.querySelectorAll(".btn-remove-item").forEach(btn => {
        btn.addEventListener("click", () => {
            const pId = Number(btn.getAttribute("data-product-id"));
            const pName = btn.getAttribute("data-product-name");
            handleRemoveItem(pId, pName);
        });
    });

    // Update Summary
    if (dom.summaryTotalItems) dom.summaryTotalItems.textContent = cart.totalItems;
    if (dom.summarySubtotal) dom.summarySubtotal.textContent = formatCurrency(cart.totalPrice);
    if (dom.summaryGrandTotal) dom.summaryGrandTotal.textContent = formatCurrency(cart.totalPrice);
}

// Action: Update Quantity
async function handleUpdateQuantity(productId, newQty) {
    try {
        const response = await CartApi.updateQuantity(productId, newQty);
        currentCart = response?.data;
        renderCart(currentCart);
        updateCartBadge();
        showToast("Đã cập nhật số lượng giỏ hàng.");
    } catch (err) {
        showToast(err.message || "Không thể cập nhật số lượng.", "danger");
        loadCart(); // reload to reset state
    }
}

// Action: Remove Item
async function handleRemoveItem(productId, productName) {
    if (!confirm(`Bạn có chắc muốn xóa "${productName}" khỏi giỏ hàng không?`)) {
        return;
    }

    try {
        const response = await CartApi.removeItem(productId);
        currentCart = response?.data;
        if (!currentCart || currentCart.items.length === 0) {
            showEmpty();
        } else {
            renderCart(currentCart);
        }
        updateCartBadge();
        showToast(`Đã xóa "${productName}" khỏi giỏ hàng.`);
    } catch (err) {
        showToast(err.message || "Không thể xóa sản phẩm.", "danger");
    }
}

// Action: Clear Cart
async function handleClearCart() {
    if (!confirm("Bạn có chắc muốn xóa toàn bộ sản phẩm trong giỏ hàng?")) {
        return;
    }

    try {
        await CartApi.clearCart();
        showEmpty();
        updateCartBadge();
        showToast("Đã làm trống giỏ hàng.");
    } catch (err) {
        showToast(err.message || "Không thể xóa giỏ hàng.", "danger");
    }
}

// UI States
function setLoading(loading) {
    if (dom.cartLoading) dom.cartLoading.style.display = loading ? "block" : "none";
    if (dom.cartContent && loading) dom.cartContent.style.display = "none";
}

function showEmpty() {
    if (dom.cartEmpty) dom.cartEmpty.style.display = "block";
    if (dom.cartContent) dom.cartContent.style.display = "none";
    if (dom.btnClearCart) dom.btnClearCart.style.display = "none";
}

function hideEmpty() {
    if (dom.cartEmpty) dom.cartEmpty.style.display = "none";
}

function showUnauth() {
    if (dom.unauthState) dom.unauthState.style.display = "block";
    if (dom.cartLoading) dom.cartLoading.style.display = "none";
    if (dom.cartEmpty) dom.cartEmpty.style.display = "none";
    if (dom.cartContent) dom.cartContent.style.display = "none";
    if (dom.btnClearCart) dom.btnClearCart.style.display = "none";
}

function showToast(message, type = "dark") {
    if (!dom.toastEl || !cartToast) return;
    dom.toastEl.className = `toast align-items-center text-white bg-${type} border-0 shadow`;
    if (dom.toastBody) dom.toastBody.textContent = message;
    cartToast.show();
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
