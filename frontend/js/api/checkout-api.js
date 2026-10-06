import { apiRequest } from "./api-client.js";

/**
 * Checkout & Order API Service for TechStore
 */
export const CheckoutApi = {
    /**
     * Submit checkout order
     */
    async checkout(payload) {
        return apiRequest("/checkout", {
            method: "POST",
            body: payload
        });
    },

    /**
     * Validate coupon before placing order
     */
    async validateCoupon(couponCode, orderAmount) {
        return apiRequest("/checkout/validate-coupon", {
            method: "POST",
            body: {
                couponCode,
                orderAmount: Number(orderAmount)
            }
        });
    },

    /**
     * Get list of active branches
     */
    async getBranches() {
        return apiRequest("/branches", {
            method: "GET"
        });
    }
};
