# TechStore Architecture Documentation

## 1. System Overview
TechStore là hệ thống thương mại điện tử chuyên cung cấp các sản phẩm thiết bị công nghệ hiện đại.

```text
Browser (Vanilla JS ES6 Modules + Bootstrap 5)
        │
        ▼ (HTTP REST JSON /api/v1)
Spring Boot 3.x REST Controllers
        │
        ▼
Spring Service Layer (Business Logic & Transactions)
        │
        ▼
Spring Data JPA / Repositories
        │
        ▼
MySQL 8.x (InnoDB, utf8mb4)
```

## 2. Monorepo Organization
- `backend/`: Chứa mã nguồn Spring Boot REST API, cấu hình Maven, Java 21.
- `frontend/`: Chứa mã nguồn static HTML5, CSS3, JavaScript ES6 Modules, Fetch API.
- `database/`: Chứa các script SQL schema, seed data.
- `docs/`: Tài liệu đặc tả kiến trúc và API.

## 3. Standard API Conventions
- Base Path: `/api/v1`
- Format: JSON (`Content-Type: application/json; charset=UTF-8`)
- Global Exception Handler: `@RestControllerAdvice` định dạng thống nhất `ApiResponse<T>`
