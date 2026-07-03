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
        if (userRepository.findByEmail("manniboh@gmail.com").isEmpty()) {
            userRepository.save(User.builder()
                    .email("manniboh@gmail.com")
                    .password(passwordEncoder.encode("Password123"))
                    .fullName("Admin User")
                    .role(User.Role.ADMIN)
                    .build());
            System.out.println("Created admin: manniboh@gmail.com / Password123");
        }

        if (userRepository.findByEmail("patient@demo.com").isEmpty()) {
            userRepository.save(User.builder()
                    .email("patient@demo.com")
                    .password(passwordEncoder.encode("DemoPass123"))
                    .fullName("Patient Demo")
                    .role(User.Role.PATIENT)
                    .build());
            System.out.println("Created patient: patient@demo.com / DemoPass123");
        }

        if (userRepository.findByEmail("staff@demo.com").isEmpty()) {
            userRepository.save(User.builder()
                    .email("staff@demo.com")
                    .password(passwordEncoder.encode("DemoPass123"))
                    .fullName("Staff Demo")
                    .role(User.Role.STAFF)
                    .build());
            System.out.println("Created staff: staff@demo.com / DemoPass123");
        }

        System.out.println("Seed data loaded.");
    }
}