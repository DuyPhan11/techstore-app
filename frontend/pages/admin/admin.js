import { openProductEditor } from "./product-editor.js";
import { Guard } from "../../js/auth/guard.js";
import { Auth } from "../../js/auth/auth.js";
import { AdminApi } from "../../js/api/admin-api.js";
import { OrderApi } from "../../js/api/order-api.js";
import { CouponApi } from "../../js/api/coupon-api.js";

let currentTab = "dashboard";
let currentPage = 0;
let totalPages = 1;
let toastInstance = null;

// Dashboard chart instances & filter state
let timelineChartInstance = null;
let categoryChartInstance = null;
let branchChartInstance = null;
let currentDashboardDays = 30;

// Modal instances
let branchModal = null;
let staffModal = null;
let categoryModal = null;
let brandModal = null;
let adjustStockModal = null;
let transferStockModal = null;

// Cache for dropdowns
let cachedProducts = [];
let cachedBranches = [];

document.addEventListener("DOMContentLoaded", async () => {
    // 1. RBAC Guard: Requires at least STAFF role
    if (!Guard.requireStaff()) return;

    setupToast();
    document.addEventListener('click', event => {
        const edit = event.target.closest('[data-edit-product]');
        if (edit) openProductEditor(edit.dataset.editProduct, loadProductsData).catch(error => showToast(error.message, 'danger'));
    });
    setupUserSidebar();
    setupModals();
    setupTabNavigation();
    setupFilterEvents();
    setupDashboardEvents();
    setupMobileSidebar();

    // 2. Determine initial tab from URL hash
    const initialHash = window.location.hash.replace("#", "") || "dashboard";
    await switchTab(initialHash);
});

function setupToast() {
    const el = document.getElementById("adminToast");
    if (el) toastInstance = new bootstrap.Toast(el, { delay: 3500 });
}

function showToast(msg, type = "success") {
    const el = document.getElementById("adminToast");
    const body = document.getElementById("toastMessage");
    if (!el || !body) {
        alert(msg);
        return;
    }
    el.className = `toast align-items-center border-0 text-white ${type === "danger" ? "bg-danger" : "bg-success"}`;
    body.innerText = msg;
    toastInstance?.show();
}

function setupUserSidebar() {
    const user = Auth.getUser();
    if (!user) return;

    const roleBadge = document.getElementById("sidebarRoleBadge");
    const avatar = document.getElementById("userAvatarText");
    const name = document.getElementById("userNameText");
    const email = document.getElementById("userEmailText");

    const isAdmin = Auth.isAdmin();

    if (roleBadge) {
        roleBadge.innerText = isAdmin ? "ADMIN" : "STAFF";
        roleBadge.className = `badge ${isAdmin ? 'bg-danger text-white' : 'bg-warning text-dark'} admin-role-badge`;
    }

    if (name) name.innerText = user.fullName || user.email;
    if (email) email.innerText = user.email;
    if (avatar) avatar.innerText = (user.fullName || user.email).charAt(0).toUpperCase();

    // If not Admin, hide Admin-exclusive navigation items
    if (!isAdmin) {
        document.querySelectorAll(".admin-only").forEach(el => el.classList.add("d-none"));
    }

    document.getElementById("logoutBtn")?.addEventListener("click", () => Auth.logout());
}

function setupModals() {
    const bEl = document.getElementById("branchModal");
    if (bEl) branchModal = new bootstrap.Modal(bEl);

    const sEl = document.getElementById("staffModal");
    if (sEl) staffModal = new bootstrap.Modal(sEl);

    const cEl = document.getElementById("categoryModal");
    if (cEl) categoryModal = new bootstrap.Modal(cEl);

    const brEl = document.getElementById("brandModal");
    if (brEl) brandModal = new bootstrap.Modal(brEl);

    const adjEl = document.getElementById("adjustStockModal");
    if (adjEl) adjustStockModal = new bootstrap.Modal(adjEl);

    const trEl = document.getElementById("transferStockModal");
    if (trEl) transferStockModal = new bootstrap.Modal(trEl);

    // Form handlers
    document.getElementById("branchForm")?.addEventListener("submit", handleSaveBranch);
    document.getElementById("staffForm")?.addEventListener("submit", handleCreateStaff);
    document.getElementById("categoryForm")?.addEventListener("submit", handleSaveCategory);
    document.getElementById("brandForm")?.addEventListener("submit", handleSaveBrand);
    document.getElementById("adjustStockForm")?.addEventListener("submit", handleAdjustStock);
    document.getElementById("transferStockForm")?.addEventListener("submit", handleTransferStock);
}

function setupTabNavigation() {
    document.querySelectorAll(".admin-nav-item").forEach(item => {
        item.addEventListener("click", (e) => {
            const tab = item.dataset.tab;
            if (tab) {
                switchTab(tab);
            }
        });
    });

    window.addEventListener("hashchange", () => {
        const h = window.location.hash.replace("#", "");
        if (h && h !== currentTab) {
            switchTab(h);
        }
    });

    document.getElementById("refreshBtn")?.addEventListener("click", () => loadCurrentTabData());
}

function setupMobileSidebar() {
    const toggle = document.getElementById("mobileSidebarToggle");
    const sidebar = document.getElementById("adminSidebar");
    const overlay = document.getElementById("sidebarOverlay");

    toggle?.addEventListener("click", () => {
        sidebar?.classList.toggle("show");
        overlay?.classList.toggle("show");
    });

    overlay?.addEventListener("click", () => {
        sidebar?.classList.remove("show");
        overlay?.classList.remove("show");
    });
}

function setupFilterEvents() {
    const form = document.getElementById("filterForm");
    form?.addEventListener("submit", (e) => {
        e.preventDefault();
        currentPage = 0;
        loadCurrentTabData();
    });

    document.getElementById("filterResetBtn")?.addEventListener("click", () => {
        document.getElementById("filterSearch").value = "";
        document.getElementById("filterStatus").value = "";
        const extra = document.getElementById("filterExtra");
        if (extra) extra.value = "";
        currentPage = 0;
        loadCurrentTabData();
    });
}

function setupDashboardEvents() {
    const rangeGroup = document.getElementById("timelineRangeGroup");
    if (!rangeGroup) return;
    rangeGroup.querySelectorAll("button").forEach(btn => {
        btn.addEventListener("click", async () => {
            rangeGroup.querySelectorAll("button").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            const days = parseInt(btn.dataset.days, 10) || 30;
            currentDashboardDays = days;
            await loadDashboardData(currentDashboardDays);
        });
    });
}

// ==========================================
// TAB SWITCHER & HEADER SETUP
// ==========================================

