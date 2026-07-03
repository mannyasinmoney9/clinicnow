package com.clinicnow.clinicnow.config;

import com.clinicnow.clinicnow.user.User;
import com.clinicnow.clinicnow.user.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class SeedRunner implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public SeedRunner(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        // Create admin demo account
        if (userRepository.findByEmail("manniboh@gmail.com").isEmpty()) {
            User admin = User.builder()
                    .email("manniboh@gmail.com")
                    .password(passwordEncoder.encode("Password123"))
                    .fullName("Admin User")
                    .role(User.Role.ADMIN)
                    .build();
            userRepository.save(admin);
            System.out.println("Created admin demo account: manniboh@gmail.com / Password123");
        }

        // Create patient demo account
        if (userRepository.findByEmail("patient@demo.com").isEmpty()) {
            User patient = User.builder()
                    .email("patient@demo.com")
                    .password(passwordEncoder.encode("DemoPass123"))
                    .fullName("Patient Demo")
                    .role(User.Role.PATIENT)
                    .build();
            userRepository.save(patient);
            System.out.println("Created patient demo account: patient@demo.com / DemoPass123");
        }

        // Create staff demo account
        if (userRepository.findByEmail("staff@demo.com").isEmpty()) {
            User staff = User.builder()
                    .email("staff@demo.com")
                    .password(passwordEncoder.encode("DemoPass123"))
                    .fullName("Staff Demo")
                    .role(User.Role.STAFF)
                    .build();
            userRepository.save(staff);
            System.out.println("Created staff demo account: staff@demo.com / DemoPass123");
        }

        System.out.println("Seed data loaded successfully.");
    }
}