import { CheckoutApi } from "../../js/api/checkout-api.js";
import { CartApi, updateCartBadge } from "../../js/api/cart-api.js";
import { formatCurrency } from "../../js/components/product-card.js";
import { isAuthenticated, isAdmin, getCurrentUser, logout } from "../../js/auth/auth.js";

// State
const state = {
    cart: null,
    branches: [],
    selectedBranchId: 1,
    appliedCoupon: null,
    discountAmount: 0,
    isSubmitting: false
};

// DOM Elements
const dom = {
    authContainer: document.getElementById("nav-auth-container"),
    unauthState: document.getElementById("checkout-unauth"),
    emptyState: document.getElementById("checkout-empty"),
    successState: document.getElementById("checkout-success"),
    checkoutView: document.getElementById("checkout-view"),
    checkoutForm: document.getElementById("checkout-form"),
    // Form fields
    inputName: document.getElementById("input-name"),
    inputPhone: document.getElementById("input-phone"),
    inputAddress: document.getElementById("input-address"),
    inputNotes: document.getElementById("input-notes"),
    branchContainer: document.getElementById("branch-options-container"),
    // Items & Pricing
    itemsList: document.getElementById("checkout-items-list"),
    inputCoupon: document.getElementById("input-coupon"),
    btnApplyCoupon: document.getElementById("btn-apply-coupon"),
    couponFeedback: document.getElementById("coupon-feedback"),
    summarySubtotal: document.getElementById("summary-subtotal"),
    rowDiscount: document.getElementById("row-discount"),
    summaryDiscount: document.getElementById("summary-discount"),
    summaryGrandTotal: document.getElementById("summary-grand-total"),
    btnSubmitOrder: document.getElementById("btn-submit-order"),
    submitSpinner: document.getElementById("submit-spinner"),
    // Success fields
    successOrderCode: document.getElementById("success-order-code"),
    successRecipient: document.getElementById("success-recipient"),
    successAddress: document.getElementById("success-address"),
    successPaymentMethod: document.getElementById("success-payment-method"),
    successPaymentStatus: document.getElementById("success-payment-status"),
    successTotal: document.getElementById("success-total"),
    // Toast
    toastEl: document.getElementById("checkout-toast"),
    toastBody: document.getElementById("checkout-toast-body")
};

let checkoutToast = null;

// Initialize
document.addEventListener("DOMContentLoaded", async () => {
    if (dom.toastEl && window.bootstrap) {
        checkoutToast = new window.bootstrap.Toast(dom.toastEl, { delay: 4000 });
    }

    renderNavbar();

    if (!isAuthenticated()) {
        showUnauth();
        return;
    }

    setupEventListeners();
    await loadInitialData();
});

// Render Navbar Auth
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

// Setup Event Listeners
function setupEventListeners() {
    // Payment method card selection highlight
    document.querySelectorAll("input[name='paymentMethod']").forEach(radio => {
        radio.addEventListener("change", () => {
            document.querySelectorAll(".payment-method-card").forEach(card => card.classList.remove("active"));
            radio.closest(".payment-method-card")?.classList.add("active");
        });
    });

    // Apply Coupon
    dom.btnApplyCoupon?.addEventListener("click", handleApplyCoupon);

    // Submit Order
    dom.btnSubmitOrder?.addEventListener("click", handleSubmitOrder);
}

// Load Initial Data (Cart & Branches)
async function loadInitialData() {
    try {
        const [cartRes, branchRes] = await Promise.all([
            CartApi.getCart(),
            CheckoutApi.getBranches().catch(() => ({ data: [] }))
        ]);

        state.cart = cartRes?.data;
        state.branches = branchRes?.data || [];

        if (!state.cart || !state.cart.items || state.cart.items.length === 0) {
            showEmpty();
            return;
        }

        renderCartPreview(state.cart);
        renderBranches(state.branches);
        prefillUserInfo();

        if (dom.checkoutView) dom.checkoutView.style.display = "flex";
    } catch (err) {
        console.error("Lỗi khi tải dữ liệu thanh toán:", err);
        showToast(err.message || "Không thể tải dữ liệu giỏ hàng.", "danger");
    }
}

// Prefill Logged In User Info
function prefillUserInfo() {
    const user = getCurrentUser();
    if (!user) return;

    if (dom.inputName && user.fullName) dom.inputName.value = user.fullName;
    if (dom.inputPhone && user.phone) dom.inputPhone.value = user.phone;
}

