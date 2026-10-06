import { Guard } from "../../js/auth/guard.js";
import { Auth } from "../../js/auth/auth.js";
import { OrderApi } from "../../js/api/order-api.js";

let currentPage = 0;
let totalPages = 1;
let selectedOrderId = null;
let statusModalInstance = null;
let detailModalInstance = null;

const ALLOWED_TRANSITIONS = {
    PENDING: [
        { value: "CONFIRMED", label: "Xác nhận đơn hàng (CONFIRMED)" },
        { value: "CANCELLED", label: "Hủy đơn hàng (CANCELLED)" }
    ],
    PAYMENT_PENDING: [
        { value: "CONFIRMED", label: "Xác nhận đơn hàng (CONFIRMED)" },
        { value: "CANCELLED", label: "Hủy đơn hàng (CANCELLED)" }
    ],
    CONFIRMED: [
        { value: "SHIPPING", label: "Bắt đầu giao hàng (SHIPPING)" },
        { value: "CANCELLED", label: "Hủy đơn hàng (CANCELLED)" }
    ],
    SHIPPING: [
        { value: "COMPLETED", label: "Giao thành công (COMPLETED)" },
        { value: "CANCELLED", label: "Giao thất bại / Hủy đơn (CANCELLED)" }
    ],
    COMPLETED: [],
    CANCELLED: []
};

document.addEventListener("DOMContentLoaded", async () => {
    // 1. Enforce Staff or Admin Role
    if (!Guard.requireStaff()) return;

    setupNavbar();
    setupModals();
    setupFilters();
    await loadOrders(0);
});

function setupNavbar() {
    const container = document.getElementById("adminNavContainer");
    const user = Auth.getUser();

    if (user && container) {
        container.innerHTML = `
            <div class="dropdown">
                <button class="btn btn-outline-dark btn-sm dropdown-toggle d-flex align-items-center gap-2" type="button" data-bs-toggle="dropdown">
                    <i class="bi bi-person-badge"></i>
                    <span>${escapeHtml(user.fullName || user.email)}</span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-sm">
                    <li><h6 class="dropdown-header">${escapeHtml(user.email)}</h6></li>
                    <li><a class="dropdown-item" href="../../index.html"><i class="bi bi-house me-2"></i>Trang khách hàng</a></li>
                    <li><hr class="dropdown-divider"></li>
                    <li><button class="dropdown-item text-danger" id="adminLogoutBtn"><i class="bi bi-box-arrow-right me-2"></i>Đăng xuất</button></li>
                </ul>
            </div>
        `;

        document.getElementById("adminLogoutBtn")?.addEventListener("click", () => {
            Auth.logout();
        });
    }
}

function setupModals() {
    const statusEl = document.getElementById("statusModal");
    if (statusEl) statusModalInstance = new bootstrap.Modal(statusEl);

    const detailEl = document.getElementById("adminDetailModal");
    if (detailEl) detailModalInstance = new bootstrap.Modal(detailEl);

    document.getElementById("saveStatusBtn")?.addEventListener("click", handleSaveStatus);
}

function setupFilters() {
    const filterForm = document.getElementById("filterForm");
    filterForm?.addEventListener("submit", (e) => {
        e.preventDefault();
        currentPage = 0;
        loadOrders(0);
    });

    document.getElementById("resetFilterBtn")?.addEventListener("click", () => {
        document.getElementById("searchInput").value = "";
        document.getElementById("statusFilter").value = "";
        document.getElementById("fromDateInput").value = "";
        document.getElementById("toDateInput").value = "";
        currentPage = 0;
        loadOrders(0);
    });

    document.getElementById("refreshBtn")?.addEventListener("click", () => {
        loadOrders(currentPage);
    });
}

function getFilterParams(page = 0) {
    const search = document.getElementById("searchInput")?.value.trim() || "";
    const status = document.getElementById("statusFilter")?.value || "";
    const fromDate = document.getElementById("fromDateInput")?.value || "";
    const toDate = document.getElementById("toDateInput")?.value || "";

    const params = { page, size: 15 };
    if (search) params.search = search;
    if (status) params.status = status;
    if (fromDate) params.fromDate = fromDate + "T00:00:00";
    if (toDate) params.toDate = toDate + "T23:59:59";

    return params;
}

async function loadOrders(page = 0) {
    const loadingEl = document.getElementById("adminOrdersLoading");
    const emptyEl = document.getElementById("adminOrdersEmpty");
    const tableContainer = document.getElementById("tableContainer");
    const paginationEl = document.getElementById("adminPagination");

    loadingEl.classList.remove("d-none");
    emptyEl.classList.add("d-none");
    tableContainer.classList.add("d-none");
    paginationEl.classList.add("d-none");

    try {
        const params = getFilterParams(page);
        const res = await OrderApi.getAdminOrders(params);
        const data = res.data;
        const orders = data.content || [];

        loadingEl.classList.add("d-none");

        if (orders.length === 0) {
            emptyEl.classList.remove("d-none");
            return;
        }

        currentPage = data.number;
        totalPages = data.totalPages;

        renderTable(orders);
        tableContainer.classList.remove("d-none");

        if (totalPages > 1) {
            renderPagination();
            paginationEl.classList.remove("d-none");
        }
    } catch (err) {
        loadingEl.classList.add("d-none");
        alert(err.message || "Không thể tải danh sách đơn hàng.");
    }
}

