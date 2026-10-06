import { apiRequest } from "./api-client.js";

/**
 * Coupon API Service for Staff & Admin Management
 */
export const CouponApi = {
    /**
     * Get coupons with optional search, filter by discountType & isActive, and pagination
     */
    async getAdminCoupons(params = {}) {
        const queryParams = new URLSearchParams();
        if (params.page !== undefined) queryParams.append("page", params.page);
        if (params.size !== undefined) queryParams.append("size", params.size);
        if (params.search) queryParams.append("search", params.search);
        if (params.discountType) queryParams.append("discountType", params.discountType);
        if (params.isActive !== undefined && params.isActive !== "") {
            queryParams.append("isActive", params.isActive);
        }

        const queryString = queryParams.toString();
        return apiRequest(`/admin/coupons${queryString ? "?" + queryString : ""}`, {
            method: "GET"
        });
    },

    /**
     * Get coupon details by ID
     */
    async getCouponById(id) {
        return apiRequest(`/admin/coupons/${id}`, {
            method: "GET"
        });
    },

    /**
     * Create a new coupon
     */
    async createCoupon(data) {
        return apiRequest("/admin/coupons", {
            method: "POST",
            body: data
        });
    },

    /**
     * Update an existing coupon
     */
    async updateCoupon(id, data) {
        return apiRequest(`/admin/coupons/${id}`, {
            method: "PUT",
            body: data
        });
    },

    /**
     * Toggle coupon active/inactive status
     */
    async toggleStatus(id, active) {
        return apiRequest(`/admin/coupons/${id}/status`, {
            method: "PATCH",
            body: { active }
        });
    },

    /**
     * Delete a coupon
     */
    async deleteCoupon(id) {
        return apiRequest(`/admin/coupons/${id}`, {
            method: "DELETE"
        });
    }
};