// Render Branches Radio List
function renderBranches(branches) {
    if (!dom.branchContainer) return;

    if (branches.length === 0) {
        dom.branchContainer.innerHTML = '<div class="text-muted small">Mặc định: Chi nhánh Hà Nội</div>';
        state.selectedBranchId = 1;
        return;
    }

    let html = "";
    branches.forEach((b, idx) => {
        const isChecked = idx === 0;
        if (isChecked) state.selectedBranchId = b.id;

        html += `
            <div class="form-check p-3 border rounded-3 bg-white d-flex align-items-center justify-content-between mb-2">
                <div>
                    <input class="form-check-input branch-radio" type="radio" name="branchOption" id="branch-${b.id}" value="${b.id}" ${isChecked ? "checked" : ""}>
                    <label class="form-check-label fw-bold ms-2" for="branch-${b.id}">
                        ${escapeHtml(b.name)}
                    </label>
                    <div class="small text-muted ms-4">${escapeHtml(b.address)} - SĐT: ${escapeHtml(b.phone || "1800-TECHSTORE")}</div>
                </div>
                <span class="badge bg-light text-success border">Sẵn sàng xuất kho</span>
            </div>
        `;
    });

    dom.branchContainer.innerHTML = html;

    dom.branchContainer.querySelectorAll(".branch-radio").forEach(radio => {
        radio.addEventListener("change", (e) => {
            state.selectedBranchId = Number(e.target.value);
        });
    });
}

// Render Cart Items Preview in Summary
function renderCartPreview(cart) {
    if (!dom.itemsList) return;
    dom.itemsList.innerHTML = "";

    cart.items.forEach(item => {
        const itemRow = document.createElement("div");
        itemRow.className = "d-flex align-items-center gap-3 border-bottom pb-2";

        const primaryImg = item.primaryImageUrl || "https://placehold.co/60x60?text=No+Image";

        itemRow.innerHTML = `
            <img src="${escapeHtml(primaryImg)}" alt="${escapeHtml(item.productName)}" class="checkout-item-img border"
                 onerror="this.onerror=null; this.src='https://placehold.co/60x60?text=Image';">
            <div class="flex-grow-1 overflow-hidden">
                <h6 class="mb-0 text-truncate small fw-bold" title="${escapeHtml(item.productName)}">${escapeHtml(item.productName)}</h6>
                <div class="text-muted small">${formatCurrency(item.unitPrice)} × ${item.quantity}</div>
            </div>
            <div class="text-end fw-semibold text-danger small text-nowrap">
                ${formatCurrency(item.subtotal)}
            </div>
        `;

        dom.itemsList.appendChild(itemRow);
    });

    updateTotals();
}

// Calculate & Update Pricing Display
function updateTotals() {
    const subtotal = state.cart?.totalPrice || 0;
    const finalAmount = Math.max(0, subtotal - state.discountAmount);

    if (dom.summarySubtotal) dom.summarySubtotal.textContent = formatCurrency(subtotal);

    if (state.discountAmount > 0) {
        if (dom.rowDiscount) dom.rowDiscount.style.setProperty("display", "flex", "important");
        if (dom.summaryDiscount) dom.summaryDiscount.textContent = `-${formatCurrency(state.discountAmount)}`;
    } else {
        if (dom.rowDiscount) dom.rowDiscount.style.setProperty("display", "none", "important");
    }

    if (dom.summaryGrandTotal) dom.summaryGrandTotal.textContent = formatCurrency(finalAmount);
}

// Apply Coupon Handler
async function handleApplyCoupon() {
    const code = dom.inputCoupon?.value.trim().toUpperCase();
    if (!code) {
        showCouponFeedback("Vui lòng nhập mã giảm giá", "text-danger");
        return;
    }

    const subtotal = state.cart?.totalPrice || 0;
    try {
        const res = await CheckoutApi.validateCoupon(code, subtotal);
        const data = res?.data;

        if (data?.valid) {
            state.appliedCoupon = code;
            state.discountAmount = data.discountAmount || 0;
            updateTotals();
            showCouponFeedback(`Áp dụng thành công mã "${code}": Giảm ${formatCurrency(state.discountAmount)}`, "text-success");
        } else {
            state.appliedCoupon = null;
            state.discountAmount = 0;
            updateTotals();
            showCouponFeedback(data?.message || "Mã giảm giá không hợp lệ", "text-danger");
        }
    } catch (err) {
        state.appliedCoupon = null;
        state.discountAmount = 0;
        updateTotals();
        showCouponFeedback(err.message || "Không thể kiểm tra mã giảm giá", "text-danger");
    }
}