function renderTable(orders) {
    const tbody = document.getElementById("adminOrdersTbody");
    tbody.innerHTML = orders.map(order => {
        const statusBadge = getStatusBadge(order.status);
        const paymentBadge = getPaymentBadge(order.paymentStatus, order.paymentMethod);
        const dateStr = formatDateTime(order.createdAt);
        const isTerminal = order.status === "COMPLETED" || order.status === "CANCELLED";

        return `
            <tr>
                <td class="ps-3 fw-bold text-primary">#${escapeHtml(order.orderCode)}</td>
                <td class="small text-muted">${dateStr}</td>
                <td>
                    <div class="fw-semibold text-dark">${escapeHtml(order.recipientName)}</div>
                    <small class="text-muted">${escapeHtml(order.recipientPhone)}</small>
                </td>
                <td class="small text-muted">${escapeHtml(order.branchName || "Chi nhánh chính")}</td>
                <td class="text-end fw-bold text-danger">${formatCurrency(order.finalAmount)}</td>
                <td class="text-center">${paymentBadge}</td>
                <td class="text-center">${statusBadge}</td>
                <td class="text-end pe-3">
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary view-detail-btn" data-id="${order.id}" title="Xem chi tiết">
                            <i class="bi bi-eye"></i>
                        </button>
                        ${!isTerminal ? `
                            <button class="btn btn-outline-primary update-status-btn" 
                                    data-id="${order.id}" 
                                    data-code="${escapeHtml(order.orderCode)}" 
                                    data-status="${order.status}" 
                                    title="Cập nhật trạng thái">
                                <i class="bi bi-pencil-square"></i>
                            </button>
                        ` : ''}
                    </div>
                </td>
            </tr>
        `;
    }).join("");

    // Attach row events
    tbody.querySelectorAll(".view-detail-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            const id = btn.getAttribute("data-id");
            openDetailModal(id);
        });
    });

    tbody.querySelectorAll(".update-status-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            const id = btn.getAttribute("data-id");
            const code = btn.getAttribute("data-code");
            const status = btn.getAttribute("data-status");
            openStatusModal(id, code, status);
        });
    });
}

function openStatusModal(id, code, currentStatus) {
    selectedOrderId = id;
    document.getElementById("modalOrderCode").value = code;
    document.getElementById("modalCurrentStatusBadge").innerHTML = getStatusBadge(currentStatus);
    document.getElementById("modalNotesInput").value = "";

    const select = document.getElementById("modalNewStatusSelect");
    const allowed = ALLOWED_TRANSITIONS[currentStatus] || [];

    if (allowed.length === 0) {
        select.innerHTML = `<option value="">Không có trạng thái kế tiếp (Đơn hàng kết thúc)</option>`;
        document.getElementById("saveStatusBtn").disabled = true;
    } else {
        select.innerHTML = allowed.map(opt => `<option value="${opt.value}">${opt.label}</option>`).join("");
        document.getElementById("saveStatusBtn").disabled = false;
    }

    statusModalInstance?.show();
}

async function handleSaveStatus() {
    if (!selectedOrderId) return;

    const select = document.getElementById("modalNewStatusSelect");
    const status = select.value;
    const notes = document.getElementById("modalNotesInput").value.trim();

    if (!status) {
        alert("Vui lòng chọn trạng thái mới.");
        return;
    }

    const saveBtn = document.getElementById("saveStatusBtn");
    const spinner = document.getElementById("saveStatusSpinner");
    saveBtn.disabled = true;
    spinner.classList.remove("d-none");

    try {
        await OrderApi.updateOrderStatus(selectedOrderId, status, notes);
        statusModalInstance?.hide();
        alert("Cập nhật trạng thái đơn hàng thành công!");
        await loadOrders(currentPage);
    } catch (err) {
        alert(err.message || "Cập nhật thất bại.");
    } finally {
        saveBtn.disabled = false;
        spinner.classList.add("d-none");
    }
}

