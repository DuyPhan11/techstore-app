import { apiRequest } from "./api-client.js";

/**
 * Review API Service for TechStore
 */
export const ReviewApi = {
    /**
     * Get product reviews and rating summary (Public)
     */
    async getProductReviews(productId, page = 0, size = 10) {
        return apiRequest(`/products/${productId}/reviews?page=${page}&size=${size}`, {
            method: "GET"
        });
    },

    /**
     * Check if authenticated customer is eligible to review this product
     */
    async checkEligibility(productId) {
        return apiRequest(`/products/${productId}/reviews/eligibility`, {
            method: "GET"
        });
    },

    /**
     * Create review for product (Requires completed order)
     */
    async createReview(productId, payload) {
        return apiRequest(`/products/${productId}/reviews`, {
            method: "POST",
            body: payload
        });
    },

    /**
     * Update existing review (Owner only)
     */
    async updateReview(reviewId, payload) {
        return apiRequest(`/reviews/${reviewId}`, {
            method: "PUT",
            body: payload
        });
    },

    /**
     * Delete review (Owner or Admin)
     */
    async deleteReview(reviewId) {
        return apiRequest(`/reviews/${reviewId}`, {
            method: "DELETE"
        });
    }
};