function showCouponFeedback(msg, className) {
    if (!dom.couponFeedback) return;
    dom.couponFeedback.style.display = "block";
    dom.couponFeedback.className = `small mt-2 ${className}`;
    dom.couponFeedback.textContent = msg;
}

// Submit Order Handler
async function handleSubmitOrder() {
    if (state.isSubmitting) return;

    // Validate recipient fields
    const recipientName = dom.inputName?.value.trim();
    const recipientPhone = dom.inputPhone?.value.trim();
    const shippingAddress = dom.inputAddress?.value.trim();
    const notes = dom.inputNotes?.value.trim();

    if (!recipientName) {
        alert("Vui lòng nhập họ tên người nhận hàng.");
        dom.inputName?.focus();
        return;
    }
    if (!recipientPhone) {
        alert("Vui lòng nhập số điện thoại người nhận.");
        dom.inputPhone?.focus();
        return;
    }
    if (!shippingAddress) {
        alert("Vui lòng nhập địa chỉ nhận hàng cụ thể.");
        dom.inputAddress?.focus();
        return;
    }

    const selectedPaymentInput = document.querySelector("input[name='paymentMethod']:checked");
    const paymentMethod = selectedPaymentInput ? selectedPaymentInput.value : "COD";

    const payload = {
        recipientName,
        recipientPhone,
        shippingAddress,
        branchId: state.selectedBranchId,
        couponCode: state.appliedCoupon,
        paymentMethod,
        notes,
        mockPaymentSuccess: true
    };

    setSubmitting(true);

    try {
        const response = await CheckoutApi.checkout(payload);
        const order = response?.data;

        if (!order) {
            throw new Error("Không nhận được dữ liệu xác nhận đơn hàng từ máy chủ.");
        }

        renderSuccessScreen(order);
        updateCartBadge();
    } catch (err) {
        console.error("Lỗi đặt hàng:", err);
        showToast(err.message || "Đã xảy ra lỗi khi đặt hàng. Vui lòng kiểm tra lại tồn kho hoặc thử lại.", "danger");
    } finally {
        setSubmitting(false);
    }
}

// Render Success Screen
function renderSuccessScreen(order) {
    if (dom.checkoutView) dom.checkoutView.style.display = "none";
    if (dom.successState) dom.successState.style.display = "block";

    if (dom.successOrderCode) dom.successOrderCode.textContent = order.orderCode;
    if (dom.successRecipient) dom.successRecipient.textContent = `${order.recipientName} (${order.recipientPhone})`;
    if (dom.successAddress) dom.successAddress.textContent = order.shippingAddress;
    if (dom.successPaymentMethod) dom.successPaymentMethod.textContent = order.paymentMethod;

    if (dom.successPaymentStatus) {
        const isPaid = order.paymentStatus === "PAID";
        dom.successPaymentStatus.className = `badge ${isPaid ? "bg-success" : "bg-warning text-dark"}`;
        dom.successPaymentStatus.textContent = isPaid ? "Đã thanh toán" : "Chờ thanh toán khi nhận hàng";
    }

    if (dom.successTotal) dom.successTotal.textContent = formatCurrency(order.finalAmount);

    window.scrollTo({ top: 0, behavior: "smooth" });
}

// UI States
function setSubmitting(submitting) {
    state.isSubmitting = submitting;
    if (dom.btnSubmitOrder) dom.btnSubmitOrder.disabled = submitting;
    if (dom.submitSpinner) {
        if (submitting) dom.submitSpinner.classList.remove("d-none");
        else dom.submitSpinner.classList.add("d-none");
    }
}

function showUnauth() {
    if (dom.unauthState) dom.unauthState.style.display = "block";
    if (dom.checkoutView) dom.checkoutView.style.display = "none";
    if (dom.emptyState) dom.emptyState.style.display = "none";
}

function showEmpty() {
    if (dom.emptyState) dom.emptyState.style.display = "block";
    if (dom.checkoutView) dom.checkoutView.style.display = "none";
    if (dom.unauthState) dom.unauthState.style.display = "none";
}

function showToast(message, type = "dark") {
    if (!dom.toastEl || !checkoutToast) return;
    dom.toastEl.className = `toast align-items-center text-white bg-${type} border-0 shadow`;
    if (dom.toastBody) dom.toastBody.textContent = message;
    checkoutToast.show();
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
