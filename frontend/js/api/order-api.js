import { apiRequest } from "./api-client.js";

/**
 * Order API Service for Customer & Admin
 */
export const OrderApi = {
    /**
     * Customer: Get my orders with pagination and optional status filter
     */
    async getMyOrders(page = 0, size = 10) {
        return apiRequest(`/orders/my?page=${page}&size=${size}`, {
            method: "GET"
        });
    },

    /**
     * Customer: Get order details by ID
     */
    async getOrderDetail(orderId) {
        return apiRequest(`/orders/${orderId}`, {
            method: "GET"
        });
    },

    /**
     * Customer: Cancel an order with optional reason
     */
    async cancelOrder(orderId, reason = "") {
        return apiRequest(`/orders/${orderId}/cancel`, {
            method: "POST",
            body: { reason }
        });
    },

    /**
     * Staff/Admin: Get all orders with search, status filter, and pagination
     */
    async getAdminOrders(params = {}) {
        const queryParams = new URLSearchParams();
        if (params.page !== undefined) queryParams.append("page", params.page);
        if (params.size !== undefined) queryParams.append("size", params.size);
        if (params.status) queryParams.append("status", params.status);
        if (params.search) queryParams.append("search", params.search);
        if (params.fromDate) queryParams.append("fromDate", params.fromDate);
        if (params.toDate) queryParams.append("toDate", params.toDate);

        const queryString = queryParams.toString();
        return apiRequest(`/admin/orders${queryString ? "?" + queryString : ""}`, {
            method: "GET"
        });
    },

    /**
     * Staff/Admin: Get admin order detail
     */
    async getAdminOrderDetail(orderId) {
        return apiRequest(`/admin/orders/${orderId}`, {
            method: "GET"
        });
    },

    /**
     * Staff/Admin: Update order status
     */
    async updateOrderStatus(orderId, status, notes = "") {
        return apiRequest(`/admin/orders/${orderId}/status`, {
            method: "PUT",
            body: { status, notes }
        });
    }
};
