package com.clinicnow.clinicnow.auth;

public record AuthResponse(
        String accessToken,
        String tokenType) {
}