async function switchTab(tab) {
    const isAdmin = Auth.isAdmin();
    const adminOnlyTabs = ["categories", "brands", "branches", "users", "staff"];

    if (adminOnlyTabs.includes(tab) && !isAdmin) {
        showToast("Bạn không có quyền truy cập chức năng này", "danger");
        tab = "dashboard";
    }

    currentTab = tab;
    window.location.hash = tab;

    // Toggle view containers
    const dashboardView = document.getElementById("dashboardView");
    const standardTableView = document.getElementById("standardTableView");
    if (tab === "dashboard") {
        dashboardView?.classList.remove("d-none");
        standardTableView?.classList.add("d-none");
    } else {
        dashboardView?.classList.add("d-none");
        standardTableView?.classList.remove("d-none");
    }

    // Update active class on nav
    document.querySelectorAll(".admin-nav-item").forEach(item => {
        item.classList.toggle("active", item.dataset.tab === tab);
    });

    currentPage = 0;
    updateTabHeader(tab);
    await loadCurrentTabData();
}

function updateTabHeader(tab) {
    const pageTitle = document.getElementById("pageTitle");
    const pageBreadcrumb = document.getElementById("pageBreadcrumb");
    const actionBtn = document.getElementById("primaryActionBtn");
    const actionIcon = document.getElementById("primaryActionIcon");
    const actionText = document.getElementById("primaryActionText");
    const secBtn = document.getElementById("secondaryActionBtn");
    const statusSelect = document.getElementById("filterStatus");
    const extraContainer = document.getElementById("extraFilterContainer");

    secBtn?.classList.add("d-none");
    actionBtn?.classList.remove("d-none");

    switch (tab) {
        case "dashboard":
            pageTitle.innerText = "Tổng Quan Báo Cáo & Thống Kê";
            pageBreadcrumb.innerText = "Trang quản trị / Báo cáo & Thống kê";
            actionBtn?.classList.add("d-none");
            secBtn?.classList.add("d-none");
            break;

        case "orders":
            pageTitle.innerText = "Quản Lý Đơn Hàng";
            pageBreadcrumb.innerText = "Trang quản trị / Đơn hàng";
            actionText.innerText = "Xem trên trang Đơn Hàng";
            actionIcon.className = "bi bi-box-arrow-up-right";
            actionBtn.onclick = () => window.location.href = "admin-orders.html";
            setupStatusFilter(["PENDING", "CONFIRMED", "SHIPPING", "COMPLETED", "CANCELLED"]);
            extraContainer?.classList.add("d-none");
            break;

        case "products":
            pageTitle.innerText = "Quản Lý Sản Phẩm";
            pageBreadcrumb.innerText = "Trang quản trị / Sản phẩm";
            actionText.innerText = "Thêm sản phẩm";
            actionIcon.className = "bi bi-plus-circle";
            actionBtn.onclick = () => showProductCreatePrompt();
            setupStatusFilter(["ACTIVE", "INACTIVE"]);
            extraContainer?.classList.add("d-none");
            break;

        case "inventory":
            pageTitle.innerText = "Quản Lý Tồn Kho Chi Nhánh";
            pageBreadcrumb.innerText = "Trang quản trị / Tồn kho";
            actionText.innerText = "Điều chỉnh kho";
            actionIcon.className = "bi bi-plus-slash-minus";
            actionBtn.onclick = () => openAdjustModal();
            secBtn?.classList.remove("d-none");
            secBtn.onclick = () => openTransferModal();
            setupStatusFilter([]);
            statusSelect.innerHTML = `
                <option value="">Tất cả tồn kho</option>
                <option value="true">Chỉ hàng sắp hết (Cảnh báo)</option>
            `;
            extraContainer?.classList.add("d-none");
            break;

        case "coupons":
            pageTitle.innerText = "Quản Lý Khuyến Mãi & Coupon";
            pageBreadcrumb.innerText = "Trang quản trị / Khuyến mãi";
            actionText.innerText = "Trang khuyến mãi đầy đủ";
            actionIcon.className = "bi bi-box-arrow-up-right";
            actionBtn.onclick = () => window.location.href = "admin-coupons.html";
            setupStatusFilter(["true", "false"], ["Đang hoạt động", "Đã tắt"]);
            extraContainer?.classList.add("d-none");
            break;

        case "categories":
            pageTitle.innerText = "Quản Lý Danh Mục Sản Phẩm";
            pageBreadcrumb.innerText = "Hệ thống / Danh mục";
            actionText.innerText = "Thêm danh mục";
            actionIcon.className = "bi bi-plus-circle";
            actionBtn.onclick = () => openCategoryModal();
            setupStatusFilter(["ACTIVE", "INACTIVE"]);
            extraContainer?.classList.add("d-none");
            break;

        case "brands":
            pageTitle.innerText = "Quản Lý Thương Hiệu";
            pageBreadcrumb.innerText = "Hệ thống / Thương hiệu";
            actionText.innerText = "Thêm thương hiệu";
            actionIcon.className = "bi bi-plus-circle";
            actionBtn.onclick = () => openBrandModal();
            setupStatusFilter(["ACTIVE", "INACTIVE"]);
            extraContainer?.classList.add("d-none");
            break;

        case "branches":
            pageTitle.innerText = "Quản Lý Hệ Thống Chi Nhánh";
            pageBreadcrumb.innerText = "Hệ thống / Chi nhánh";
            actionText.innerText = "Thêm chi nhánh";
            actionIcon.className = "bi bi-plus-circle";
            actionBtn.onclick = () => openBranchModal();
            setupStatusFilter(["ACTIVE", "INACTIVE"]);
            extraContainer?.classList.add("d-none");
            break;

        case "users":
            pageTitle.innerText = "Quản Lý Tài Khoản Khách Hàng";
            pageBreadcrumb.innerText = "Hệ thống / Người dùng";
            actionBtn?.classList.add("d-none");
            setupStatusFilter(["ACTIVE", "LOCKED"]);
            extraContainer?.classList.remove("d-none");
            setupRoleFilter();
            break;

        case "staff":
            pageTitle.innerText = "Quản Lý Đội Ngũ Nhân Viên";
            pageBreadcrumb.innerText = "Hệ thống / Nhân viên";
            actionText.innerText = "Thêm nhân viên";
            actionIcon.className = "bi bi-person-plus";
            actionBtn.onclick = () => openStaffModal();
            setupStatusFilter(["ACTIVE", "LOCKED"]);
            extraContainer?.classList.add("d-none");
            break;
    }
}

function setupStatusFilter(values, labels = null) {
    const select = document.getElementById("filterStatus");
    if (!select) return;
    let html = `<option value="">Tất cả trạng thái</option>`;
    values.forEach((v, idx) => {
        const text = labels ? labels[idx] : v;
        html += `<option value="${v}">${text}</option>`;
    });
    select.innerHTML = html;
}

