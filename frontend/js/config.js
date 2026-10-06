// Global Configuration for TechStore Frontend
export const CONFIG = {
    API_BASE_URL: (document.querySelector('meta[name="api-base-url"]')?.content || `${location.protocol}//${location.hostname}:8080/api/v1`).replace(/\/$/, ""),
    APP_NAME: "TechStore",
    CURRENCY: "VND",
    DEFAULT_PAGE_SIZE: 12
};
