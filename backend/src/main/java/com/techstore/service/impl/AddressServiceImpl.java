package com.techstore.service.impl;

import com.techstore.dto.AddressDto;
import com.techstore.dto.AddressRequest;
import com.techstore.entity.Address;
import com.techstore.entity.User;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.repository.AddressRepository;
import com.techstore.service.AddressService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AddressServiceImpl implements AddressService {

    private final AddressRepository addressRepository;

    @Override
    @Transactional(readOnly = true)
    public List<AddressDto> getMyAddresses(User user) {
        return addressRepository.findByUserIdOrderByIsDefaultDescCreatedAtDesc(user.getId())
                .stream()
                .map(AddressDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public AddressDto getAddressById(User user, Long id) {
        Address address = addressRepository.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy địa chỉ với ID: " + id));
        return AddressDto.fromEntity(address);
    }

    @Override
    @Transactional(readOnly = true)
    public AddressDto getDefaultAddress(User user) {
        return addressRepository.findByUserIdAndIsDefaultTrue(user.getId())
                .map(AddressDto::fromEntity)
                .orElse(null);
    }

    @Override
    @Transactional
    public AddressDto createAddress(User user, AddressRequest request) {
        long addressCount = addressRepository.countByUserId(user.getId());
        boolean shouldBeDefault = Boolean.TRUE.equals(request.getIsDefault()) || addressCount == 0;

        if (shouldBeDefault && addressCount > 0) {
            addressRepository.resetDefaultAddressForUser(user.getId());
        }

        Address address = Address.builder()
                .user(user)
                .recipientName(request.getRecipientName().trim())
                .phone(request.getPhone().trim())
                .streetAddress(request.getStreetAddress().trim())
                .ward(request.getWard() != null ? request.getWard().trim() : null)
                .district(request.getDistrict() != null ? request.getDistrict().trim() : null)
                .city(request.getCity().trim())
                .isDefault(shouldBeDefault)
                .build();

        Address saved = addressRepository.save(address);
        log.info("Address created with ID: {} for user: {}", saved.getId(), user.getEmail());
        return AddressDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public AddressDto updateAddress(User user, Long id, AddressRequest request) {
        Address address = addressRepository.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy địa chỉ với ID: " + id));

        boolean shouldBeDefault = Boolean.TRUE.equals(request.getIsDefault());

        if (shouldBeDefault && !Boolean.TRUE.equals(address.getIsDefault())) {
            addressRepository.resetDefaultAddressForUser(user.getId());
        }

        address.setRecipientName(request.getRecipientName().trim());
        address.setPhone(request.getPhone().trim());
        address.setStreetAddress(request.getStreetAddress().trim());
        address.setWard(request.getWard() != null ? request.getWard().trim() : null);
        address.setDistrict(request.getDistrict() != null ? request.getDistrict().trim() : null);
        address.setCity(request.getCity().trim());
        if (shouldBeDefault) {
            address.setIsDefault(true);
        }

        Address saved = addressRepository.save(address);
        log.info("Address updated with ID: {} for user: {}", saved.getId(), user.getEmail());
        return AddressDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public void deleteAddress(User user, Long id) {
        Address address = addressRepository.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy địa chỉ với ID: " + id));

        boolean wasDefault = Boolean.TRUE.equals(address.getIsDefault());
        addressRepository.delete(address);
        log.info("Address deleted with ID: {} for user: {}", id, user.getEmail());

        if (wasDefault) {
            List<Address> remaining = addressRepository.findByUserIdOrderByIsDefaultDescCreatedAtDesc(user.getId());
            if (!remaining.isEmpty()) {
                Address newDefault = remaining.get(0);
                newDefault.setIsDefault(true);
                addressRepository.save(newDefault);
            }
        }
    }

    @Override
    @Transactional
    public AddressDto setDefaultAddress(User user, Long id) {
        Address address = addressRepository.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy địa chỉ với ID: " + id));

        addressRepository.resetDefaultAddressForUser(user.getId());
        address.setIsDefault(true);
        Address saved = addressRepository.save(address);
        log.info("Address ID {} set as default for user: {}", id, user.getEmail());
        return AddressDto.fromEntity(saved);
    }
}
