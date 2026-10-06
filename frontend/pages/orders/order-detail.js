import { Guard } from "../../js/auth/guard.js";
import { Auth } from "../../js/auth/auth.js";
import { OrderApi } from "../../js/api/order-api.js";
import { CartApi } from "../../js/api/cart-api.js";

let currentOrder = null;
let cancelModalInstance = null;

document.addEventListener("DOMContentLoaded", async () => {
    // 1. Enforce Authentication
    if (!Guard.requireAuth()) return;

    setupNavbar();
    await updateCartBadge();

    const urlParams = new URLSearchParams(window.location.search);
    let orderId = urlParams.get("id");

    if (!orderId) {
        const cachedId = localStorage.getItem("techstore_last_viewed_order_id");
        if (cachedId) {
            orderId = cachedId;
            try {
                const newUrl = window.location.pathname + "?id=" + orderId;
                window.history.replaceState({}, "", newUrl);
            } catch (e) {}
        }
    }

    if (!orderId) {
        alert("Không tìm thấy mã đơn hàng hợp lệ.");
        window.location.href = window.location.pathname.endsWith(".html") ? "my-orders.html" : "my-orders";
        return;
    }

    if (orderId) {
        try {
            localStorage.setItem("techstore_last_viewed_order_id", orderId);
        } catch (e) {}
    }

    setupCancelModal(orderId);
    await loadOrderDetail(orderId);
});

function setupNavbar() {
    const authNavContainer = document.getElementById("authNavContainer");
    const user = Auth.getUser();

    if (user && authNavContainer) {
        const displayName = user.fullName || user.email || "Tài khoản";
        authNavContainer.innerHTML = `
            <div class="dropdown">
                <button class="btn btn-light border dropdown-toggle d-flex align-items-center gap-2" type="button" data-bs-toggle="dropdown">
                    <i class="bi bi-person-circle text-primary fs-5"></i>
                    <span class="fw-semibold">${escapeHtml(displayName)}</span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-sm">
                    <li><h6 class="dropdown-header">Xin chào, ${escapeHtml(displayName)}</h6></li>
                    <li><a class="dropdown-item active" href="my-orders.html"><i class="bi bi-bag me-2"></i>Đơn mua của tôi</a></li>
                    ${Auth.isStaff() ? '<li><a class="dropdown-item text-primary" href="../admin/admin-orders.html"><i class="bi bi-speedometer2 me-2"></i>Quản trị đơn hàng</a></li>' : ''}
                    <li><hr class="dropdown-divider"></li>
                    <li><button class="dropdown-item text-danger" id="logoutBtn"><i class="bi bi-box-arrow-right me-2"></i>Đăng xuất</button></li>
                </ul>
            </div>
        `;

        document.getElementById("logoutBtn")?.addEventListener("click", () => {
            Auth.logout();
        });
    }
}

async function updateCartBadge() {
    try {
        const res = await CartApi.getCart();
        const badge = document.getElementById("cart-badge") || document.getElementById("cartCountBadge");
        if (badge && res.data) {
            const count = res.data.totalItems || 0;
            badge.textContent = count;
            badge.style.display = count > 0 ? "inline-block" : "none";
        }
    } catch (e) {
        console.warn("Failed to load cart count", e);
    }
}

function setupCancelModal(orderId) {
    const modalEl = document.getElementById("cancelOrderModal");
    if (modalEl) {
        cancelModalInstance = new bootstrap.Modal(modalEl);
    }

    const confirmBtn = document.getElementById("detailConfirmCancelBtn");
    confirmBtn?.addEventListener("click", async () => {
        const reason = document.getElementById("detailCancelReason").value.trim();
        confirmBtn.disabled = true;
        try {
            await OrderApi.cancelOrder(orderId, reason);
            cancelModalInstance?.hide();
            alert("Đơn hàng đã được hủy thành công!");
            await loadOrderDetail(orderId);
        } catch (err) {
            alert(err.message || "Không thể hủy đơn hàng.");
        } finally {
            confirmBtn.disabled = false;
        }
    });
}

async function loadOrderDetail(orderId) {
    const loadingEl = document.getElementById("detailLoading");
    const contentEl = document.getElementById("detailContent");

    loadingEl.classList.remove("d-none");
    contentEl.classList.add("d-none");

    try {
        const res = await OrderApi.getOrderDetail(orderId);
        currentOrder = res.data;
        renderOrderDetail(currentOrder);

        loadingEl.classList.add("d-none");
        contentEl.classList.remove("d-none");
    } catch (err) {
        loadingEl.classList.add("d-none");
        alert(err.message || "Không thể tải chi tiết đơn hàng.");
        window.location.href = "my-orders.html";
    }
}

