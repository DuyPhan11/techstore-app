import { Guard } from "../../js/auth/guard.js";
import { Auth } from "../../js/auth/auth.js";
import { OrderApi } from "../../js/api/order-api.js";
import { CartApi } from "../../js/api/cart-api.js";

let currentPage = 0;
let currentStatus = "";
let cancelOrderId = null;
let cancelModalInstance = null;

document.addEventListener("DOMContentLoaded", async () => {
    // 1. Enforce Authentication
    if (!Guard.requireAuth()) return;

    setupNavbar();
    setupStatusTabs();
    setupCancelModal();
    await updateCartBadge();
    await loadOrders(0, currentStatus);
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

function setupStatusTabs() {
    const tabs = document.querySelectorAll("#orderStatusTabs button");
    tabs.forEach(btn => {
        btn.addEventListener("click", () => {
            tabs.forEach(t => t.classList.remove("active"));
            btn.classList.add("active");
            currentStatus = btn.getAttribute("data-status") || "";
            currentPage = 0;
            loadOrders(0, currentStatus);
        });
    });
}

function setupCancelModal() {
    const modalEl = document.getElementById("cancelOrderModal");
    if (modalEl) {
        cancelModalInstance = new bootstrap.Modal(modalEl);
    }

    const reasonSelect = document.getElementById("cancelReasonSelect");
    const reasonOther = document.getElementById("cancelReasonOther");
    if (reasonSelect && reasonOther) {
        reasonSelect.addEventListener("change", () => {
            if (reasonSelect.value === "other") {
                reasonOther.classList.remove("d-none");
            } else {
                reasonOther.classList.add("d-none");
            }
        });
    }

    const confirmBtn = document.getElementById("confirmCancelBtn");
    confirmBtn?.addEventListener("click", handleConfirmCancel);
}

async function loadOrders(page = 0, status = "") {
    const loadingEl = document.getElementById("ordersLoading");
    const emptyEl = document.getElementById("ordersEmpty");
    const listEl = document.getElementById("ordersList");
    const paginationEl = document.getElementById("ordersPagination");

    loadingEl.classList.remove("d-none");
    emptyEl.classList.add("d-none");
    listEl.classList.add("d-none");
    paginationEl.classList.add("d-none");

    try {
        const res = await OrderApi.getMyOrders(page, 10);
        const data = res.data;
        let orders = data.content || [];

        // Client filter if tab status is set
        if (status) {
            orders = orders.filter(o => o.status === status);
        }

        loadingEl.classList.add("d-none");

        if (orders.length === 0) {
            emptyEl.classList.remove("d-none");
            return;
        }

        renderOrdersList(orders);
        listEl.classList.remove("d-none");

        if (data.totalPages > 1 && !status) {
            renderPagination(data.totalPages, data.number);
            paginationEl.classList.remove("d-none");
        }
    } catch (err) {
        loadingEl.classList.add("d-none");
        alert(err.message || "Không thể tải danh sách đơn hàng.");
    }
}

function renderOrdersList(orders) {
    const listEl = document.getElementById("ordersList");
    listEl.innerHTML = orders.map(order => {
        const isCancellable = ["PENDING", "PAYMENT_PENDING", "CONFIRMED"].includes(order.status);
        const statusBadge = getStatusBadge(order.status);
        const paymentBadge = getPaymentBadge(order.paymentStatus, order.paymentMethod);
        const dateStr = formatDateTime(order.createdAt);

        const itemsHtml = (order.items || []).slice(0, 3).map(item => `
            <div class="d-flex align-items-center gap-3 py-2 border-bottom">
                <img src="${item.productImage || item.productThumbnail || 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=100'}" alt="${escapeHtml(item.productName)}" class="order-thumb">
                <div class="flex-grow-1">
                    <h6 class="mb-0 fw-semibold text-truncate" style="max-width: 400px;">${escapeHtml(item.productName)}</h6>
                    <small class="text-muted">Số lượng: ${item.quantity} × ${formatCurrency(item.unitPrice)}</small>
                </div>
                <div class="text-end fw-semibold text-dark">
                    ${formatCurrency(item.totalPrice ?? item.subtotalAmount ?? (item.unitPrice * item.quantity))}
                </div>
            </div>
        `).join("");

        const moreItemsNotice = (order.items && order.items.length > 3) 
            ? `<p class="small text-muted mb-0 mt-2 text-center">+ ${order.items.length - 3} sản phẩm khác...</p>` 
            : "";

        return `
            <div class="order-card p-4">
                <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 pb-3 border-bottom">
                    <div>
                        <span class="fw-bold fs-6 text-dark me-2">Mã: #${escapeHtml(order.orderCode)}</span>
                        <span class="text-muted small"><i class="bi bi-clock me-1"></i>${dateStr}</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        ${paymentBadge}
                        ${statusBadge}
                    </div>
                </div>

                <div class="my-2">
                    ${itemsHtml}
                    ${moreItemsNotice}
                </div>

                <div class="d-flex flex-wrap align-items-center justify-content-between gap-3 pt-3 border-top mt-2">
                    <div class="text-muted small">
                        <span><i class="bi bi-geo-alt me-1 text-secondary"></i>Người nhận: <strong>${escapeHtml(order.recipientName)}</strong> (${escapeHtml(order.recipientPhone)})</span>
                    </div>
                    <div class="d-flex align-items-center gap-3">
                        <div class="text-end">
                            <span class="text-muted small d-block">Tổng số tiền:</span>
                            <span class="text-danger fw-bold fs-5">${formatCurrency(order.finalAmount)}</span>
                        </div>
                        <div class="d-flex gap-2">
                            <a href="${window.location.pathname.endsWith('.html') ? 'order-detail.html' : 'order-detail'}?id=${order.id}" class="btn btn-outline-secondary btn-sm px-3 order-detail-link" data-id="${order.id}">
                                <i class="bi bi-eye me-1"></i>Chi tiết
                            </a>
                            ${isCancellable ? `
                                <button class="btn btn-outline-danger btn-sm px-3 cancel-btn" data-id="${order.id}" data-code="${escapeHtml(order.orderCode)}">
                                    <i class="bi bi-x-circle me-1"></i>Hủy đơn
                                </button>
                            ` : ''}
                        </div>
                    </div>
                </div>
            </div>
        `;
    }).join("");

    // Attach click listeners for order detail links
    document.querySelectorAll(".order-detail-link").forEach(link => {
        link.addEventListener("click", () => {
            const id = link.getAttribute("data-id");
            if (id) {
                try {
                    localStorage.setItem("techstore_last_viewed_order_id", id);
                } catch (e) {}
            }
        });
    });

    // Attach click listeners for cancel buttons
    document.querySelectorAll(".cancel-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            cancelOrderId = btn.getAttribute("data-id");
            const code = btn.getAttribute("data-code");
            document.getElementById("cancelModalOrderCode").textContent = `#${code}`;
            cancelModalInstance?.show();
        });
    });
}

