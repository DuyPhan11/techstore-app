package com.techstore.service;

import com.techstore.dto.AddressDto;
import com.techstore.dto.AddressRequest;
import com.techstore.entity.User;

import java.util.List;

public interface AddressService {
    List<AddressDto> getMyAddresses(User user);

    AddressDto getAddressById(User user, Long id);

    AddressDto getDefaultAddress(User user);

    AddressDto createAddress(User user, AddressRequest request);

    AddressDto updateAddress(User user, Long id, AddressRequest request);

    void deleteAddress(User user, Long id);

    AddressDto setDefaultAddress(User user, Long id);
}
