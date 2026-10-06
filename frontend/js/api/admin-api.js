import { apiRequest } from "./api-client.js";

/**
 * Unified Admin API Service for TechStore Administration Portal
 */
export const AdminApi = {

    // ==========================================
    // 1. USER MANAGEMENT (Admin Only)
    // ==========================================

    async getUsers(params = {}) {
        const queryParams = new URLSearchParams();
        if (params.page !== undefined) queryParams.append("page", params.page);
        if (params.size !== undefined) queryParams.append("size", params.size);
        if (params.search) queryParams.append("search", params.search);
        if (params.status) queryParams.append("status", params.status);
        if (params.role) queryParams.append("role", params.role);

        const qs = queryParams.toString();
        return apiRequest(`/admin/users${qs ? "?" + qs : ""}`, { method: "GET" });
    },

    async getUserById(id) {
        return apiRequest(`/admin/users/${id}`, { method: "GET" });
    },

    async updateUserStatus(id, status) {
        return apiRequest(`/admin/users/${id}/status`, {
            method: "PATCH",
            body: { status }
        });
    },

    async updateUserRoles(id, roles) {
        return apiRequest(`/admin/users/${id}/roles`, {
            method: "PUT",
            body: { roles }
        });
    },

    // ==========================================
    // 2. STAFF MANAGEMENT (Admin Only)
    // ==========================================

    async getStaff(params = {}) {
        const queryParams = new URLSearchParams();
        if (params.page !== undefined) queryParams.append("page", params.page);
        if (params.size !== undefined) queryParams.append("size", params.size);
        if (params.search) queryParams.append("search", params.search);
        if (params.status) queryParams.append("status", params.status);

        const qs = queryParams.toString();
        return apiRequest(`/admin/staff${qs ? "?" + qs : ""}`, { method: "GET" });
    },

    async createStaff(payload) {
        return apiRequest("/admin/staff", {
            method: "POST",
            body: payload
        });
    },

    async updateStaffStatus(id, status) {
        return apiRequest(`/admin/staff/${id}/status`, {
            method: "PATCH",
            body: { status }
        });
    },

    // ==========================================
    // 3. BRANCH MANAGEMENT (Admin Only)
    // ==========================================

    async getBranches(status) {
        const qs = status ? `?status=${status}` : "";
        return apiRequest(`/admin/branches${qs}`, { method: "GET" });
    },

    async getBranchById(id) {
        return apiRequest(`/admin/branches/${id}`, { method: "GET" });
    },

    async createBranch(payload) {
        return apiRequest("/admin/branches", {
            method: "POST",
            body: payload
        });
    },

    async updateBranch(id, payload) {
        return apiRequest(`/admin/branches/${id}`, {
            method: "PUT",
            body: payload
        });
    },

    async deleteBranch(id) {
        return apiRequest(`/admin/branches/${id}`, {
            method: "DELETE"
        });
    },

    // ==========================================
    // 4. INVENTORY MANAGEMENT (Staff & Admin)
    // ==========================================

    async getInventory(params = {}) {
        const queryParams = new URLSearchParams();
        if (params.page !== undefined) queryParams.append("page", params.page);
        if (params.size !== undefined) queryParams.append("size", params.size);
        if (params.productId) queryParams.append("productId", params.productId);
        if (params.branchId) queryParams.append("branchId", params.branchId);
        if (params.lowStock !== undefined && params.lowStock !== "") queryParams.append("lowStock", params.lowStock);
        if (params.search) queryParams.append("search", params.search);

        const qs = queryParams.toString();
        return apiRequest(`/admin/inventory${qs ? "?" + qs : ""}`, { method: "GET" });
    },

    async adjustStock(payload) {
        return apiRequest("/admin/inventory/adjust", {
            method: "POST",
            body: payload
        });
    },

    async transferStock(payload) {
        return apiRequest("/admin/inventory/transfer", {
            method: "POST",
            body: payload
        });
    },

    // ==========================================
    // 5. CATEGORY MANAGEMENT (Admin Only)
    // ==========================================

    async getCategories(status) {
        const qs = status ? `?status=${status}` : "";
        return apiRequest(`/categories${qs}`, { method: "GET" });
    },

    async createCategory(payload) {
        return apiRequest("/categories", {
            method: "POST",
            body: payload
        });
    },

    async updateCategory(id, payload) {
        return apiRequest(`/categories/${id}`, {
            method: "PUT",
            body: payload
        });
    },

    async deleteCategory(id) {
        return apiRequest(`/categories/${id}`, {
            method: "DELETE"
        });
    },

    // ==========================================
    // 6. BRAND MANAGEMENT (Admin Only)
    // ==========================================

    async getBrands(status) {
        const qs = status ? `?status=${status}` : "";
        return apiRequest(`/brands${qs}`, { method: "GET" });
    },

    async createBrand(payload) {
        return apiRequest("/brands", {
            method: "POST",
            body: payload
        });
    },

    async updateBrand(id, payload) {
        return apiRequest(`/brands/${id}`, {
            method: "PUT",
            body: payload
        });
    },

    async deleteBrand(id) {
        return apiRequest(`/brands/${id}`, {
            method: "DELETE"
        });
    },

    // ==========================================
    // 7. PRODUCT MANAGEMENT (Staff & Admin)
    // ==========================================

    async getProducts(params = {}) {
        const queryParams = new URLSearchParams();
        if (params.page !== undefined) queryParams.append("page", params.page);
        if (params.size !== undefined) queryParams.append("size", params.size);
        if (params.keyword) queryParams.append("keyword", params.keyword);
        if (params.categoryId) queryParams.append("categoryId", params.categoryId);
        if (params.brandId) queryParams.append("brandId", params.brandId);
        if (params.status) queryParams.append("status", params.status);

        const qs = queryParams.toString();
        return apiRequest(`/products/management${qs ? "?" + qs : ""}`, { method: "GET" });
    },

    async getProductById(id) {
        return apiRequest(`/products/${id}/management`, { method: "GET" });
    },

    async createProduct(payload) {
        return apiRequest("/products", {
            method: "POST",
            body: payload
        });
    },

    async updateProduct(id, payload) {
        return apiRequest(`/products/${id}`, {
            method: "PUT",
            body: payload
        });
    },

    async deleteProduct(id) {
        return apiRequest(`/products/${id}`, {
            method: "DELETE"
        });
    },

    // ==========================================
    // 8. DASHBOARD ANALYTICS (Staff & Admin)
    // ==========================================

    async getDashboardSummary(days = 30) {
        return apiRequest(`/admin/dashboard/summary?days=${days}`, {
            method: "GET"
        });
    }
};
