package com.clinicnow.clinicnow.auth;

public record AuthRequest(
        String email,
        String password) {
}