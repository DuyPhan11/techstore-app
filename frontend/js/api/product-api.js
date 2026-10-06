import { apiRequest } from "./api-client.js";

/**
 * Product API Service for TechStore
 * Handles Public Catalog and Staff/Admin CRUD
 */
export const ProductApi = {
    /**
     * Get paginated products with search & filter params
     */
    async getProducts(params = {}) {
        return apiRequest("/products", {
            method: "GET",
            params
        });
    },

    /**
     * Get single product detail by ID
     */
    async getProductById(id) {
        return apiRequest(`/products/${id}`, {
            method: "GET"
        });
    },

    /**
     * Get single product detail by slug
     */
    async getProductBySlug(slug) {
        return apiRequest(`/products/slug/${slug}`, {
            method: "GET"
        });
    },

    /**
     * Get list of categories
     */
    async getCategories(status = "ACTIVE") {
        return apiRequest("/categories", {
            method: "GET",
            params: status ? { status } : {}
        });
    },

    /**
     * Get list of brands
     */
    async getBrands(status = "ACTIVE") {
        return apiRequest("/brands", {
            method: "GET",
            params: status ? { status } : {}
        });
    },

    /**
     * Admin/Staff: Create new product
     */
    async createProduct(productData) {
        return apiRequest("/products", {
            method: "POST",
            body: productData
        });
    },

    /**
     * Admin/Staff: Update product
     */
    async updateProduct(id, productData) {
        return apiRequest(`/products/${id}`, {
            method: "PUT",
            body: productData
        });
    },

    /**
     * Admin/Staff: Delete (deactivate) product
     */
    async deleteProduct(id) {
        return apiRequest(`/products/${id}`, {
            method: "DELETE"
        });
    },

    /**
     * Admin/Staff: Add product image
     */
    async addProductImage(productId, imageData) {
        return apiRequest(`/products/${productId}/images`, {
            method: "POST",
            body: imageData
        });
    },

    /**
     * Admin/Staff: Delete product image
     */
    async deleteProductImage(productId, imageId) {
        return apiRequest(`/products/${productId}/images/${imageId}`, {
            method: "DELETE"
        });
    }
};