async function handleConfirmCancel() {
    if (!cancelOrderId) return;

    const select = document.getElementById("cancelReasonSelect");
    const other = document.getElementById("cancelReasonOther");
    const confirmBtn = document.getElementById("confirmCancelBtn");
    const spinner = document.getElementById("cancelBtnSpinner");

    let reason = select.value;
    if (reason === "other") {
        reason = other.value.trim() || "Khác";
    }

    confirmBtn.disabled = true;
    spinner.classList.remove("d-none");

    try {
        await OrderApi.cancelOrder(cancelOrderId, reason);
        cancelModalInstance?.hide();
        alert("Đơn hàng đã được hủy thành công!");
        await loadOrders(currentPage, currentStatus);
    } catch (err) {
        alert(err.message || "Không thể hủy đơn hàng.");
    } finally {
        confirmBtn.disabled = false;
        spinner.classList.add("d-none");
    }
}

function renderPagination(totalPages, activePage) {
    const paginationList = document.getElementById("paginationList");
    let html = "";

    for (let i = 0; i < totalPages; i++) {
        html += `
            <li class="page-item ${i === activePage ? 'active' : ''}">
                <button class="page-link" data-page="${i}">${i + 1}</button>
            </li>
        `;
    }

    paginationList.innerHTML = html;
    paginationList.querySelectorAll(".page-link").forEach(btn => {
        btn.addEventListener("click", () => {
            currentPage = Number(btn.getAttribute("data-page"));
            loadOrders(currentPage, currentStatus);
        });
    });
}

function getStatusBadge(status) {
    switch (status) {
        case "PENDING":
        case "PAYMENT_PENDING":
            return `<span class="badge bg-warning text-dark status-badge"><i class="bi bi-hourglass-split me-1"></i>Chờ xử lý</span>`;
        case "CONFIRMED":
            return `<span class="badge bg-info text-dark status-badge"><i class="bi bi-check2-circle me-1"></i>Đã xác nhận</span>`;
        case "SHIPPING":
            return `<span class="badge bg-primary status-badge"><i class="bi bi-truck me-1"></i>Đang giao hàng</span>`;
        case "COMPLETED":
            return `<span class="badge bg-success status-badge"><i class="bi bi-check-all me-1"></i>Hoàn thành</span>`;
        case "CANCELLED":
            return `<span class="badge bg-danger status-badge"><i class="bi bi-x-circle me-1"></i>Đã hủy</span>`;
        default:
            return `<span class="badge bg-secondary status-badge">${escapeHtml(status)}</span>`;
    }
}

function getPaymentBadge(paymentStatus, paymentMethod) {
    let methodText = paymentMethod === "COD" ? "COD" : "Online";
    if (paymentStatus === "PAID") {
        return `<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1"><i class="bi bi-credit-card me-1"></i>${methodText}: Đã thanh toán</span>`;
    } else if (paymentStatus === "REFUNDED") {
        return `<span class="badge bg-info-subtle text-info border border-info-subtle px-2 py-1"><i class="bi bi-arrow-counterclockwise me-1"></i>Đã hoàn tiền</span>`;
    } else if (paymentStatus === "FAILED") {
        return `<span class="badge bg-danger-subtle text-danger border border-danger-subtle px-2 py-1"><i class="bi bi-slash-circle me-1"></i>Thất bại</span>`;
    } else {
        return `<span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle px-2 py-1"><i class="bi bi-cash me-1"></i>${methodText}: Chưa thanh toán</span>`;
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
