import { apiRequest } from "../api/api-client.js";
import { Auth } from "../auth/auth.js";
import { updateCartBadge } from "../api/cart-api.js";

document.addEventListener("DOMContentLoaded", () => {
    checkBackendHealth();
    renderNavbarAuth();
});

function renderNavbarAuth() {
    const authContainer = document.getElementById("nav-auth-container");
    if (!authContainer) return;

    if (Auth.isAuthenticated()) {
        const user = Auth.getUser();
        const isAdmin = Auth.isAdmin() || Auth.isStaff();

        authContainer.innerHTML = `
            <a href="./pages/cart/cart.html" class="btn btn-outline-primary position-relative" title="Giỏ hàng">
                <i class="bi bi-cart3"></i>
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" id="cart-badge" style="display: none;">
                    0
                </span>
            </a>
            <div class="dropdown">
                <button class="btn btn-light border dropdown-toggle d-flex align-items-center gap-2" type="button" data-bs-toggle="dropdown">
                    <i class="bi bi-person-circle text-primary fs-5"></i>
                    <span class="fw-semibold">${user?.fullName || user?.email || "Tài khoản"}</span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-sm">
                    <li><h6 class="dropdown-header">Xin chào, ${user?.fullName || user?.email || "Tài khoản"}</h6></li>
                    <li><a class="dropdown-item" href="./pages/orders/my-orders.html"><i class="bi bi-bag me-2"></i>Đơn mua của tôi</a></li>
                    ${isAdmin ? '<li><a class="dropdown-item text-primary" href="./pages/admin/admin-orders.html"><i class="bi bi-speedometer2 me-2"></i>Quản trị đơn hàng</a></li>' : ''}
                    <li><hr class="dropdown-divider"></li>
                    <li><button class="dropdown-item text-danger" id="btn-logout"><i class="bi bi-box-arrow-right me-2"></i>Đăng xuất</button></li>
                </ul>
            </div>
        `;

        document.getElementById("btn-logout")?.addEventListener("click", () => {
            Auth.logout("./index.html");
        });

        updateCartBadge();
    }
}

async function checkBackendHealth() {
    const statusBadge = document.getElementById("backend-status-badge");
    const statusDetails = document.getElementById("backend-status-details");

    if (!statusBadge) return;

    try {
        statusBadge.className = "badge bg-warning text-dark";
        statusBadge.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status"></span> Đang kiểm tra...';

        const response = await apiRequest("/health");

        if (response && response.success) {
            statusBadge.className = "badge bg-success";
            statusBadge.innerHTML = '<i class="bi bi-check-circle-fill me-1"></i> Backend Online';
            if (statusDetails) {
                statusDetails.innerHTML = `
                    <small class="text-success">
                        <strong>Dịch vụ:</strong> ${response.data.service} (v${response.data.version}) |
                        <strong>Thời gian:</strong> ${response.data.timestamp}
                    </small>
                `;
            }
        } else {
            throw new Error(response?.message || "Không phản hồi dữ liệu hợp lệ");
        }
    } catch (error) {
        statusBadge.className = "badge bg-danger";
        statusBadge.innerHTML = '<i class="bi bi-x-circle-fill me-1"></i> Backend Offline';
        if (statusDetails) {
            statusDetails.innerHTML = `
                <small class="text-danger">
                    Không thể kết nối đến REST API (http://localhost:8080/api/v1/health). Hãy kiểm tra Spring Boot backend đã khởi động chưa.
                </small>
            `;
        }
    }
}