function setupRoleFilter() {
    const extra = document.getElementById("filterExtra");
    if (!extra) return;
    extra.innerHTML = `
        <option value="">Tất cả vai trò</option>
        <option value="ROLE_CUSTOMER">Khách hàng (CUSTOMER)</option>
        <option value="ROLE_STAFF">Nhân viên (STAFF)</option>
        <option value="ROLE_ADMIN">Quản trị (ADMIN)</option>
    `;
}

// ==========================================
// DATA LOADING DISPATCHER
// ==========================================

async function loadCurrentTabData() {
    if (currentTab !== "dashboard") {
        showLoading(true);
    }
    try {
        switch (currentTab) {
            case "dashboard": await loadDashboardData(currentDashboardDays); break;
            case "orders": await loadOrdersData(); break;
            case "products": await loadProductsData(); break;
            case "inventory": await loadInventoryData(); break;
            case "coupons": await loadCouponsData(); break;
            case "categories": await loadCategoriesData(); break;
            case "brands": await loadBrandsData(); break;
            case "branches": await loadBranchesData(); break;
            case "users": await loadUsersData(); break;
            case "staff": await loadStaffData(); break;
        }
    } catch (err) {
        console.error("Error loading tab:", err);
        showToast(err.message || "Lỗi nạp dữ liệu", "danger");
    } finally {
        if (currentTab !== "dashboard") {
            showLoading(false);
        }
    }
}

// ==========================================
// 0. DASHBOARD MODULE
// ==========================================

async function loadDashboardData(days = 30) {
    try {
        const res = await AdminApi.getDashboardSummary(days);
        if (!res || !res.success || !res.data) {
            throw new Error(res?.message || "Không thể tải số liệu báo cáo");
        }

        const data = res.data;

        // KPI metrics
        const kpiRevenue = document.getElementById("kpiRevenue");
        const kpiOrders = document.getElementById("kpiOrders");
        const kpiCompletedOrders = document.getElementById("kpiCompletedOrders");
        const kpiCancelled = document.getElementById("kpiCancelled");
        const kpiNewCustomers = document.getElementById("kpiNewCustomers");
        const kpiTotalCustomers = document.getElementById("kpiTotalCustomers");

        if (kpiRevenue) kpiRevenue.innerText = formatVND(data.totalRevenue);
        if (kpiOrders) kpiOrders.innerText = data.totalOrders?.toLocaleString("vi-VN") || "0";
        if (kpiCompletedOrders) kpiCompletedOrders.innerText = `${data.completedOrders?.toLocaleString("vi-VN") || 0} đơn hoàn tất`;
        if (kpiCancelled) kpiCancelled.innerText = data.cancelledOrders?.toLocaleString("vi-VN") || "0";
        if (kpiNewCustomers) kpiNewCustomers.innerText = data.newCustomers?.toLocaleString("vi-VN") || "0";
        if (kpiTotalCustomers) kpiTotalCustomers.innerText = `Tổng: ${data.totalCustomers?.toLocaleString("vi-VN") || 0} khách`;

        // Render Charts
        renderTimelineChart(data.revenueOverTime || []);
        renderCategoryChart(data.revenueByCategory || []);
        renderBranchChart(data.revenueByBranch || []);

        // Render Best Sellers Table
        renderBestSellersTable(data.bestSellingProducts || []);
    } catch (err) {
        console.error("Dashboard error:", err);
        showToast(err.message || "Lỗi nạp dữ liệu thống kê", "danger");
    }
}

function renderTimelineChart(points) {
    const canvas = document.getElementById("revenueTimelineChart");
    if (!canvas) return;

    if (timelineChartInstance) {
        timelineChartInstance.destroy();
        timelineChartInstance = null;
    }

    const labels = points.map(p => {
        const parts = (p.date || "").split("-");
        return parts.length === 3 ? `${parts[2]}/${parts[1]}` : p.date;
    });
    const revenues = points.map(p => p.revenue || 0);

    const ctx = canvas.getContext("2d");
    const gradient = ctx.createLinearGradient(0, 0, 0, 300);
    gradient.addColorStop(0, "rgba(13, 110, 253, 0.25)");
    gradient.addColorStop(1, "rgba(13, 110, 253, 0.0)");

    timelineChartInstance = new Chart(canvas, {
        type: "line",
        data: {
            labels: labels,
            datasets: [{
                label: "Doanh Thu (₫)",
                data: revenues,
                borderColor: "#0d6efd",
                backgroundColor: gradient,
                borderWidth: 2.5,
                pointBackgroundColor: "#0d6efd",
                pointRadius: 3,
                pointHoverRadius: 6,
                fill: true,
                tension: 0.35
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: (ctx) => ` Doanh thu: ${formatVND(ctx.parsed.y)}`
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: (val) => {
                            if (val >= 1000000000) return (val / 1000000000).toFixed(1) + " tỷ";
                            if (val >= 1000000) return (val / 1000000).toFixed(0) + " tr";
                            if (val >= 1000) return (val / 1000).toFixed(0) + " k";
                            return val;
                        }
                    },
                    grid: { color: "rgba(0, 0, 0, 0.05)" }
                },
                x: {
                    grid: { display: false }
                }
            }
        }
    });
}

function renderCategoryChart(categories) {
    const canvas = document.getElementById("categoryDistributionChart");
    if (!canvas) return;

    if (categoryChartInstance) {
        categoryChartInstance.destroy();
        categoryChartInstance = null;
    }

    if (!categories || categories.length === 0) {
        const ctx = canvas.getContext("2d");
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        return;
    }

    const labels = categories.map(c => c.categoryName || "Khác");
    const data = categories.map(c => c.revenue || 0);

    const palette = [
        "#0d6efd", "#20c997", "#ffc107", "#fd7e14",
        "#6f42c1", "#0dcaf0", "#d63384", "#6c757d"
    ];

    categoryChartInstance = new Chart(canvas, {
        type: "doughnut",
        data: {
            labels: labels,
            datasets: [{
                data: data,
                backgroundColor: palette.slice(0, labels.length),
                borderWidth: 2,
                borderColor: "#ffffff"
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: "bottom",
                    labels: { boxWidth: 12, padding: 12 }
                },
                tooltip: {
                    callbacks: {
                        label: (ctx) => ` ${ctx.label}: ${formatVND(ctx.parsed)}`
                    }
                }
            },
            cutout: "68%"
        }
    });
}

