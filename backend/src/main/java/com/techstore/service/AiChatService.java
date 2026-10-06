package com.techstore.service;

import com.techstore.dto.AiChatRequest;
import com.techstore.dto.AiChatResponse;

public interface AiChatService {
    AiChatResponse chat(AiChatRequest request);
}
