package com.techstore.service;

import com.techstore.dto.PageResponse;
import com.techstore.dto.InventoryDto;
import com.techstore.dto.InventoryFilterParams;
import com.techstore.dto.StockAdjustmentRequest;
import com.techstore.dto.StockTransferRequest;

public interface InventoryService {

    PageResponse<InventoryDto> getInventory(InventoryFilterParams params);

    InventoryDto adjustStock(StockAdjustmentRequest request);

    void transferStock(StockTransferRequest request);
}


