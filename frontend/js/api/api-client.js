import { CONFIG } from "../config.js";

/**
 * Universal Fetch API client for TechStore
 * Handles baseUrl, query parameters, auth headers, and standard error envelopes
 */
export async function apiRequest(endpoint, options = {}) {
    const {
        method = "GET",
        headers = {},
        body = null,
        params = null
    } = options;

    let url = `${CONFIG.API_BASE_URL}${endpoint.startsWith("/") ? endpoint : "/" + endpoint}`;

    // Append query parameters if provided
    if (params && Object.keys(params).length > 0) {
        const queryParams = new URLSearchParams();
        Object.entries(params).forEach(([key, value]) => {
            if (value !== undefined && value !== null && value !== "") {
                queryParams.append(key, value);
            }
        });
        const queryString = queryParams.toString();
        if (queryString) {
            url += (url.includes("?") ? "&" : "?") + queryString;
        }
    }

    const defaultHeaders = {
        "Accept": "application/json"
    };

    if (!(body instanceof FormData)) {
        defaultHeaders["Content-Type"] = "application/json";
    }

    // Attach JWT token if available in localStorage
    const token = localStorage.getItem("techstore_token");
    if (token) {
        defaultHeaders["Authorization"] = `Bearer ${token}`;
    }

    const fetchConfig = {
        method,
        headers: {
            ...defaultHeaders,
            ...headers
        }
    };

    if (body) {
        fetchConfig.body = (body instanceof FormData) ? body : JSON.stringify(body);
    }

    try {
        const response = await fetch(url, fetchConfig);
        const data = await response.json().catch(() => null);

        if (response.status === 401 && token && !endpoint.startsWith('/auth/')) {
            localStorage.removeItem('techstore_token');
            localStorage.removeItem('techstore_user');
            const redirect = encodeURIComponent(location.pathname + location.search + location.hash);
            location.assign('/pages/auth/login.html?redirect=' + redirect);
        }
        if (!response.ok) {
            const error = new Error(data?.message || `HTTP error ${response.status}`);
            error.status = response.status;
            error.data = data;
            throw error;
        }

        return data;
    } catch (err) {
        console.error(`[API Error] ${method} ${endpoint}: ${err.status || "network"}`);
        throw err;
    }
}