function renderOrderDetail(order) {
    document.getElementById("detailOrderCode").textContent = `#${order.orderCode}`;
    const bcCode = document.getElementById("breadcrumbDetailOrderCode");
    if (bcCode) bcCode.textContent = `#${order.orderCode}`;

    // Action buttons (Cancel order button if eligible)
    const isCancellable = ["PENDING", "PAYMENT_PENDING", "CONFIRMED"].includes(order.status);
    const actionContainer = document.getElementById("detailActionButtons");
    if (actionContainer) {
        actionContainer.innerHTML = isCancellable ? `
            <button class="btn btn-outline-danger btn-sm" id="detailCancelBtn">
                <i class="bi bi-x-circle me-1"></i>Hủy đơn hàng
            </button>
        ` : '';

        document.getElementById("detailCancelBtn")?.addEventListener("click", () => {
            cancelModalInstance?.show();
        });
    }

    // Timeline / Stepper
    renderTimeline(order.status, order.createdAt, order.notes);

    // Recipient & Delivery
    document.getElementById("detailRecipientName").textContent = order.recipientName;
    document.getElementById("detailRecipientPhone").textContent = order.recipientPhone;
    document.getElementById("detailShippingAddress").textContent = order.shippingAddress;
    document.getElementById("detailNotes").textContent = order.notes || "Không có ghi chú";

    // Branch
    document.getElementById("detailBranchName").textContent = order.branchName || "Chi nhánh chính";

    // Payment Info
    document.getElementById("detailPaymentMethod").textContent = order.paymentMethod === "COD" ? "Thanh toán khi nhận hàng (COD)" : "Thanh toán trực tuyến (Mock)";
    document.getElementById("detailPaymentStatus").innerHTML = getPaymentBadge(order.paymentStatus);
    
    const txContainer = document.getElementById("detailTxCodeContainer");
    if (order.transactionCode) {
        document.getElementById("detailTxCode").textContent = order.transactionCode;
        txContainer.classList.remove("d-none");
    } else {
        txContainer.classList.add("d-none");
    }

    // Amounts
    document.getElementById("detailTotalItemsAmount").textContent = formatCurrency(order.totalItemsAmount);
    document.getElementById("detailDiscountAmount").textContent = `-${formatCurrency(order.discountAmount)}`;
    document.getElementById("detailCouponCode").textContent = order.couponCode ? `Mã: ${order.couponCode}` : "Không có";
    document.getElementById("detailFinalAmount").textContent = formatCurrency(order.finalAmount);

    // Items
    const items = order.items || [];
    document.getElementById("detailItemCount").textContent = `${items.length} sản phẩm`;

    const tableBody = document.getElementById("detailItemsTableBody");
    tableBody.innerHTML = items.map(item => `
        <tr>
            <td>
                <div class="d-flex align-items-center gap-3">
                    <img src="${item.productImage || item.productThumbnail || 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=100'}" alt="${escapeHtml(item.productName)}" class="order-product-thumb">
                    <div>
                        <h6 class="mb-0 fw-semibold">${escapeHtml(item.productName)}</h6>
                        <small class="text-muted">Mã: #${item.productId}</small>
                    </div>
                </div>
            </td>
            <td class="text-center">${formatCurrency(item.unitPrice)}</td>
            <td class="text-center fw-semibold">${item.quantity}</td>
            <td class="text-end fw-bold text-dark">${formatCurrency(item.totalPrice ?? item.subtotalAmount ?? (item.unitPrice * item.quantity))}</td>
        </tr>
    `).join("");
}

function renderTimeline(status, createdAt, notes) {
    const timelineEl = document.getElementById("trackingTimeline");
    const cancelledBanner = document.getElementById("cancelledBanner");

    if (status === "CANCELLED") {
        timelineEl.classList.add("d-none");
        cancelledBanner.classList.remove("d-none");
        if (notes && notes.includes("Cancellation")) {
            document.getElementById("cancelledReasonText").textContent = notes;
        }
        return;
    }

    timelineEl.classList.remove("d-none");
    cancelledBanner.classList.add("d-none");

    const steps = ["PENDING", "CONFIRMED", "SHIPPING", "COMPLETED"];
    const stepElements = {
        PENDING: document.getElementById("step-PENDING"),
        CONFIRMED: document.getElementById("step-CONFIRMED"),
        SHIPPING: document.getElementById("step-SHIPPING"),
        COMPLETED: document.getElementById("step-COMPLETED")
    };

    // Reset classes
    steps.forEach(s => {
        stepElements[s]?.classList.remove("completed", "active");
    });

    document.getElementById("stepDate-PENDING").textContent = formatDateTime(createdAt);

    if (status === "PENDING" || status === "PAYMENT_PENDING") {
        stepElements.PENDING?.classList.add("active");
    } else if (status === "CONFIRMED") {
        stepElements.PENDING?.classList.add("completed");
        stepElements.CONFIRMED?.classList.add("active");
    } else if (status === "SHIPPING") {
        stepElements.PENDING?.classList.add("completed");
        stepElements.CONFIRMED?.classList.add("completed");
        stepElements.SHIPPING?.classList.add("active");
    } else if (status === "COMPLETED") {
        steps.forEach(s => stepElements[s]?.classList.add("completed"));
    }
}

function getPaymentBadge(paymentStatus) {
    if (paymentStatus === "PAID") {
        return `<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1"><i class="bi bi-check-circle me-1"></i>Đã thanh toán</span>`;
    } else if (paymentStatus === "REFUNDED") {
        return `<span class="badge bg-info-subtle text-info border border-info-subtle px-2 py-1"><i class="bi bi-arrow-counterclockwise me-1"></i>Đã hoàn tiền</span>`;
    } else if (paymentStatus === "FAILED") {
        return `<span class="badge bg-danger-subtle text-danger border border-danger-subtle px-2 py-1"><i class="bi bi-slash-circle me-1"></i>Thất bại</span>`;
    } else {
        return `<span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle px-2 py-1"><i class="bi bi-hourglass-split me-1"></i>Chưa thanh toán</span>`;
    }
}

function formatCurrency(amount) {
    return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(amount || 0);
}

function formatDateTime(dateString) {
    if (!dateString) return "";
    const date = new Date(dateString);
    return date.toLocaleString("vi-VN", {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit"
    });
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
