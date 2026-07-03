package com.clinicnow.clinicnow.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class RegisterRequest {
    @NotBlank @Email
    private String email;
    @NotBlank
    private String password;
    @NotBlank
    private String fullName;
    private String phone;
    private String role;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}