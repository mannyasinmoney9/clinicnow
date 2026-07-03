package com.clinicnow.clinicnow.auth;

public class AuthResponse {
    private String accessToken;
    private String tokenType = "Bearer";
    private Long userId;
    private String email;
    private String fullName;
    private String role;

    public AuthResponse(String accessToken, Long userId, String email, String fullName, String role) {
        this.accessToken = accessToken;
        this.userId = userId;
        this.email = email;
        this.fullName = fullName;
        this.role = role;
    }

    public String getAccessToken() { return accessToken; }
    public void setAccessToken(String accessToken) { this.accessToken = accessToken; }
    public String getTokenType() { return tokenType; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}