function renderBranchChart(branches) {
    const canvas = document.getElementById("branchPerformanceChart");
    if (!canvas) return;

    if (branchChartInstance) {
        branchChartInstance.destroy();
        branchChartInstance = null;
    }

    if (!branches || branches.length === 0) {
        const ctx = canvas.getContext("2d");
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        return;
    }

    const labels = branches.map(b => b.branchName || "Chi nhánh");
    const revenues = branches.map(b => b.revenue || 0);

    branchChartInstance = new Chart(canvas, {
        type: "bar",
        data: {
            labels: labels,
            datasets: [{
                label: "Doanh thu",
                data: revenues,
                backgroundColor: "#198754",
                borderRadius: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: (ctx) => ` Doanh thu: ${formatVND(ctx.parsed.y)}`
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: (val) => {
                            if (val >= 1000000000) return (val / 1000000000).toFixed(1) + " tỷ";
                            if (val >= 1000000) return (val / 1000000).toFixed(0) + " tr";
                            if (val >= 1000) return (val / 1000).toFixed(0) + " k";
                            return val;
                        }
                    },
                    grid: { color: "rgba(0, 0, 0, 0.05)" }
                },
                x: {
                    grid: { display: false }
                }
            }
        }
    });
}

function renderBestSellersTable(products) {
    const tbody = document.getElementById("bestSellersTableBody");
    if (!tbody) return;

    if (!products || products.length === 0) {
        tbody.innerHTML = `<tr><td colspan="5" class="text-center py-4 text-muted">Chưa có sản phẩm nào được bán</td></tr>`;
        return;
    }

    const badges = [
        '<span class="badge bg-warning text-dark"><i class="bi bi-trophy-fill me-1"></i>#1</span>',
        '<span class="badge bg-secondary"><i class="bi bi-award-fill me-1"></i>#2</span>',
        '<span class="badge bg-bronze" style="background:#cd7f32; color:white;"><i class="bi bi-award me-1"></i>#3</span>',
        '<span class="badge bg-light text-dark border">#4</span>',
        '<span class="badge bg-light text-dark border">#5</span>'
    ];

    tbody.innerHTML = products.map((p, idx) => {
        const badge = badges[idx] || `<span class="badge bg-light text-dark border">#${idx + 1}</span>`;
        const imgUrl = p.productImage || "../../assets/images/placeholder.png";

        return `
            <tr>
                <td>${badge}</td>
                <td>
                    <div class="d-flex align-items-center gap-3">
                        <img src="${escapeHtml(imgUrl)}" alt="${escapeHtml(p.productName)}"
                             class="rounded border" style="width: 44px; height: 44px; object-fit: cover;"
                             onerror="this.src='../../assets/images/placeholder.png'">
                        <div>
                            <div class="fw-semibold text-truncate" style="max-width: 320px;" title="${escapeHtml(p.productName)}">
                                ${escapeHtml(p.productName)}
                            </div>
                            <small class="text-muted">ID: ${p.productId}</small>
                        </div>
                    </div>
                </td>
                <td><span class="badge bg-light text-dark border font-monospace">${escapeHtml(p.productSku || "-")}</span></td>
                <td class="text-center fw-bold text-success fs-6">${p.quantitySold?.toLocaleString("vi-VN") || 0}</td>
                <td class="text-end fw-bold text-primary">${formatVND(p.totalRevenue)}</td>
            </tr>
        `;
    }).join("");
}

// ==========================================
// 1. ORDERS MODULE
// ==========================================

async function loadOrdersData() {
    const search = document.getElementById("filterSearch")?.value.trim();
    const status = document.getElementById("filterStatus")?.value;

    const res = await OrderApi.getAdminOrders({ page: currentPage, size: 10, search, status });
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải đơn hàng");

    renderTable(
        ["Mã Đơn", "Khách Hàng", "Ngày Đặt", "Tổng Tiền", "Thanh Toán", "Trạng Thái", "Thao Tác"],
        res.data.content,
        (o) => `
            <tr>
                <td class="fw-bold text-primary font-monospace">${escapeHtml(o.orderCode)}</td>
                <td>
                    <div class="fw-semibold">${escapeHtml(o.recipientName)}</div>
                    <small class="text-muted">${escapeHtml(o.recipientPhone)}</small>
                </td>
                <td class="small">${formatDateTime(o.createdAt)}</td>
                <td class="fw-bold text-danger">${formatVND(o.finalAmount)}</td>
                <td><span class="badge bg-light text-dark border">${o.paymentMethod}</span></td>
                <td>${getOrderStatusBadge(o.status)}</td>
                <td>
                    <a href="admin-orders.html" class="btn btn-outline-primary btn-sm" title="Quản lý chi tiết">
                        <i class="bi bi-eye"></i>
                    </a>
                </td>
            </tr>
        `
    );
    renderPagination(res.data);
}

// ==========================================
// 2. PRODUCTS MODULE
// ==========================================

async function loadProductsData() {
    const keyword = document.getElementById("filterSearch")?.value.trim();
    const status = document.getElementById("filterStatus")?.value;

    const res = await AdminApi.getProducts({ page: currentPage, size: 10, keyword, status });
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải sản phẩm");

    renderTable(
        ["Mã SKU", "Tên Sản Phẩm", "Giá Bán", "Trạng Thái", "Thao Tác"],
        res.data.content,
        (p) => `
            <tr>
                <td class="font-monospace fw-semibold">${escapeHtml(p.sku || "N/A")}</td>
                <td>
                    <div class="d-flex align-items-center gap-2">
                        <img src="${escapeHtml(p.primaryImageUrl || '/assets/images/placeholder.svg')}" alt="" class="rounded" width="40" height="40" style="object-fit: cover;">
                        <span class="fw-semibold text-truncate" style="max-width: 280px;">${escapeHtml(p.name)}</span>
                    </div>
                </td>
                <td class="fw-bold text-primary">${formatVND(p.price)}</td>
                <td>${getProductStatusBadge(p.status)}</td>
                <td>
                    <button class="btn btn-outline-primary btn-sm" data-edit-product="${p.id}" title="Sửa sản phẩm"><i class="bi bi-pencil"></i></button>
                    <a href="../products/product-detail.html?id=${p.id}" target="_blank" class="btn btn-outline-secondary btn-sm" title="Xem trên cửa hàng">
                        <i class="bi bi-box-arrow-up-right"></i>
                    </a>
                </td>
            </tr>
        `
    );
    renderPagination(res.data);
}

// ==========================================
// 3. INVENTORY MODULE
// ==========================================

