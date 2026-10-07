package com.techstore.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.*;
import com.techstore.entity.Product;
import com.techstore.enums.ProductStatus;
import com.techstore.repository.ProductRepository;
import com.techstore.service.AiChatService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.*;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.Normalizer;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiChatServiceImpl implements AiChatService {

    private final ProductRepository productRepository;
    private final ObjectMapper objectMapper;

    @Value("${gemini.api-key:}")
    private String geminiApiKey;

    @Value("${gemini.model:gemini-1.5-flash}")
    private String geminiModel;

    private final RestTemplate restTemplate = createRestTemplate();

    private static RestTemplate createRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(6000);
        factory.setReadTimeout(12000);
        return new RestTemplate(factory);
    }

    private static final DecimalFormat PRICE_FORMAT = new DecimalFormat("#,### đ");

    @Override
    @Transactional(readOnly = true)
    public AiChatResponse chat(AiChatRequest request) {
        String userMessage = request.getMessage() != null ? request.getMessage().trim() : "";
        log.info("Received AI chat message: '{}'", userMessage);

        List<Product> relevantProducts = Collections.emptyList();
        List<ProductSummaryDto> productDtos = Collections.emptyList();

        try {
            // 1. Identify relevant products from store database
            relevantProducts = findRelevantProducts(userMessage);
            productDtos = relevantProducts.stream()
                    .limit(5)
                    .map(p -> ProductSummaryDto.fromEntity(p, 10))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to query relevant products from DB: {}", e.getMessage());
        }

        // 2. Attempt to call Gemini API if key is present
        if (geminiApiKey != null && !geminiApiKey.isBlank()) {
            try {
                String aiReply = callGeminiApi(userMessage, request.getHistory(), relevantProducts);
                if (aiReply != null && !aiReply.isBlank()) {
                    return AiChatResponse.builder()
                            .reply(aiReply)
                            .suggestedProducts(productDtos)
                            .quickReplies(generateQuickReplies(userMessage))
                            .fromAi(true)
                            .build();
                }
            } catch (Exception e) {
                log.warn("Gemini API call failed, falling back to smart rule engine: {}", e.getMessage());
            }
        }

        // 3. Fallback Smart Rule Advisor
        try {
            return generateSmartAdvisorReply(userMessage, relevantProducts, productDtos);
        } catch (Exception e) {
            log.error("Failed to generate fallback response: {}", e.getMessage(), e);
            return AiChatResponse.builder()
                    .reply("Dạ chào bạn! TechStore luôn sẵn sàng hỗ trợ bạn tư vấn cấu hình, chính sách đổi trả 7 ngày và bảo hành 12 tháng chính hãng. Bạn vui lòng thử lại câu hỏi nhé!")
                    .suggestedProducts(Collections.emptyList())
                    .quickReplies(List.of("Tư vấn điện thoại giá rẻ", "Tư vấn laptop sinh viên", "Chính sách bảo hành & đổi trả 7 ngày"))
                    .fromAi(false)
                    .build();
        }
    }

    /**
     * Remove Vietnamese accents and convert to lower case for resilient keyword matching
     */
    private static String removeDiacritics(String text) {
        if (text == null) return "";
        String normalized = Normalizer.normalize(text, Normalizer.Form.NFD);
        String result = normalized.replaceAll("\\p{M}", "");
        return result.replace("đ", "d").replace("Đ", "d").toLowerCase().trim();
    }

    /**
     * Smart product search in database with Vietnamese accent neutralization, category mapping,
     * brand detection, and price intent sorting.
     */
    private List<Product> findRelevantProducts(String query) {
        if (query == null || query.isBlank()) {
            return getDiverseCatalogProducts();
        }

        String norm = removeDiacritics(query);

        // 1. Detect Category ID (1: Điện Thoại, 2: Laptop, 3: Tablet, 4: Phụ Kiện)
        Long targetCategoryId = null;

        // Check Accessories & Audio first (to avoid misclassifying AirPods / Apple Watch as iPhone/Macbook)
        if (norm.contains("airpods") || norm.contains("apple watch") || norm.contains("galaxy watch")
                || norm.contains("loa") || norm.contains("tai nghe") || norm.contains("headphone")
                || norm.contains("earphone") || norm.contains("smartwatch") || norm.contains("dong ho")
                || norm.contains("chuot") || norm.contains("ban phim") || norm.contains("keyboard") || norm.contains("mouse")
                || norm.contains("sac") || norm.contains("cap") || norm.contains("pin du phong") || norm.contains("phu kien")
                || norm.contains("man hinh") || norm.contains("monitor") || norm.contains("am thanh") || norm.contains("audio")) {
            targetCategoryId = 4L;
        } else if (norm.contains("ipad") || norm.contains("tablet") || norm.contains("may tinh bang")
                || norm.contains("galaxy tab") || norm.contains("xiaomi pad")) {
            targetCategoryId = 3L;
        } else if (norm.contains("macbook") || norm.contains("laptop") || norm.contains("lap top")
                || (norm.contains("may tinh") && !norm.contains("bang")) || norm.contains("gaming")
                || norm.contains("vivobook") || norm.contains("zenbook") || norm.contains("thinkpad")
                || norm.contains("legion") || norm.contains("nitro") || norm.contains("predator")
                || norm.contains("ideapad") || norm.contains("tuf") || norm.contains("rog")) {
            targetCategoryId = 2L;
        } else if (norm.contains("dien thoai") || norm.contains("dienthoai") || norm.contains("dt ")
                || norm.endsWith(" dt") || norm.equals("dt") || norm.contains("smartphone") || norm.contains("phone")
                || norm.contains("di dong") || norm.contains("iphone") || norm.contains("samsung")
                || norm.contains("galaxy") || norm.contains("redmi") || norm.contains("oppo")
                || norm.contains("vivo") || norm.contains("realme") || norm.contains("xiaomi")) {
            targetCategoryId = 1L;
        }

        // 2. Detect Brands
        List<String> brandKeywords = new ArrayList<>();
        if (norm.contains("apple") || norm.contains("iphone") || norm.contains("macbook") || norm.contains("ipad")) brandKeywords.add("apple");
        if (norm.contains("samsung") || norm.contains("galaxy")) brandKeywords.add("samsung");
        if (norm.contains("xiaomi") || norm.contains("redmi") || norm.contains("poco")) brandKeywords.add("xiaomi");
        if (norm.contains("oppo")) brandKeywords.add("oppo");
        if (norm.contains("vivo")) brandKeywords.add("vivo");
        if (norm.contains("realme")) brandKeywords.add("realme");
        if (norm.contains("asus") || norm.contains("rog") || norm.contains("tuf") || norm.contains("zenbook") || norm.contains("vivobook")) brandKeywords.add("asus");
        if (norm.contains("acer") || norm.contains("nitro") || norm.contains("aspire") || norm.contains("predator")) brandKeywords.add("acer");
        if (norm.contains("lenovo") || norm.contains("thinkpad") || norm.contains("legion") || norm.contains("ideapad") || norm.contains("loq")) brandKeywords.add("lenovo");
        if (norm.contains("dell") || norm.contains("inspiron") || norm.contains("vostro") || norm.contains("xps")) brandKeywords.add("dell");
        if (norm.contains("hp") || norm.contains("victus") || norm.contains("pavilion") || norm.contains("omen")) brandKeywords.add("hp");
        if (norm.contains("msi")) brandKeywords.add("msi");
        if (norm.contains("sony")) brandKeywords.add("sony");
        if (norm.contains("jbl")) brandKeywords.add("jbl");
        if (norm.contains("marshall")) brandKeywords.add("marshall");
        if (norm.contains("anker") || norm.contains("soundcore")) brandKeywords.add("anker");
        if (norm.contains("logitech")) brandKeywords.add("logitech");
        if (norm.contains("garmin")) brandKeywords.add("garmin");
        if (norm.contains("baseus")) brandKeywords.add("baseus");
        if (norm.contains("ugreen")) brandKeywords.add("ugreen");

        // 3. Detect Feature / Model keywords
        List<String> featureKeywords = new ArrayList<>();
        if (norm.contains("gaming")) featureKeywords.add("gaming");
        if (norm.contains("pro max") || norm.contains("promax")) featureKeywords.add("pro max");
        else if (norm.contains("pro")) featureKeywords.add("pro");
        if (norm.contains("plus")) featureKeywords.add("plus");
        if (norm.contains("ultra")) featureKeywords.add("ultra");
        if (norm.contains("flip")) featureKeywords.add("flip");
        if (norm.contains("fold")) featureKeywords.add("fold");
        if (norm.contains("air")) featureKeywords.add("air");

        // 4. Detect Price Intent & Range
        boolean isCheapSort = norm.contains("gia re") || norm.contains("giare")
                || norm.contains("re nhat") || norm.contains("gia tot") || norm.contains("tiet kiem")
                || norm.contains("binh dan") || norm.contains("hat de") || norm.contains("sinh vien")
                || norm.contains("hoc sinh") || norm.matches(".*\\bre\\b.*");

        boolean isExpensiveSort = norm.contains("cao cap") || norm.contains("flagship")
                || norm.contains("dat nhat") || norm.contains("xin nhat") || norm.contains("vip");

        BigDecimal minPrice = null;
        BigDecimal maxPrice = null;

        // "duoi 15tr", "duoi 15 trieu", "< 15tr"
        Pattern underPattern = Pattern.compile("(?:duoi|<|<=)\\s*(\\d+)\\s*(?:tr|trieu)?");
        Matcher underMatcher = underPattern.matcher(norm);
        if (underMatcher.find()) {
            try {
                long val = Long.parseLong(underMatcher.group(1));
                maxPrice = BigDecimal.valueOf(val * 1_000_000L);
            } catch (Exception ignored) {}
        }

        // "tu 10 den 20tr", "khoang 5 - 10 trieu"
        Pattern rangePattern = Pattern.compile("(?:tu|khoang)\\s*(\\d+)\\s*(?:den|-)\\s*(\\d+)\\s*(?:tr|trieu)?");
        Matcher rangeMatcher = rangePattern.matcher(norm);
        if (rangeMatcher.find()) {
            try {
                long minVal = Long.parseLong(rangeMatcher.group(1));
                long maxVal = Long.parseLong(rangeMatcher.group(2));
                minPrice = BigDecimal.valueOf(minVal * 1_000_000L);
                maxPrice = BigDecimal.valueOf(maxVal * 1_000_000L);
            } catch (Exception ignored) {}
        }

        // "tren 20tr", "> 20 trieu"
        Pattern overPattern = Pattern.compile("(?:tren|>|>=)\\s*(\\d+)\\s*(?:tr|trieu)?");
        Matcher overMatcher = overPattern.matcher(norm);
        if (overMatcher.find()) {
            try {
                long val = Long.parseLong(overMatcher.group(1));
                minPrice = BigDecimal.valueOf(val * 1_000_000L);
            } catch (Exception ignored) {}
        }

        // 5. If query is broad (no category, no brand, no feature, no price intent), return diverse catalog products
        if (targetCategoryId == null && brandKeywords.isEmpty() && featureKeywords.isEmpty()
                && maxPrice == null && minPrice == null && !isCheapSort && !isExpensiveSort) {
            return getDiverseCatalogProducts();
        }

        // 6. Build dynamic Specification
        Specification<Product> spec = (root, q, cb) -> cb.equal(root.get("status"), ProductStatus.ACTIVE);

        if (targetCategoryId != null) {
            final Long catId = targetCategoryId;
            spec = spec.and((root, q, cb) -> cb.equal(root.get("category").get("id"), catId));
        }

        if (!brandKeywords.isEmpty()) {
            Specification<Product> brandSpec = null;
            for (String bk : brandKeywords) {
                Specification<Product> itemSpec = (root, q, cb) -> cb.or(
                        cb.like(cb.lower(root.get("brand").get("name")), "%" + bk + "%"),
                        cb.like(cb.lower(root.get("brand").get("slug")), "%" + bk + "%"),
                        cb.like(cb.lower(root.get("name")), "%" + bk + "%"),
                        cb.like(cb.lower(root.get("slug")), "%" + bk + "%")
                );
                brandSpec = (brandSpec == null) ? itemSpec : brandSpec.or(itemSpec);
            }
            if (brandSpec != null) {
                spec = spec.and(brandSpec);
            }
        }

        if (!featureKeywords.isEmpty()) {
            Specification<Product> featureSpec = null;
            for (String fk : featureKeywords) {
                Specification<Product> itemSpec = (root, q, cb) -> cb.or(
                        cb.like(cb.lower(root.get("name")), "%" + fk + "%"),
                        cb.like(cb.lower(root.get("slug")), "%" + fk + "%")
                );
                featureSpec = (featureSpec == null) ? itemSpec : featureSpec.or(itemSpec);
            }
            if (featureSpec != null) {
                spec = spec.and(featureSpec);
            }
        }

        if (minPrice != null) {
            final BigDecimal fMin = minPrice;
            spec = spec.and((root, q, cb) -> cb.greaterThanOrEqualTo(root.get("price"), fMin));
        }
        if (maxPrice != null) {
            final BigDecimal fMax = maxPrice;
            spec = spec.and((root, q, cb) -> cb.lessThanOrEqualTo(root.get("price"), fMax));
        }

        Sort sort;
        if (isCheapSort) {
            sort = Sort.by(Sort.Direction.ASC, "price");
        } else if (isExpensiveSort) {
            sort = Sort.by(Sort.Direction.DESC, "price");
        } else {
            sort = Sort.by(Sort.Direction.DESC, "createdAt");
        }

        Page<Product> page = productRepository.findAll(spec, PageRequest.of(0, 10, sort));
        List<Product> list = page.getContent();

        if (list.isEmpty()) {
            // If filters are too restrictive, fall back to target category or diverse catalog
            if (targetCategoryId != null) {
                Page<Product> catFallback = productRepository.findByCategoryIdAndStatus(
                        targetCategoryId, ProductStatus.ACTIVE, PageRequest.of(0, 8, sort));
                if (!catFallback.isEmpty()) {
                    return catFallback.getContent();
                }
            }
            return getDiverseCatalogProducts();
        }

        return list;
    }

    /**
     * Provide a balanced representation of products across all categories (Phones, Laptops, Tablets, Accessories)
     * so that the AI assistant never suffers from context starvation or falsely claims a category is not sold.
     */
    private List<Product> getDiverseCatalogProducts() {
        List<Product> result = new ArrayList<>();
        try {
            // 1. Điện Thoại (3 items)
            Page<Product> phones = productRepository.findByCategoryIdAndStatus(
                    1L, ProductStatus.ACTIVE, PageRequest.of(0, 3, Sort.by(Sort.Direction.DESC, "createdAt")));
            result.addAll(phones.getContent());

            // 2. Laptop (3 items)
            Page<Product> laptops = productRepository.findByCategoryIdAndStatus(
                    2L, ProductStatus.ACTIVE, PageRequest.of(0, 3, Sort.by(Sort.Direction.DESC, "createdAt")));
            result.addAll(laptops.getContent());

            // 3. Tablet (2 items)
            Page<Product> tablets = productRepository.findByCategoryIdAndStatus(
                    3L, ProductStatus.ACTIVE, PageRequest.of(0, 2, Sort.by(Sort.Direction.DESC, "createdAt")));
            result.addAll(tablets.getContent());

            // 4. Phụ Kiện & Âm thanh (2 items)
            Page<Product> accessories = productRepository.findByCategoryIdAndStatus(
                    4L, ProductStatus.ACTIVE, PageRequest.of(0, 2, Sort.by(Sort.Direction.DESC, "createdAt")));
            result.addAll(accessories.getContent());
        } catch (Exception e) {
            log.warn("Error fetching diverse products: {}", e.getMessage());
        }

        if (result.isEmpty()) {
            return productRepository.findByStatus(
                    ProductStatus.ACTIVE, PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "createdAt"))).getContent();
        }
        return result;
    }

    /**
     * Call Google Gemini API with multi-model fallback support
     */
    private String callGeminiApi(String userMessage, List<AiChatMessageDto> history, List<Product> catalogProducts) {
        List<String> modelsToTry = new ArrayList<>();
        if (geminiModel != null && !geminiModel.isBlank()) {
            modelsToTry.add(geminiModel.trim());
        }
        if (!modelsToTry.contains("gemini-1.5-flash")) modelsToTry.add("gemini-1.5-flash");
        if (!modelsToTry.contains("gemini-2.0-flash")) modelsToTry.add("gemini-2.0-flash");
        if (!modelsToTry.contains("gemini-1.5-pro")) modelsToTry.add("gemini-1.5-pro");

        String systemInstruction = buildSystemPrompt(catalogProducts);

        Map<String, Object> requestBody = new HashMap<>();

        // System Instruction
        requestBody.put("systemInstruction", Map.of(
                "parts", List.of(Map.of("text", systemInstruction))
        ));

        // Contents (conversation history + latest message)
        List<Map<String, Object>> contents = new ArrayList<>();
        if (history != null && !history.isEmpty()) {
            int start = Math.max(0, history.size() - 6);
            for (int i = start; i < history.size(); i++) {
                AiChatMessageDto msg = history.get(i);
                String role = "user".equalsIgnoreCase(msg.getRole()) ? "user" : "model";
                contents.add(Map.of(
                        "role", role,
                        "parts", List.of(Map.of("text", msg.getContent()))
                ));
            }
        }
        contents.add(Map.of(
                "role", "user",
                "parts", List.of(Map.of("text", userMessage))
        ));
        requestBody.put("contents", contents);

        // Generation Config: limit output tokens to 500 to save cost and keep replies concise
        requestBody.put("generationConfig", Map.of(
                "temperature", 0.7,
                "maxOutputTokens", 500,
                "topP", 0.95
        ));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        for (String modelName : modelsToTry) {
            try {
                String url = String.format("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
                        modelName, geminiApiKey);

                HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
                ResponseEntity<String> response = restTemplate.postForEntity(url, entity, String.class);

                if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                    JsonNode root = objectMapper.readTree(response.getBody());
                    JsonNode candidates = root.path("candidates");
                    if (candidates.isArray() && !candidates.isEmpty()) {
                        JsonNode textNode = candidates.get(0).path("content").path("parts").get(0).path("text");
                        if (!textNode.isMissingNode() && !textNode.asText().isBlank()) {
                            log.info("Gemini model '{}' responded successfully", modelName);
                            return textNode.asText();
                        }
                    }
                }
            } catch (Exception ex) {
                log.warn("Gemini model '{}' call failed: {}. Trying fallback model if available...", modelName, ex.getMessage());
            }
        }

        return null;
    }

    /**
     * Build comprehensive System Prompt for Gemini
     */
    private String buildSystemPrompt(List<Product> products) {
        StringBuilder sb = new StringBuilder();
        sb.append("Bạn là TechBot - Trợ lý ảo tư vấn công nghệ & bán hàng thông minh của TechStore (chuỗi bán lẻ thiết bị công nghệ chính hãng).\n\n");
        sb.append("NHIỆM VỤ VÀ PHONG CÁCH:\n");
        sb.append("- Tư vấn nhiệt tình, thân thiện, xưng hô 'em' hoặc 'TechStore', gọi khách là 'bạn' hoặc 'quý khách'.\n");
        sb.append("- Trả lời ngắn gọn, súc tích (tối đa 150-250 từ), dùng gạch đầu dòng rõ ràng và emoji sinh động.\n");
        sb.append("- Chỉ tư vấn về sản phẩm công nghệ, phụ kiện, mua sắm và dịch vụ của TechStore. Từ chối lịch sự nếu khách hỏi các chủ đề ngoài lề (làm thơ, toán học, chính trị, viết code...).\n\n");

        sb.append("DANH MỤC SẢN PHẨM TECHSTORE KINH DOANH:\n");
        sb.append("- TechStore kinh doanh đầy đủ 4 nhóm sản phẩm chính hãng 100%:\n");
        sb.append("  1. Điện thoại thông minh (iPhone, Samsung Galaxy, Xiaomi, Oppo, Vivo, Realme...)\n");
        sb.append("  2. Laptop & Máy tính (MacBook, Asus, Acer, Lenovo, Dell, HP, MSI...)\n");
        sb.append("  3. Máy tính bảng (iPad, Samsung Galaxy Tab, Xiaomi Pad...)\n");
        sb.append("  4. Thiết bị âm thanh & Phụ kiện (Loa Bluetooth JBL/Marshall, tai nghe không dây, đồng hồ thông minh, củ sạc, cáp sạc, chuột bàn phím...)\n\n");

        sb.append("QUY TẮC PHẢN HỒI QUAN TRỌNG (BẮT BUỘC TUÂN THỦ):\n");
        sb.append("1. TUYỆT ĐỐI KHÔNG TỰ BỊA ĐẶT rằng TechStore 'không bán', 'ngừng kinh doanh' hay 'chỉ tập trung vào loa/phụ kiện' đối với bất kỳ ngành hàng nào kể trên.\n");
        sb.append("2. Nếu khách hỏi sản phẩm hoặc mẫu mã cụ thể mà trong danh sách sản phẩm mẫu bên dưới chưa có: Hãy giải thích lịch sự rằng mẫu cụ thể đó có thể đang tạm hết hàng hoặc chưa hiển thị ở lượt gợi ý này, đồng thời tư vấn các mẫu tương đương đang có trong danh sách hoặc mời khách xem thêm trên thanh tìm kiếm của ứng dụng.\n");
        sb.append("3. Khi giới thiệu sản phẩm có trong danh sách bên dưới, hãy nêu chính xác Tên máy, Giá bán và Thời hạn bảo hành.\n");
        sb.append("4. Nếu khách hỏi 'giá rẻ', 'tiết kiệm', 'sinh viên', hãy ưu tiên tư vấn các sản phẩm có mức giá mềm nhất trong danh sách phù hợp với nhu cầu của khách.\n\n");

        sb.append("CHÍNH SÁCH CỬA HÀNG TECHSTORE:\n");
        sb.append("1. ĐỔI TRẢ & HOÀN TIỀN: 1 đổi 1 hoặc hoàn tiền trong vòng 7 NGÀY kể từ ngày nhận hàng thành công nếu máy bị lỗi phần cứng do nhà sản xuất. Khách có thể gửi yêu cầu trực tuyến ngay trong chi tiết đơn hàng trên app.\n");
        sb.append("2. BẢO HÀNH CHÍNH HÃNG: 100% sản phẩm chính hãng, thời hạn bảo hành 12 - 24 tháng theo hãng. Khách hàng chỉ cần xuất Hóa đơn điện tử PDF từ app để bảo hành tại mọi trung tâm ủy quyền toàn quốc (Apple, Asus, Samsung, v.v.).\n");
        sb.append("3. GIAO HÀNG: Miễn phí vận chuyển toàn quốc cho đơn hàng từ 5.000.000 VNĐ hoặc khi khách chọn Nhận tại cửa hàng. Đơn dưới 5 triệu có phí giao hàng tiêu chuẩn là 30.000 VNĐ. Thời gian giao hàng 2 - 4 ngày.\n");
        sb.append("4. THANH TOÁN: Hỗ trợ tiền mặt khi nhận hàng (COD), ví điện tử VNPay, chuyển khoản ngân hàng và thẻ quốc tế.\n\n");

        if (products != null && !products.isEmpty()) {
            sb.append("DANH SÁCH MỘT SỐ SẢN PHẨM PHÙ HỢP TẠI CỬA HÀNG (TRÍCH XUẤT TỪ DATABASE):\n");
            for (Product p : products) {
                String priceStr = p.getPrice() != null ? PRICE_FORMAT.format(p.getPrice()) : "Liên hệ";
                int warranty = p.getWarrantyMonths() != null ? p.getWarrantyMonths() : 12;
                String catName = p.getCategory() != null ? p.getCategory().getName() : "";
                String brandName = p.getBrand() != null ? p.getBrand().getName() : "";
                sb.append(String.format("- [%s / %s] %s | Giá: %s | Bảo hành: %d tháng chính hãng\n",
                        catName, brandName, p.getName(), priceStr, warranty));
            }
        }

        return sb.toString();
    }

    /**
     * Fallback Intelligent Rule Engine when Gemini key is not configured or fails
     */
    private AiChatResponse generateSmartAdvisorReply(String userMessage, List<Product> relevantProducts, List<ProductSummaryDto> productDtos) {
        String norm = removeDiacritics(userMessage);
        StringBuilder reply = new StringBuilder();
        List<String> quickReplies = new ArrayList<>();

        if (norm.contains("doi tra") || norm.contains("tra hang") || norm.contains("hoan tien") || norm.contains("7 ngay") || norm.contains("doi may")) {
            reply.append("Dạ chào bạn! TechStore cam kết quyền lợi tối đa cho khách hàng với **Chính sách Đổi trả & Hoàn tiền** như sau:\n\n");
            reply.append("🔄 **Thời hạn hiệu lực:** Trong vòng **7 ngày** kể từ khi nhận hàng thành công.\n");
            reply.append("🛠️ **Điều kiện áp dụng:** Sản phẩm phát sinh lỗi phần cứng do nhà sản xuất (giữ nguyên phụ kiện, hộp máy).\n");
            reply.append("📱 **Thao tác cực dễ dàng trên App:**\n");
            reply.append("  1. Vào mục **Đơn hàng của tôi** > chọn đơn đã nhận.\n");
            reply.append("  2. Bấm nút **'Yêu cầu Đổi trả / Hoàn tiền'**.\n");
            reply.append("  3. Chọn lý do, tải ảnh lỗi và nhập STK ngân hàng nhận tiền hoàn.\n\n");
            reply.append("Shop sẽ duyệt yêu cầu và hỗ trợ thu hồi máy tận nơi hoàn toàn miễn phí ạ!");

            quickReplies.add("Chính sách bảo hành");
            quickReplies.add("Phí giao hàng bao nhiêu?");
            quickReplies.add("Tư vấn điện thoại giá rẻ");
        } else if (norm.contains("bao hanh") || norm.contains("bao lau") || norm.contains("hoa don") || norm.contains("pdf") || norm.contains("trung tam")) {
            reply.append("Dạ TechStore xin thông tin đến bạn về **Chính sách Bảo hành chính hãng**:\n\n");
            reply.append("🛡️ **Thời hạn bảo hành:** Tiêu chuẩn **12 - 24 tháng** chính hãng cho từng dòng sản phẩm.\n");
            reply.append("📄 **Bảo hành điện tử bằng Hóa đơn PDF:** Bạn chỉ cần vào chi tiết đơn hàng trên app > bấm **'Xuất hóa đơn PDF'** là có thể đem đến bất kỳ trung tâm bảo hành ủy quyền nào của Apple, Asus, Samsung, Dell... trên toàn quốc.\n");
            reply.append("🔄 **Đặc biệt:** Trong 7 ngày đầu tiên nếu phát sinh lỗi phần cứng, shop hỗ trợ đổi mới ngay lập tức!");

            quickReplies.add("Chính sách đổi trả 7 ngày");
            quickReplies.add("Top điện thoại bán chạy");
            quickReplies.add("Phương thức thanh toán");
        } else if (norm.contains("giao hang") || norm.contains("ship") || norm.contains("van chuyen") || norm.contains("phi")) {
            reply.append("Dạ về chính sách giao hàng tại TechStore:\n\n");
            reply.append("🚚 **Miễn phí vận chuyển (Freeship):** Áp dụng cho mọi đơn hàng từ **5.000.000 VNĐ** trên toàn quốc hoặc khi chọn **Nhận tại cửa hàng**.\n");
            reply.append("📦 Đơn hàng dưới 5 triệu có phí giao hàng tiêu chuẩn là 30.000 VNĐ.\n");
            reply.append("⏱️ **Thời gian nhận hàng:**\n");
            reply.append("  - Nội thành: 1 - 2 ngày làm việc.\n");
            reply.append("  - Các tỉnh thành khác: 2 - 4 ngày làm việc.\n");
            reply.append("📦 Hàng được đóng gói 3 lớp chống sốc và dán tem niêm phong bảo đảm an toàn tuyệt đối!");

            quickReplies.add("Hỗ trợ thanh toán COD không?");
            quickReplies.add("Chính sách đổi trả 7 ngày");
            quickReplies.add("Tư vấn điện thoại giá tốt");
        } else if (norm.contains("thanh toan") || norm.contains("cod") || norm.contains("vnpay") || norm.contains("chuyen khoan") || norm.contains("tra gop")) {
            reply.append("Dạ TechStore hỗ trợ đa dạng phương thức thanh toán an toàn và tiện lợi:\n\n");
            reply.append("💵 **Thanh toán khi nhận hàng (COD):** Khách nhận máy, kiểm tra bên ngoài trước khi thanh toán tiền mặt cho shipper.\n");
            reply.append("💳 **Thanh toán Online VNPay:** Quét mã QR qua ứng dụng ngân hàng hoặc ví VNPay.\n");
            reply.append("🏦 **Chuyển khoản trực tiếp:** Quét mã VietQR chuyển khoản nhanh 24/7 theo hướng dẫn khi đặt hàng.");

            quickReplies.add("Tư vấn laptop sinh viên");
            quickReplies.add("Chính sách bảo hành");
            quickReplies.add("Phí giao hàng bao nhiêu?");
        } else if (norm.contains("dien thoai") || norm.contains("dienthoai") || norm.contains("dt ") || norm.endsWith(" dt") || norm.equals("dt")
                || norm.contains("iphone") || norm.contains("samsung") || norm.contains("smartphone") || norm.contains("oppo") || norm.contains("xiaomi")) {
            reply.append("Dạ chào bạn! Dưới đây là các mẫu **Điện thoại thông minh chính hãng** nổi bật với mức giá cực tốt tại TechStore:\n\n");
            if (relevantProducts != null && !relevantProducts.isEmpty()) {
                for (Product p : relevantProducts.stream().limit(3).toList()) {
                    String priceStr = p.getPrice() != null ? PRICE_FORMAT.format(p.getPrice()) : "Liên hệ";
                    reply.append(String.format("📱 **%s**\n  - Giá ưu đãi: `%s`\n  - Bảo hành: %d tháng chính hãng, đổi trả 7 ngày.\n\n",
                            p.getName(), priceStr, p.getWarrantyMonths() != null ? p.getWarrantyMonths() : 12));
                }
            }
            reply.append("👉 Bạn hãy bấm vào thẻ sản phẩm bên dưới để xem hình ảnh chi tiết và đặt hàng nhé!");

            quickReplies.add("Điện thoại pin trâu giá rẻ");
            quickReplies.add("Chính sách bảo hành");
            quickReplies.add("Giao hàng mất bao lâu?");
        } else if (norm.contains("laptop") || norm.contains("lap top") || norm.contains("may tinh") || norm.contains("gaming")
                || norm.contains("sinh vien") || norm.contains("hoc tap") || norm.contains("van phong") || norm.contains("macbook")) {
            reply.append("Dạ chào bạn! TechStore xin gợi ý các mẫu **Laptop chính hãng** đang bán rất chạy với cấu hình tối ưu theo nhu cầu của bạn:\n\n");
            if (relevantProducts != null && !relevantProducts.isEmpty()) {
                for (Product p : relevantProducts.stream().limit(3).toList()) {
                    String priceStr = p.getPrice() != null ? PRICE_FORMAT.format(p.getPrice()) : "Liên hệ";
                    reply.append(String.format("💻 **%s**\n  - Giá ưu đãi: `%s`\n  - Bảo hành: %d tháng chính hãng, đổi trả 7 ngày.\n\n",
                            p.getName(), priceStr, p.getWarrantyMonths() != null ? p.getWarrantyMonths() : 12));
                }
            }
            reply.append("👉 Bạn có thể bấm vào thẻ sản phẩm bên dưới để xem chi tiết thông số kỹ thuật và đặt hàng nhé!");

            quickReplies.add("Laptop gaming cấu hình cao");
            quickReplies.add("Laptop mỏng nhẹ dưới 15tr");
            quickReplies.add("Chính sách đổi trả 7 ngày");
        } else if (norm.contains("tablet") || norm.contains("ipad") || norm.contains("may tinh bang")) {
            reply.append("Dạ chào bạn! TechStore xin gợi ý các mẫu **Máy tính bảng (Tablet / iPad)** chính hãng đa năng phục vụ học tập, giải trí và làm việc:\n\n");
            if (relevantProducts != null && !relevantProducts.isEmpty()) {
                for (Product p : relevantProducts.stream().limit(3).toList()) {
                    String priceStr = p.getPrice() != null ? PRICE_FORMAT.format(p.getPrice()) : "Liên hệ";
                    reply.append(String.format("📱 **%s**\n  - Giá ưu đãi: `%s`\n  - Bảo hành: %d tháng chính hãng.\n\n",
                            p.getName(), priceStr, p.getWarrantyMonths() != null ? p.getWarrantyMonths() : 12));
                }
            }
            quickReplies.add("iPad giá tốt nhất");
            quickReplies.add("Samsung Galaxy Tab");
            quickReplies.add("Chính sách bảo hành");
        } else if (norm.contains("loa") || norm.contains("tai nghe") || norm.contains("am thanh") || norm.contains("dong ho") || norm.contains("phu kien")) {
            reply.append("Dạ chào bạn! TechStore xin gợi ý các mẫu **Thiết bị âm thanh & Phụ kiện công nghệ chính hãng** nổi bật:\n\n");
            if (relevantProducts != null && !relevantProducts.isEmpty()) {
                for (Product p : relevantProducts.stream().limit(3).toList()) {
                    String priceStr = p.getPrice() != null ? PRICE_FORMAT.format(p.getPrice()) : "Liên hệ";
                    reply.append(String.format("🎧 **%s**\n  - Giá ưu đãi: `%s`\n  - Bảo hành: %d tháng chính hãng.\n\n",
                            p.getName(), priceStr, p.getWarrantyMonths() != null ? p.getWarrantyMonths() : 12));
                }
            }
            quickReplies.add("Loa Bluetooth JBL/Marshall");
            quickReplies.add("Tai nghe không dây pin trâu");
            quickReplies.add("Chính sách đổi trả 7 ngày");
        } else {
            // Friendly General Welcome / Assist
            reply.append("Dạ xin chào bạn! Em là **TechBot** - Trợ lý thông minh của TechStore. 🤖✨\n\n");
            reply.append("Em có thể hỗ trợ bạn:\n");
            reply.append("💡 **Tư vấn chọn thiết bị:** Điện thoại thông minh, laptop văn phòng/gaming, tablet, loa & tai nghe theo ngân sách.\n");
            reply.append("🛡️ **Chính sách:** Đổi trả trong 7 ngày, bảo hành 12 - 24 tháng chính hãng và xuất hóa đơn PDF.\n");
            reply.append("🚚 **Hỗ trợ mua sắm:** Miễn phí vận chuyển đơn từ 5 triệu (hoặc nhận tại cửa hàng), thanh toán COD hoặc VNPay tiện lợi.\n\n");
            reply.append("Bạn đang quan tâm đến dòng sản phẩm nào hoặc cần tư vấn tầm giá bao nhiêu ạ?");

            quickReplies.add("Điện thoại giá rẻ dưới 5tr");
            quickReplies.add("Laptop sinh viên dưới 15tr");
            quickReplies.add("Chính sách đổi trả & bảo hành");
        }

        return AiChatResponse.builder()
                .reply(reply.toString())
                .suggestedProducts(productDtos)
                .quickReplies(quickReplies)
                .fromAi(false)
                .build();
    }

    private List<String> generateQuickReplies(String userMessage) {
        String norm = removeDiacritics(userMessage);
        if (norm.contains("laptop") || norm.contains("may tinh")) {
            return List.of("Laptop gaming cấu hình cao", "Laptop mỏng nhẹ dưới 15tr", "Chính sách bảo hành");
        } else if (norm.contains("dien thoai") || norm.contains("dienthoai") || norm.contains("dt") || norm.contains("phone")) {
            return List.of("Điện thoại pin trâu giá rẻ", "Điện thoại dưới 5 triệu", "Chính sách đổi trả 7 ngày");
        } else if (norm.contains("tablet") || norm.contains("ipad")) {
            return List.of("iPad chính hãng giá tốt", "Samsung Galaxy Tab", "Chính sách bảo hành");
        } else if (norm.contains("loa") || norm.contains("tai nghe")) {
            return List.of("Loa Bluetooth bán chạy", "Tai nghe chống ồn", "Chính sách đổi trả 7 ngày");
        } else {
            return List.of("Điện thoại giá rẻ dưới 5tr", "Laptop sinh viên văn phòng", "Chính sách bảo hành 12 tháng");
        }
    }
}