async function openDetailModal(orderId) {
    const modalBody = document.getElementById("adminDetailModalBody");
    modalBody.innerHTML = `
        <div class="text-center py-4">
            <div class="spinner-border text-primary spinner-border-sm"></div>
            <span class="ms-2 small text-muted">Đang tải chi tiết...</span>
        </div>
    `;
    detailModalInstance?.show();

    try {
        const res = await OrderApi.getAdminOrderDetail(orderId);
        const order = res.data;
        document.getElementById("adminDetailCode").textContent = `#${order.orderCode}`;

        const itemsHtml = (order.items || []).map(item => `
            <tr>
                <td>
                    <div class="fw-semibold">${escapeHtml(item.productName)}</div>
                    <small class="text-muted">ID: #${item.productId}</small>
                </td>
                <td class="text-center">${formatCurrency(item.unitPrice)}</td>
                <td class="text-center">${item.quantity}</td>
                <td class="text-end fw-semibold">${formatCurrency(item.totalPrice ?? item.subtotalAmount ?? (item.unitPrice * item.quantity))}</td>
            </tr>
        `).join("");

        modalBody.innerHTML = `
            <div class="row g-3 mb-3">
                <div class="col-md-6">
                    <h6 class="fw-bold small text-uppercase text-muted">Thông tin nhận hàng</h6>
                    <div class="bg-light p-3 rounded">
                        <div class="fw-bold">${escapeHtml(order.recipientName)}</div>
                        <div class="text-muted small">${escapeHtml(order.recipientPhone)}</div>
                        <div class="small">${escapeHtml(order.shippingAddress)}</div>
                        ${order.notes ? `<div class="small text-secondary mt-2 border-top pt-1"><i class="bi bi-chat-text me-1"></i>Ghi chú: ${escapeHtml(order.notes)}</div>` : ''}
                    </div>
                </div>
                <div class="col-md-6">
                    <h6 class="fw-bold small text-uppercase text-muted">Thông tin thanh toán</h6>
                    <div class="bg-light p-3 rounded">
                        <div class="d-flex justify-content-between mb-1">
                            <span class="small text-muted">Phương thức:</span>
                            <span class="small fw-semibold">${order.paymentMethod}</span>
                        </div>
                        <div class="d-flex justify-content-between mb-1">
                            <span class="small text-muted">Trạng thái:</span>
                            <span class="small">${getPaymentBadge(order.paymentStatus, order.paymentMethod)}</span>
                        </div>
                        ${order.transactionCode ? `
                            <div class="d-flex justify-content-between mb-1">
                                <span class="small text-muted">Mã GD:</span>
                                <code class="small">${escapeHtml(order.transactionCode)}</code>
                            </div>
                        ` : ''}
                        <div class="d-flex justify-content-between border-top pt-1 mt-2">
                            <span class="small fw-bold">Tổng thanh toán:</span>
                            <span class="small fw-bold text-danger">${formatCurrency(order.finalAmount)}</span>
                        </div>
                    </div>
                </div>
            </div>

            <h6 class="fw-bold small text-uppercase text-muted mb-2">Danh sách sản phẩm (${order.items?.length || 0})</h6>
            <div class="table-responsive border">
                <table class="table table-sm align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th>Sản phẩm</th>
                            <th class="text-center">Đơn giá</th>
                            <th class="text-center">Số lượng</th>
                            <th class="text-end">Thành tiền</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${itemsHtml}
                    </tbody>
                </table>
            </div>
        `;
    } catch (err) {
        modalBody.innerHTML = `<div class="alert alert-danger mb-0">${err.message || "Không thể tải chi tiết đơn hàng."}</div>`;
    }
}

function renderPagination() {
    const list = document.getElementById("adminPaginationList");
    const info = document.getElementById("pageInfoText");
    info.textContent = `Trang ${currentPage + 1} / ${totalPages}`;

    let html = "";
    for (let i = 0; i < totalPages; i++) {
        html += `
            <li class="page-item ${i === currentPage ? 'active' : ''}">
                <button class="page-link" data-page="${i}">${i + 1}</button>
            </li>
        `;
    }

    list.innerHTML = html;
    list.querySelectorAll(".page-link").forEach(btn => {
        btn.addEventListener("click", () => {
            currentPage = Number(btn.getAttribute("data-page"));
            loadOrders(currentPage);
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
            return `<span class="badge bg-primary status-badge"><i class="bi bi-truck me-1"></i>Đang vận chuyển</span>`;
        case "COMPLETED":
            return `<span class="badge bg-success status-badge"><i class="bi bi-check-all me-1"></i>Hoàn thành</span>`;
        case "CANCELLED":
            return `<span class="badge bg-danger status-badge"><i class="bi bi-x-circle me-1"></i>Đã hủy</span>`;
        default:
            return `<span class="badge bg-secondary status-badge">${escapeHtml(status)}</span>`;
    }
}

function getPaymentBadge(paymentStatus, paymentMethod) {
    let method = paymentMethod === "COD" ? "COD" : "Online";
    if (paymentStatus === "PAID") {
        return `<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1"><i class="bi bi-check-circle me-1"></i>Đã thanh toán</span>`;
    } else if (paymentStatus === "REFUNDED") {
        return `<span class="badge bg-info-subtle text-info border border-info-subtle px-2 py-1"><i class="bi bi-arrow-counterclockwise me-1"></i>Đã hoàn tiền</span>`;
    } else if (paymentStatus === "FAILED") {
        return `<span class="badge bg-danger-subtle text-danger border border-danger-subtle px-2 py-1"><i class="bi bi-slash-circle me-1"></i>Thất bại</span>`;
    } else {
        return `<span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle px-2 py-1"><i class="bi bi-cash me-1"></i>${method}: Chưa thanh toán</span>`;
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