async function loadInventoryData() {
    const search = document.getElementById("filterSearch")?.value.trim();
    const lowStock = document.getElementById("filterStatus")?.value;

    const res = await AdminApi.getInventory({ page: currentPage, size: 10, search, lowStock: lowStock || undefined });
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải tồn kho");

    renderTable(
        ["Chi Nhánh", "Sản Phẩm", "Mã SKU", "Tồn Kho Hiện Tại", "Cảnh Báo", "Trạng Thái Kho", "Thao Tác"],
        res.data.content,
        (i) => `
            <tr>
                <td class="fw-semibold"><i class="bi bi-geo-alt text-danger me-1"></i>${escapeHtml(i.branchName)}</td>
                <td class="fw-semibold text-truncate" style="max-width: 250px;">${escapeHtml(i.productName)}</td>
                <td class="font-monospace small">${escapeHtml(i.productSku)}</td>
                <td class="fw-bold fs-6 ${i.isLowStock ? 'text-danger' : 'text-success'}">${i.quantity}</td>
                <td class="text-muted small">&le; ${i.minStockAlert}</td>
                <td>
                    ${i.isLowStock 
                        ? '<span class="badge bg-danger"><i class="bi bi-exclamation-triangle me-1"></i>Sắp hết hàng</span>' 
                        : '<span class="badge bg-success"><i class="bi bi-check-circle me-1"></i>Đầy đủ</span>'}
                </td>
                <td>
                    <button class="btn btn-outline-primary btn-sm quick-adjust-btn" data-product="${i.productId}" data-branch="${i.branchId}">
                        <i class="bi bi-sliders me-1"></i>Chỉnh
                    </button>
                </td>
            </tr>
        `
    );
    renderPagination(res.data);

    document.querySelectorAll(".quick-adjust-btn").forEach(btn => {
        btn.addEventListener("click", () => openAdjustModal(btn.dataset.product, btn.dataset.branch));
    });
}

// ==========================================
// 4. COUPONS MODULE
// ==========================================

async function loadCouponsData() {
    const search = document.getElementById("filterSearch")?.value.trim();
    const isActive = document.getElementById("filterStatus")?.value;

    const res = await CouponApi.getAdminCoupons({ page: currentPage, size: 10, search, isActive: isActive || undefined });
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải mã khuyến mãi");

    renderTable(
        ["Mã Code", "Loại & Giảm", "Đơn Tối Thiểu", "Lượt Dùng", "Hạn Dùng", "Trạng Thái", "Thao Tác"],
        res.data.content,
        (c) => `
            <tr>
                <td class="font-monospace fw-bold text-primary">${escapeHtml(c.code)}</td>
                <td>${c.discountType === 'PERCENTAGE' ? c.discountValue + '%' : formatVND(c.discountValue)}</td>
                <td>${formatVND(c.minOrderAmount)}</td>
                <td>${c.usedCount} / ${c.usageLimit}</td>
                <td class="small">${formatDateTime(c.endDate)}</td>
                <td>${c.isActive ? '<span class="badge bg-success">Đang bật</span>' : '<span class="badge bg-secondary">Đã tắt</span>'}</td>
                <td>
                    <a href="admin-coupons.html" class="btn btn-outline-primary btn-sm" title="Quản lý chi tiết">
                        <i class="bi bi-pencil"></i>
                    </a>
                </td>
            </tr>
        `
    );
    renderPagination(res.data);
}

// ==========================================
// 5. CATEGORIES MODULE (Admin)
// ==========================================

async function loadCategoriesData() {
    const status = document.getElementById("filterStatus")?.value;
    const res = await AdminApi.getCategories(status);
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải danh mục");

    renderTable(
        ["ID", "Tên Danh Mục", "Slug", "Mô Tả", "Trạng Thái", "Thao Tác"],
        res.data,
        (c) => `
            <tr>
                <td class="text-muted">#${c.id}</td>
                <td class="fw-bold">${escapeHtml(c.name)}</td>
                <td class="font-monospace text-muted small">${escapeHtml(c.slug)}</td>
                <td class="text-muted small">${escapeHtml(c.description || "")}</td>
                <td>${c.status === 'ACTIVE' ? '<span class="badge bg-success">Hoạt động</span>' : '<span class="badge bg-secondary">Tạm dừng</span>'}</td>
                <td>
                    <button class="btn btn-outline-primary btn-sm edit-cat-btn" data-id="${c.id}" data-name="${escapeHtml(c.name)}" data-desc="${escapeHtml(c.description || '')}" data-img="${escapeHtml(c.imageUrl || '')}">
                        <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-outline-danger btn-sm del-cat-btn" data-id="${c.id}" data-name="${escapeHtml(c.name)}">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        `
    );
    hidePagination();

    document.querySelectorAll(".edit-cat-btn").forEach(btn => {
        btn.addEventListener("click", () => openCategoryModal(btn.dataset.id, btn.dataset.name, btn.dataset.desc, btn.dataset.img));
    });
    document.querySelectorAll(".del-cat-btn").forEach(btn => {
        btn.addEventListener("click", () => handleDeleteCategory(btn.dataset.id, btn.dataset.name));
    });
}

// ==========================================
// 6. BRANDS MODULE (Admin)
// ==========================================

async function loadBrandsData() {
    const status = document.getElementById("filterStatus")?.value;
    const res = await AdminApi.getBrands(status);
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải thương hiệu");

    renderTable(
        ["ID", "Tên Thương Hiệu", "Slug", "Mô Tả", "Trạng Thái", "Thao Tác"],
        res.data,
        (b) => `
            <tr>
                <td class="text-muted">#${b.id}</td>
                <td class="fw-bold">${escapeHtml(b.name)}</td>
                <td class="font-monospace text-muted small">${escapeHtml(b.slug)}</td>
                <td class="text-muted small">${escapeHtml(b.description || "")}</td>
                <td>${b.status === 'ACTIVE' ? '<span class="badge bg-success">Hoạt động</span>' : '<span class="badge bg-secondary">Tạm dừng</span>'}</td>
                <td>
                    <button class="btn btn-outline-primary btn-sm edit-brand-btn" data-id="${b.id}" data-name="${escapeHtml(b.name)}" data-desc="${escapeHtml(b.description || '')}" data-logo="${escapeHtml(b.logoUrl || '')}">
                        <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-outline-danger btn-sm del-brand-btn" data-id="${b.id}" data-name="${escapeHtml(b.name)}">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        `
    );
    hidePagination();

    document.querySelectorAll(".edit-brand-btn").forEach(btn => {
        btn.addEventListener("click", () => openBrandModal(btn.dataset.id, btn.dataset.name, btn.dataset.desc, btn.dataset.logo));
    });
    document.querySelectorAll(".del-brand-btn").forEach(btn => {
        btn.addEventListener("click", () => handleDeleteBrand(btn.dataset.id, btn.dataset.name));
    });
}

// ==========================================
// 7. BRANCHES MODULE (Admin)
// ==========================================

