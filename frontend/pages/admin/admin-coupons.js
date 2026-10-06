import { Guard } from "../../js/auth/guard.js";
import { Auth } from "../../js/auth/auth.js";
import { CouponApi } from "../../js/api/coupon-api.js";

let currentPage = 0;
let totalPages = 1;
let createModalInstance = null;
let editModalInstance = null;
let toastInstance = null;

document.addEventListener("DOMContentLoaded", async () => {
    // 1. Enforce Staff or Admin Role
    if (!Guard.requireStaff()) return;

    setupNavbar();
    setupModals();
    setupFilters();
    setupTypeChangeListeners();

    await loadCoupons(0);
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
    const createEl = document.getElementById("createCouponModal");
    if (createEl) createModalInstance = new bootstrap.Modal(createEl);

    const editEl = document.getElementById("editCouponModal");
    if (editEl) editModalInstance = new bootstrap.Modal(editEl);

    const toastEl = document.getElementById("adminToast");
    if (toastEl) toastInstance = new bootstrap.Toast(toastEl, { delay: 4000 });

    document.getElementById("openCreateModalBtn")?.addEventListener("click", () => {
        resetCreateForm();
        createModalInstance?.show();
    });

    document.getElementById("createCouponForm")?.addEventListener("submit", handleCreateCoupon);
    document.getElementById("editCouponForm")?.addEventListener("submit", handleEditCoupon);
}

function setupFilters() {
    const filterForm = document.getElementById("filterForm");
    filterForm?.addEventListener("submit", (e) => {
        e.preventDefault();
        currentPage = 0;
        loadCoupons(0);
    });

    document.getElementById("resetFilterBtn")?.addEventListener("click", () => {
        document.getElementById("searchInput").value = "";
        document.getElementById("typeFilter").value = "";
        document.getElementById("statusFilter").value = "";
        currentPage = 0;
        loadCoupons(0);
    });

    document.getElementById("refreshBtn")?.addEventListener("click", () => {
        loadCoupons(currentPage);
    });
}

function setupTypeChangeListeners() {
    const createType = document.getElementById("createDiscountType");
    const createVal = document.getElementById("createDiscountValue");
    const createValLabel = document.getElementById("createDiscountValueLabel");

    createType?.addEventListener("change", () => {
        if (createType.value === "PERCENTAGE") {
            createValLabel.innerHTML = `Giá trị giảm (%) <span class="text-danger">*</span>`;
            createVal.max = "100";
            createVal.placeholder = "VD: 10";
        } else {
            createValLabel.innerHTML = `Giá trị giảm (VNĐ) <span class="text-danger">*</span>`;
            createVal.removeAttribute("max");
            createVal.placeholder = "VD: 500000";
        }
    });

    const editType = document.getElementById("editDiscountType");
    const editVal = document.getElementById("editDiscountValue");
    const editValLabel = document.getElementById("editDiscountValueLabel");

    editType?.addEventListener("change", () => {
        if (editType.value === "PERCENTAGE") {
            editValLabel.innerHTML = `Giá trị giảm (%) <span class="text-danger">*</span>`;
            editVal.max = "100";
            editVal.placeholder = "VD: 10";
        } else {
            editValLabel.innerHTML = `Giá trị giảm (VNĐ) <span class="text-danger">*</span>`;
            editVal.removeAttribute("max");
            editVal.placeholder = "VD: 500000";
        }
    });
}

function resetCreateForm() {
    const form = document.getElementById("createCouponForm");
    if (!form) return;
    form.reset();

    const now = new Date();
    const future = new Date();
    future.setDate(future.getDate() + 30);

    document.getElementById("createStartDate").value = toDatetimeLocalString(now);
    document.getElementById("createEndDate").value = toDatetimeLocalString(future);
    document.getElementById("createIsActive").checked = true;
    document.getElementById("createDiscountType").value = "PERCENTAGE";
    document.getElementById("createDiscountValueLabel").innerHTML = `Giá trị giảm (%) <span class="text-danger">*</span>`;
    document.getElementById("createDiscountValue").max = "100";
}

function getFilterParams(page = 0) {
    const search = document.getElementById("searchInput")?.value.trim();
    const discountType = document.getElementById("typeFilter")?.value;
    const isActive = document.getElementById("statusFilter")?.value;

    return {
        page,
        size: 10,
        search: search || undefined,
        discountType: discountType || undefined,
        isActive: isActive !== "" ? isActive : undefined
    };
}

async function loadCoupons(page = 0) {
    showLoading(true);
    try {
        const params = getFilterParams(page);
        const res = await CouponApi.getAdminCoupons(params);

        if (res && res.success && res.data) {
            currentPage = res.data.number || 0;
            totalPages = res.data.totalPages || 1;
            renderCouponsTable(res.data.content || []);
            renderPagination(res.data);
        } else {
            showToast(res?.message || "Không thể tải danh sách mã khuyến mãi", "danger");
            renderCouponsTable([]);
        }
    } catch (err) {
        console.error("Error loading coupons:", err);
        showToast(err.message || "Lỗi khi kết nối máy chủ", "danger");
        renderCouponsTable([]);
    } finally {
        showLoading(false);
    }
}

function renderCouponsTable(coupons) {
    const tbody = document.getElementById("couponsTableBody");
    const emptyState = document.getElementById("emptyState");
    const table = document.getElementById("couponsTable");

    if (!coupons || coupons.length === 0) {
        tbody.innerHTML = "";
        emptyState?.classList.remove("d-none");
        table?.classList.add("d-none");
        return;
    }

    emptyState?.classList.add("d-none");
    table?.classList.remove("d-none");

    tbody.innerHTML = coupons.map(c => {
        const isExpired = c.expired;
        const isFullyUsed = c.fullyUsed;

        let statusBadge = "";
        if (!c.isActive) {
            statusBadge = `<span class="badge bg-secondary">Vô hiệu hóa</span>`;
        } else if (isExpired) {
            statusBadge = `<span class="badge bg-warning text-dark">Hết hạn</span>`;
        } else if (isFullyUsed) {
            statusBadge = `<span class="badge bg-danger">Hết lượt</span>`;
        } else {
            statusBadge = `<span class="badge bg-success">Đang hoạt động</span>`;
        }

        const discountDisplay = c.discountType === "PERCENTAGE"
            ? `<span class="badge bg-primary-subtle text-primary border border-primary-subtle px-2 py-1 fs-6">${c.discountValue}%</span>`
            : `<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1 fs-6">${formatVND(c.discountValue)}</span>`;

        const minOrderDisplay = c.minOrderAmount > 0
            ? `<span class="fw-semibold">${formatVND(c.minOrderAmount)}</span>`
            : `<span class="text-muted">Không yêu cầu</span>`;

        const maxDiscountDisplay = c.maxDiscountAmount
            ? `<span class="fw-semibold text-danger">${formatVND(c.maxDiscountAmount)}</span>`
            : `<span class="text-muted">Không giới hạn</span>`;

        const usagePercent = Math.min(100, Math.round((c.usedCount / c.usageLimit) * 100));

        return `
            <tr>
                <td class="ps-4">
                    <span class="coupon-code-badge">${escapeHtml(c.code)}</span>
                </td>
                <td>${discountDisplay}</td>
                <td>${minOrderDisplay}</td>
                <td>${maxDiscountDisplay}</td>
                <td>
                    <div class="small fw-semibold mb-1">${c.usedCount} / ${c.usageLimit} lượt</div>
                    <div class="progress" style="height: 6px; width: 90px;">
                        <div class="progress-bar ${usagePercent >= 100 ? 'bg-danger' : 'bg-primary'}" 
                             role="progressbar" 
                             style="width: ${usagePercent}%">
                        </div>
                    </div>
                </td>
                <td class="small">
                    <div><i class="bi bi-calendar-check text-success me-1"></i>${formatDateTime(c.startDate)}</div>
                    <div><i class="bi bi-calendar-x text-danger me-1"></i>${formatDateTime(c.endDate)}</div>
                </td>
                <td>${statusBadge}</td>
                <td class="text-end pe-4">
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-${c.isActive ? 'warning' : 'success'} toggle-status-btn" 
                                data-id="${c.id}" 
                                data-active="${c.isActive}" 
                                title="${c.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'}">
                            <i class="bi bi-${c.isActive ? 'pause-fill' : 'play-fill'}"></i>
                        </button>
                        <button class="btn btn-outline-primary edit-coupon-btn" 
                                data-id="${c.id}" 
                                title="Chỉnh sửa">
                            <i class="bi bi-pencil"></i>
                        </button>
                        <button class="btn btn-outline-danger delete-coupon-btn" 
                                data-id="${c.id}" 
                                data-code="${escapeHtml(c.code)}" 
                                title="Xóa">
                            <i class="bi bi-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join("");

    // Attach row events
    tbody.querySelectorAll(".toggle-status-btn").forEach(btn => {
        btn.addEventListener("click", () => handleToggleStatus(btn.dataset.id, btn.dataset.active === "true"));
    });

    tbody.querySelectorAll(".edit-coupon-btn").forEach(btn => {
        btn.addEventListener("click", () => openEditModal(btn.dataset.id));
    });

    tbody.querySelectorAll(".delete-coupon-btn").forEach(btn => {
        btn.addEventListener("click", () => handleDeleteCoupon(btn.dataset.id, btn.dataset.code));
    });
}

function renderPagination(pageData) {
    const info = document.getElementById("paginationInfo");
    const controls = document.getElementById("paginationControls");

    const totalElements = pageData.totalElements || 0;
    const page = pageData.number || 0;
    const size = pageData.size || 10;
    const total = pageData.totalPages || 1;

    const start = totalElements === 0 ? 0 : page * size + 1;
    const end = Math.min((page + 1) * size, totalElements);

    if (info) {
        info.innerText = `Hiển thị ${start} - ${end} của ${totalElements} mã khuyến mãi`;
    }

    if (!controls) return;

    if (total <= 1) {
        controls.innerHTML = "";
        return;
    }

    let html = `
        <li class="page-item ${page === 0 ? 'disabled' : ''}">
            <button class="page-link" data-page="${page - 1}"><i class="bi bi-chevron-left"></i></button>
        </li>
    `;

    for (let i = 0; i < total; i++) {
        if (i === 0 || i === total - 1 || (i >= page - 1 && i <= page + 1)) {
            html += `
                <li class="page-item ${i === page ? 'active' : ''}">
                    <button class="page-link" data-page="${i}">${i + 1}</button>
                </li>
            `;
        } else if (i === page - 2 || i === page + 2) {
            html += `<li class="page-item disabled"><span class="page-link">...</span></li>`;
        }
    }

    html += `
        <li class="page-item ${page === total - 1 ? 'disabled' : ''}">
            <button class="page-link" data-page="${page + 1}"><i class="bi bi-chevron-right"></i></button>
        </li>
    `;

    controls.innerHTML = html;

    controls.querySelectorAll(".page-link").forEach(link => {
        link.addEventListener("click", (e) => {
            const p = parseInt(e.currentTarget.dataset.page);
            if (!isNaN(p) && p >= 0 && p < total && p !== page) {
                currentPage = p;
                loadCoupons(p);
            }
        });
    });
}

async function handleCreateCoupon(e) {
    e.preventDefault();

    const code = document.getElementById("createCode").value.trim().toUpperCase();
    const discountType = document.getElementById("createDiscountType").value;
    const discountValue = parseFloat(document.getElementById("createDiscountValue").value);
    const minOrderAmount = parseFloat(document.getElementById("createMinOrderAmount").value) || 0;
    const maxDiscountAmountVal = document.getElementById("createMaxDiscountAmount").value.trim();
    const maxDiscountAmount = maxDiscountAmountVal ? parseFloat(maxDiscountAmountVal) : null;
    const usageLimit = parseInt(document.getElementById("createUsageLimit").value);
    const startDate = document.getElementById("createStartDate").value;
    const endDate = document.getElementById("createEndDate").value;
    const isActive = document.getElementById("createIsActive").checked;

    if (discountType === "PERCENTAGE" && discountValue > 100) {
        showToast("Phần trăm giảm giá không được vượt quá 100%", "danger");
        return;
    }

    if (new Date(endDate) <= new Date(startDate)) {
        showToast("Thời gian kết thúc phải sau thời gian bắt đầu", "danger");
        return;
    }

    const payload = {
        code,
        discountType,
        discountValue,
        minOrderAmount,
        maxDiscountAmount,
        usageLimit,
        startDate,
        endDate,
        isActive
    };

    const submitBtn = document.getElementById("submitCreateBtn");
    if (submitBtn) submitBtn.disabled = true;

    try {
        const res = await CouponApi.createCoupon(payload);
        if (res && res.success) {
            showToast("Tạo mã khuyến mãi thành công!", "success");
            createModalInstance?.hide();
            await loadCoupons(0);
        } else {
            showToast(res?.message || "Không thể tạo mã khuyến mãi", "danger");
        }
    } catch (err) {
        showToast(err.message || "Lỗi khi tạo mã khuyến mãi", "danger");
    } finally {
        if (submitBtn) submitBtn.disabled = false;
    }
}

async function openEditModal(couponId) {
    try {
        const res = await CouponApi.getCouponById(couponId);
        if (!res || !res.success || !res.data) {
            showToast("Không tìm thấy thông tin mã khuyến mãi", "danger");
            return;
        }

        const c = res.data;
        document.getElementById("editCouponId").value = c.id;
        document.getElementById("editCode").value = c.code;
        document.getElementById("editDiscountType").value = c.discountType;
        document.getElementById("editDiscountValue").value = c.discountValue;
        document.getElementById("editMinOrderAmount").value = c.minOrderAmount || 0;
        document.getElementById("editMaxDiscountAmount").value = c.maxDiscountAmount || "";
        document.getElementById("editUsageLimit").value = c.usageLimit;
        document.getElementById("editUsageHint").innerText = `Lượt đã dùng hiện tại: ${c.usedCount} / ${c.usageLimit}`;
        document.getElementById("editStartDate").value = toDatetimeLocalString(new Date(c.startDate));
        document.getElementById("editEndDate").value = toDatetimeLocalString(new Date(c.endDate));
        document.getElementById("editIsActive").checked = c.isActive;

        // Sync label & max
        const editVal = document.getElementById("editDiscountValue");
        const editValLabel = document.getElementById("editDiscountValueLabel");
        if (c.discountType === "PERCENTAGE") {
            editValLabel.innerHTML = `Giá trị giảm (%) <span class="text-danger">*</span>`;
            editVal.max = "100";
        } else {
            editValLabel.innerHTML = `Giá trị giảm (VNĐ) <span class="text-danger">*</span>`;
            editVal.removeAttribute("max");
        }

        editModalInstance?.show();
    } catch (err) {
        showToast(err.message || "Lỗi khi lấy thông tin mã khuyến mãi", "danger");
    }
}

async function handleEditCoupon(e) {
    e.preventDefault();

    const id = document.getElementById("editCouponId").value;
    const discountType = document.getElementById("editDiscountType").value;
    const discountValue = parseFloat(document.getElementById("editDiscountValue").value);
    const minOrderAmount = parseFloat(document.getElementById("editMinOrderAmount").value) || 0;
    const maxDiscountAmountVal = document.getElementById("editMaxDiscountAmount").value.trim();
    const maxDiscountAmount = maxDiscountAmountVal ? parseFloat(maxDiscountAmountVal) : null;
    const usageLimit = parseInt(document.getElementById("editUsageLimit").value);
    const startDate = document.getElementById("editStartDate").value;
    const endDate = document.getElementById("editEndDate").value;
    const isActive = document.getElementById("editIsActive").checked;

    if (discountType === "PERCENTAGE" && discountValue > 100) {
        showToast("Phần trăm giảm giá không được vượt quá 100%", "danger");
        return;
    }

    if (new Date(endDate) <= new Date(startDate)) {
        showToast("Thời gian kết thúc phải sau thời gian bắt đầu", "danger");
        return;
    }

    const payload = {
        discountType,
        discountValue,
        minOrderAmount,
        maxDiscountAmount,
        usageLimit,
        startDate,
        endDate,
        isActive
    };

    const submitBtn = document.getElementById("submitEditBtn");
    if (submitBtn) submitBtn.disabled = true;

    try {
        const res = await CouponApi.updateCoupon(id, payload);
        if (res && res.success) {
            showToast("Cập nhật mã khuyến mãi thành công!", "success");
            editModalInstance?.hide();
            await loadCoupons(currentPage);
        } else {
            showToast(res?.message || "Không thể cập nhật mã khuyến mãi", "danger");
        }
    } catch (err) {
        showToast(err.message || "Lỗi khi cập nhật mã khuyến mãi", "danger");
    } finally {
        if (submitBtn) submitBtn.disabled = false;
    }
}

async function handleToggleStatus(id, currentActive) {
    const newStatus = !currentActive;
    try {
        const res = await CouponApi.toggleStatus(id, newStatus);
        if (res && res.success) {
            showToast(`Đã ${newStatus ? 'kích hoạt' : 'vô hiệu hóa'} mã khuyến mãi!`, "success");
            await loadCoupons(currentPage);
        } else {
            showToast(res?.message || "Thao tác thất bại", "danger");
        }
    } catch (err) {
        showToast(err.message || "Lỗi cập nhật trạng thái", "danger");
    }
}

async function handleDeleteCoupon(id, code) {
    if (!confirm(`Bạn có chắc chắn muốn xóa vĩnh viễn mã khuyến mãi '${code}'?`)) {
        return;
    }

    try {
        const res = await CouponApi.deleteCoupon(id);
        if (res && res.success) {
            showToast(`Đã xóa mã khuyến mãi '${code}' thành công!`, "success");
            await loadCoupons(currentPage);
        } else {
            showToast(res?.message || "Không thể xóa mã khuyến mãi", "danger");
        }
    } catch (err) {
        showToast(err.message || "Lỗi khi xóa mã khuyến mãi", "danger");
    }
}

function showLoading(isLoading) {
    const loadingState = document.getElementById("loadingState");
    const table = document.getElementById("couponsTable");
    const emptyState = document.getElementById("emptyState");

    if (isLoading) {
        loadingState?.classList.remove("d-none");
        table?.classList.add("d-none");
        emptyState?.classList.add("d-none");
    } else {
        loadingState?.classList.add("d-none");
    }
}

function showToast(message, type = "success") {
    const toastEl = document.getElementById("adminToast");
    const toastBody = document.getElementById("adminToastBody");

    if (!toastEl || !toastBody) {
        alert(message);
        return;
    }

    toastEl.className = `toast align-items-center border-0 text-white ${type === 'danger' ? 'bg-danger' : 'bg-success'}`;
    toastBody.innerText = message;
    toastInstance?.show();
}

function formatVND(amount) {
    if (amount === undefined || amount === null) return "0 ₫";
    return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(amount);
}

function formatDateTime(dateStr) {
    if (!dateStr) return "";
    const d = new Date(dateStr);
    return d.toLocaleString("vi-VN", {
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
    });
}

function toDatetimeLocalString(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    return `${year}-${month}-${day}T${hours}:${minutes}`;
}

function escapeHtml(text) {
    if (!text) return "";
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}
