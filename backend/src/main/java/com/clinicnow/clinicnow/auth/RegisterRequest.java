package com.clinicnow.clinicnow.auth;

public record RegisterRequest(
        String email,
        String password,
        String fullName,
        String phone,
        String role) {
}