async function loadBranchesData() {
    const status = document.getElementById("filterStatus")?.value;
    const res = await AdminApi.getBranches(status);
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải chi nhánh");

    renderTable(
        ["ID", "Tên Chi Nhánh", "Số Điện Thoại", "Địa Chỉ", "Trạng Thái", "Thao Tác"],
        res.data,
        (b) => `
            <tr>
                <td class="text-muted">#${b.id}</td>
                <td class="fw-bold">${escapeHtml(b.name)}</td>
                <td>${escapeHtml(b.phone || "N/A")}</td>
                <td class="small text-truncate" style="max-width: 250px;">${escapeHtml(b.address)}</td>
                <td>${b.status === 'ACTIVE' ? '<span class="badge bg-success">Hoạt động</span>' : '<span class="badge bg-secondary">Tạm dừng</span>'}</td>
                <td>
                    <button class="btn btn-outline-primary btn-sm edit-branch-btn" data-id="${b.id}" data-name="${escapeHtml(b.name)}" data-phone="${escapeHtml(b.phone || '')}" data-address="${escapeHtml(b.address)}" data-status="${b.status}">
                        <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-outline-danger btn-sm del-branch-btn" data-id="${b.id}" data-name="${escapeHtml(b.name)}">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        `
    );
    hidePagination();

    document.querySelectorAll(".edit-branch-btn").forEach(btn => {
        btn.addEventListener("click", () => openBranchModal(btn.dataset.id, btn.dataset.name, btn.dataset.phone, btn.dataset.address, btn.dataset.status));
    });
    document.querySelectorAll(".del-branch-btn").forEach(btn => {
        btn.addEventListener("click", () => handleDeleteBranch(btn.dataset.id, btn.dataset.name));
    });
}

// ==========================================
// 8. USERS MODULE (Admin)
// ==========================================

async function loadUsersData() {
    const search = document.getElementById("filterSearch")?.value.trim();
    const status = document.getElementById("filterStatus")?.value;
    const role = document.getElementById("filterExtra")?.value;

    const res = await AdminApi.getUsers({ page: currentPage, size: 10, search, status, role });
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải người dùng");

    renderTable(
        ["Họ & Tên", "Email", "Số Điện Thoại", "Vai Trò", "Trạng Thái", "Ngày Tạo", "Thao Tác"],
        res.data.content,
        (u) => `
            <tr>
                <td class="fw-semibold">${escapeHtml(u.fullName)}</td>
                <td class="font-monospace small">${escapeHtml(u.email)}</td>
                <td>${escapeHtml(u.phone)}</td>
                <td>${u.roles.map(r => `<span class="badge badge-role">${r.replace('ROLE_', '')}</span>`).join('')}</td>
                <td>
                    ${u.status === 'ACTIVE' 
                        ? '<span class="badge badge-status-active">Hoạt động</span>' 
                        : '<span class="badge badge-status-locked">Đã khóa</span>'}
                </td>
                <td class="small text-muted">${formatDateTime(u.createdAt)}</td>
                <td>
                    <button class="btn btn-outline-${u.status === 'ACTIVE' ? 'warning' : 'success'} btn-sm toggle-user-btn" data-id="${u.id}" data-status="${u.status}" data-email="${escapeHtml(u.email)}">
                        <i class="bi bi-${u.status === 'ACTIVE' ? 'lock' : 'unlock'}"></i>
                    </button>
                </td>
            </tr>
        `
    );
    renderPagination(res.data);

    document.querySelectorAll(".toggle-user-btn").forEach(btn => {
        btn.addEventListener("click", () => handleToggleUserStatus(btn.dataset.id, btn.dataset.status, btn.dataset.email));
    });
}

// ==========================================
// 9. STAFF MODULE (Admin)
// ==========================================

async function loadStaffData() {
    const search = document.getElementById("filterSearch")?.value.trim();
    const status = document.getElementById("filterStatus")?.value;

    const res = await AdminApi.getStaff({ page: currentPage, size: 10, search, status });
    if (!res || !res.success || !res.data) throw new Error(res?.message || "Không thể tải nhân viên");

    renderTable(
        ["Họ & Tên", "Email", "Số Điện Thoại", "Trạng Thái", "Ngày Tham Gia", "Thao Tác"],
        res.data.content,
        (s) => `
            <tr>
                <td class="fw-semibold"><i class="bi bi-person-badge text-primary me-2"></i>${escapeHtml(s.fullName)}</td>
                <td class="font-monospace small">${escapeHtml(s.email)}</td>
                <td>${escapeHtml(s.phone)}</td>
                <td>
                    ${s.status === 'ACTIVE' 
                        ? '<span class="badge badge-status-active">Đang làm việc</span>' 
                        : '<span class="badge badge-status-locked">Đã vô hiệu</span>'}
                </td>
                <td class="small text-muted">${formatDateTime(s.createdAt)}</td>
                <td>
                    <button class="btn btn-outline-${s.status === 'ACTIVE' ? 'warning' : 'success'} btn-sm toggle-staff-btn" data-id="${s.id}" data-status="${s.status}" data-email="${escapeHtml(s.email)}">
                        <i class="bi bi-${s.status === 'ACTIVE' ? 'pause-fill' : 'play-fill'}"></i>
                    </button>
                </td>
            </tr>
        `
    );
    renderPagination(res.data);

    document.querySelectorAll(".toggle-staff-btn").forEach(btn => {
        btn.addEventListener("click", () => handleToggleStaffStatus(btn.dataset.id, btn.dataset.status, btn.dataset.email));
    });
}

// ==========================================
// MODAL TRIGGERS & SUBMITS
// ==========================================

function openBranchModal(id = "", name = "", phone = "", address = "", status = "ACTIVE") {
    document.getElementById("branchId").value = id;
    document.getElementById("branchName").value = name;
    document.getElementById("branchPhone").value = phone;
    document.getElementById("branchAddress").value = address;
    document.getElementById("branchStatus").value = status;
    document.getElementById("branchModalTitle").innerText = id ? "Chỉnh Sửa Chi Nhánh" : "Thêm Chi Nhánh Mới";
    branchModal?.show();
}

async function handleSaveBranch(e) {
    e.preventDefault();
    const id = document.getElementById("branchId").value;
    const name = document.getElementById("branchName").value.trim();
    const phone = document.getElementById("branchPhone").value.trim();
    const address = document.getElementById("branchAddress").value.trim();
    const status = document.getElementById("branchStatus").value;

    try {
        if (id) {
            await AdminApi.updateBranch(id, { name, phone, address, status });
            showToast("Cập nhật chi nhánh thành công!");
        } else {
            await AdminApi.createBranch({ name, phone, address, status });
            showToast("Tạo chi nhánh mới thành công!");
        }
        branchModal?.hide();
        await loadBranchesData();
    } catch (err) {
        showToast(err.message || "Lỗi lưu chi nhánh", "danger");
    }
}

