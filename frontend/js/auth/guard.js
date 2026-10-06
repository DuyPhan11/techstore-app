import { Auth } from "./auth.js";

export const Guard = {
    requireAuth(redirectUrl = "/pages/auth/login.html") {
        if (!Auth.isAuthenticated()) {
            const currentPath = encodeURIComponent(window.location.pathname + window.location.search);
            window.location.href = `${redirectUrl}?redirect=${currentPath}`;
            return false;
        }
        return true;
    },

    requireGuest(redirectUrl = "/index.html") {
        if (Auth.isAuthenticated()) {
            window.location.href = redirectUrl;
            return false;
        }
        return true;
    },

    requireRole(role, redirectUrl = "/index.html") {
        if (!this.requireAuth()) return false;
        if (!Auth.hasRole(role)) {
            alert("Bạn không có quyền truy cập vào trang này.");
            window.location.href = redirectUrl;
            return false;
        }
        return true;
    },

    requireStaff(redirectUrl = "/index.html") {
        if (!this.requireAuth()) return false;
        if (!Auth.isStaff()) {
            alert("Trang này chỉ dành cho Nhân viên hoặc Quản trị viên.");
            window.location.href = redirectUrl;
            return false;
        }
        return true;
    },

    requireAdmin(redirectUrl = "/index.html") {
        if (!this.requireAuth()) return false;
        if (!Auth.isAdmin()) {
            alert("Trang này chỉ dành cho Quản trị viên (Admin).");
            window.location.href = redirectUrl;
            return false;
        }
        return true;
    }
};