async function handleDeleteBranch(id, name) {
    if (!confirm(`Bạn có chắc chắn muốn ngừng hoạt động chi nhánh '${name}'?`)) return;
    try {
        await AdminApi.deleteBranch(id);
        showToast(`Đã ngừng hoạt động chi nhánh '${name}'!`);
        await loadBranchesData();
    } catch (err) {
        showToast(err.message || "Lỗi xóa chi nhánh", "danger");
    }
}

function openStaffModal() {
    document.getElementById("staffForm").reset();
    document.getElementById("staffPassword").value = "password123";
    staffModal?.show();
}

async function handleCreateStaff(e) {
    e.preventDefault();
    const fullName = document.getElementById("staffFullName").value.trim();
    const email = document.getElementById("staffEmail").value.trim();
    const phone = document.getElementById("staffPhone").value.trim();
    const password = document.getElementById("staffPassword").value;

    try {
        await AdminApi.createStaff({ fullName, email, phone, password });
        showToast("Tạo tài khoản nhân viên thành công!");
        staffModal?.hide();
        await loadStaffData();
    } catch (err) {
        showToast(err.message || "Lỗi tạo nhân viên", "danger");
    }
}

async function handleToggleUserStatus(id, currentStatus, email) {
    const newStatus = currentStatus === "ACTIVE" ? "LOCKED" : "ACTIVE";
    const msg = newStatus === "LOCKED" ? `khóa tài khoản '${email}'` : `mở khóa tài khoản '${email}'`;
    if (!confirm(`Bạn có chắc muốn ${msg}?`)) return;

    try {
        await AdminApi.updateUserStatus(id, newStatus);
        showToast(`Cập nhật trạng thái người dùng thành công!`);
        await loadUsersData();
    } catch (err) {
        showToast(err.message || "Lỗi cập nhật", "danger");
    }
}

async function handleToggleStaffStatus(id, currentStatus, email) {
    const newStatus = currentStatus === "ACTIVE" ? "LOCKED" : "ACTIVE";
    const msg = newStatus === "LOCKED" ? `vô hiệu hóa nhân viên '${email}'` : `kích hoạt lại nhân viên '${email}'`;
    if (!confirm(`Bạn có chắc muốn ${msg}?`)) return;

    try {
        await AdminApi.updateStaffStatus(id, newStatus);
        showToast(`Cập nhật trạng thái nhân viên thành công!`);
        await loadStaffData();
    } catch (err) {
        showToast(err.message || "Lỗi cập nhật", "danger");
    }
}

function openCategoryModal(id = "", name = "", desc = "", img = "") {
    document.getElementById("categoryId").value = id;
    document.getElementById("categoryName").value = name;
    document.getElementById("categoryDescription").value = desc;
    document.getElementById("categoryImageUrl").value = img;
    document.getElementById("categoryModalTitle").innerText = id ? "Sửa Danh Mục" : "Thêm Danh Mục Mới";
    categoryModal?.show();
}

async function handleSaveCategory(e) {
    e.preventDefault();
    const id = document.getElementById("categoryId").value;
    const name = document.getElementById("categoryName").value.trim();
    const description = document.getElementById("categoryDescription").value.trim();
    const imageUrl = document.getElementById("categoryImageUrl").value.trim();

    try {
        if (id) {
            await AdminApi.updateCategory(id, { name, description, imageUrl });
            showToast("Cập nhật danh mục thành công!");
        } else {
            await AdminApi.createCategory({ name, description, imageUrl });
            showToast("Thêm danh mục mới thành công!");
        }
        categoryModal?.hide();
        await loadCategoriesData();
    } catch (err) {
        showToast(err.message || "Lỗi lưu danh mục", "danger");
    }
}

async function handleDeleteCategory(id, name) {
    if (!confirm(`Bạn có chắc chắn muốn xóa danh mục '${name}'?`)) return;
    try {
        await AdminApi.deleteCategory(id);
        showToast(`Đã xóa danh mục '${name}'!`);
        await loadCategoriesData();
    } catch (err) {
        showToast(err.message || "Lỗi xóa danh mục", "danger");
    }
}

function openBrandModal(id = "", name = "", desc = "", logo = "") {
    document.getElementById("brandId").value = id;
    document.getElementById("brandName").value = name;
    document.getElementById("brandDescription").value = desc;
    document.getElementById("brandLogoUrl").value = logo;
    document.getElementById("brandModalTitle").innerText = id ? "Sửa Thương Hiệu" : "Thêm Thương Hiệu Mới";
    brandModal?.show();
}

async function handleSaveBrand(e) {
    e.preventDefault();
    const id = document.getElementById("brandId").value;
    const name = document.getElementById("brandName").value.trim();
    const description = document.getElementById("brandDescription").value.trim();
    const logoUrl = document.getElementById("brandLogoUrl").value.trim();

    try {
        if (id) {
            await AdminApi.updateBrand(id, { name, description, logoUrl });
            showToast("Cập nhật thương hiệu thành công!");
        } else {
            await AdminApi.createBrand({ name, description, logoUrl });
            showToast("Thêm thương hiệu mới thành công!");
        }
        brandModal?.hide();
        await loadBrandsData();
    } catch (err) {
        showToast(err.message || "Lỗi lưu thương hiệu", "danger");
    }
}

async function handleDeleteBrand(id, name) {
    if (!confirm(`Bạn có chắc chắn muốn xóa thương hiệu '${name}'?`)) return;
    try {
        await AdminApi.deleteBrand(id);
        showToast(`Đã xóa thương hiệu '${name}'!`);
        await loadBrandsData();
    } catch (err) {
        showToast(err.message || "Lỗi xóa thương hiệu", "danger");
    }
}

async function ensureCachedData() {
    if (cachedProducts.length === 0) {
        const resP = await AdminApi.getProducts({ size: 100 });
        if (resP?.data?.content) cachedProducts = resP.data.content;
    }
    if (cachedBranches.length === 0) {
        const resB = await AdminApi.getBranches("ACTIVE");
        if (resB?.data) cachedBranches = resB.data;
    }
}

async function openAdjustModal(productId = null, branchId = null) {
    await ensureCachedData();

    const pSelect = document.getElementById("adjustProductId");
    const bSelect = document.getElementById("adjustBranchId");

    pSelect.innerHTML = cachedProducts.map(p => `<option value="${p.id}" ${p.id == productId ? 'selected' : ''}>${escapeHtml(p.name)}</option>`).join("");
    bSelect.innerHTML = cachedBranches.map(b => `<option value="${b.id}" ${b.id == branchId ? 'selected' : ''}>${escapeHtml(b.name)}</option>`).join("");

    document.getElementById("adjustQuantity").value = 10;
    document.getElementById("adjustReason").value = "";
    adjustStockModal?.show();
}

async function handleAdjustStock(e) {
    e.preventDefault();
    const productId = parseInt(document.getElementById("adjustProductId").value);
    const branchId = parseInt(document.getElementById("adjustBranchId").value);
    const adjustmentType = document.getElementById("adjustType").value;
    const quantity = parseInt(document.getElementById("adjustQuantity").value);
    const reason = document.getElementById("adjustReason").value.trim();

    try {
        await AdminApi.adjustStock({ productId, branchId, adjustmentType, quantity, reason });
        showToast("Điều chỉnh tồn kho thành công!");
        adjustStockModal?.hide();
        await loadInventoryData();
    } catch (err) {
        showToast(err.message || "Lỗi điều chỉnh tồn kho", "danger");
    }
}

async function openTransferModal() {
    await ensureCachedData();

    const pSelect = document.getElementById("transferProductId");
    const fbSelect = document.getElementById("transferFromBranchId");
    const tbSelect = document.getElementById("transferToBranchId");

    pSelect.innerHTML = cachedProducts.map(p => `<option value="${p.id}">${escapeHtml(p.name)}</option>`).join("");
    fbSelect.innerHTML = cachedBranches.map(b => `<option value="${b.id}">${escapeHtml(b.name)}</option>`).join("");
    tbSelect.innerHTML = cachedBranches.map((b, i) => `<option value="${b.id}" ${i === 1 ? 'selected' : ''}>${escapeHtml(b.name)}</option>`).join("");

    document.getElementById("transferQuantity").value = 5;
    document.getElementById("transferNotes").value = "";
    transferStockModal?.show();
}

async function handleTransferStock(e) {
    e.preventDefault();
    const productId = parseInt(document.getElementById("transferProductId").value);
    const fromBranchId = parseInt(document.getElementById("transferFromBranchId").value);
    const toBranchId = parseInt(document.getElementById("transferToBranchId").value);
    const quantity = parseInt(document.getElementById("transferQuantity").value);
    const notes = document.getElementById("transferNotes").value.trim();

    if (fromBranchId === toBranchId) {
        showToast("Chi nhánh xuất và nhập không được trùng nhau!", "danger");
        return;
    }

    try {
        await AdminApi.transferStock({ productId, fromBranchId, toBranchId, quantity, notes });
        showToast("Điều chuyển kho thành công!");
        transferStockModal?.hide();
        await loadInventoryData();
    } catch (err) {
        showToast(err.message || "Lỗi điều chuyển kho", "danger");
    }
}

function showProductCreatePrompt() {
    openProductEditor(null, loadProductsData).catch(error => showToast(error.message, "danger"));
}

// ==========================================
// RENDER HELPERS
// ==========================================

function renderTable(headers, rows, rowRenderer) {
    const thead = document.getElementById("tableHead");
    const tbody = document.getElementById("tableBody");
    const emptyState = document.getElementById("emptyState");
    const table = document.getElementById("dataTable");

    thead.innerHTML = `<tr>${headers.map(h => `<th>${h}</th>`).join('')}</tr>`;

    if (!rows || rows.length === 0) {
        tbody.innerHTML = "";
        emptyState?.classList.remove("d-none");
        table?.classList.add("d-none");
        return;
    }

    emptyState?.classList.add("d-none");
    table?.classList.remove("d-none");
    tbody.innerHTML = rows.map(rowRenderer).join("");
}

function renderPagination(pageData) {
    const info = document.getElementById("paginationInfo");
    const controls = document.getElementById("paginationControls");

    const totalElements = pageData.totalElements || 0;
    const page = pageData.number !== undefined ? pageData.number : (pageData.pageNumber || 0);
    const size = pageData.size !== undefined ? pageData.size : (pageData.pageSize || 10);
    const total = pageData.totalPages || 1;

    totalPages = total;
    currentPage = page;

    const start = totalElements === 0 ? 0 : page * size + 1;
    const end = Math.min((page + 1) * size, totalElements);

    if (info) info.innerText = `Hiển thị ${start} - ${end} của ${totalElements} kết quả`;
    if (!controls) return;

    if (total <= 1) {
        controls.innerHTML = "";
        return;
    }

    let html = `
        <li class="page-item ${page === 0 ? 'disabled' : ''}">
            <button class="page-link" data-page="${page - 1}">&laquo;</button>
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
            <button class="page-link" data-page="${page + 1}">&raquo;</button>
        </li>
    `;

    controls.innerHTML = html;
    controls.querySelectorAll(".page-link").forEach(btn => {
        btn.addEventListener("click", (e) => {
            const p = parseInt(e.currentTarget.dataset.page);
            if (!isNaN(p) && p >= 0 && p < total && p !== currentPage) {
                currentPage = p;
                loadCurrentTabData();
            }
        });
    });
}

function hidePagination() {
    const info = document.getElementById("paginationInfo");
    const controls = document.getElementById("paginationControls");
    if (info) info.innerText = "";
    if (controls) controls.innerHTML = "";
}

function showLoading(isLoading) {
    const loader = document.getElementById("loadingState");
    const table = document.getElementById("dataTable");
    const empty = document.getElementById("emptyState");

    if (isLoading) {
        loader?.classList.remove("d-none");
        table?.classList.add("d-none");
        empty?.classList.add("d-none");
    } else {
        loader?.classList.add("d-none");
    }
}

function getOrderStatusBadge(status) {
    switch (status) {
        case "PENDING": return '<span class="badge bg-warning text-dark">Chờ xử lý</span>';
        case "PAYMENT_PENDING": return '<span class="badge bg-info text-dark">Chờ thanh toán</span>';
        case "CONFIRMED": return '<span class="badge bg-primary">Đã xác nhận</span>';
        case "SHIPPING": return '<span class="badge bg-primary-subtle text-primary border">Đang giao</span>';
        case "COMPLETED": return '<span class="badge bg-success">Đã hoàn tất</span>';
        case "CANCELLED": return '<span class="badge bg-danger">Đã hủy</span>';
        default: return `<span class="badge bg-secondary">${status}</span>`;
    }
}

function getProductStatusBadge(status) {
    switch (status) {
        case "ACTIVE": return '<span class="badge bg-success">Đang bán</span>';
        case "INACTIVE": return '<span class="badge bg-secondary">Ngừng bán</span>';
        case "OUT_OF_STOCK": return '<span class="badge bg-danger">Hết hàng</span>';
        default: return `<span class="badge bg-secondary">${status}</span>`;
    }
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

function escapeHtml(text) {
    if (!text) return "";
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}
