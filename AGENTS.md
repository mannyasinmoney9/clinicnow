# AGENTS.md — ClinicNow Agent Guidance

Critical context for Kilo agents working on ClinicNow repo:

## 🚨 Critical Setup (Easy to Miss)
- **Backend doesn't exist yet** - Must be created per CLAUDE.md Phase 0 using start.spring.io
- **Java 21 required** - Not just any Java version; specifically 21 LTS (Adoptium/Eclipse Temurin)
- **Flutter SDK path hardcoded** in run_dev.ps1: `C:\Users\DELL GAMING\Documents\flutter_windows_3.41.5-stable\flutter`
- **Device ID hardcoded** in run_dev.ps1: Samsung device `R58R41QZAYL` (change for your device)
- **Maven path hardcoded** in run_dev.ps1: Points to specific IntelliJ installation
- **Junction/Symlinks required**: run_dev.ps1 creates `F:` drive mapping and `C:\pc` junction for Pub cache

## 🔑 Secrets & Configuration (Never Commit)
- **Backend secrets**: Go in `backend/src/main/resources/application.yml` (create from example)
  - Read from env vars: `${GEMINI_API_KEY}`, `${PAYSTACK_SECRET_KEY}`, etc.
- **Flutter secrets**: Via `--dart-define` or `.env` (never committed)
  - Required: `API_BASE_URL`, `AGORA_APP_ID`, EmailJS keys (if using)
- **Provided files**: `.env.example`, `backend/application.yml.example` - copy and fill

## ⚙️ Development Commands (Non-Obvious)
- **Backend only**: `.\run_dev.ps1 backend`
- **Flutter only (emulator)**: `.\run_dev.ps1 emulator`
- **Flutter + phone**: `.\run_dev.ps1 phone` (requires `adb reverse` setup)
- **Full stack**: `.\run_dev.ps1 all` (backend + phone)
- **Health check**: Backend should be reachable at `http://10.0.2.2:8080/api/health` (emulator) or laptop LAN IP (physical device)

## 🏗️ Architecture (Not Obvious from Structure)
- **Monorepo**: Flutter app at root, Spring Boot backend in `backend/` (create per instructions)
- **Communication**: 
  - REST + JWT: `dio` interceptor automatically attaches token
  - Realtime: `stomp_dart_client` over WebSocket/STOMP (`/ws` endpoint)
  - Fallback: REST polling every 3s if WebSocket fails
- **State Management**: Riverpod 3.x (`flutter_riverpod` + `riverpod_annotation`)
- **Routing**: go_router with role-based redirects (PATIENT/STAFF/ADMIN)
- **DI**: Constructor injection only (no service locator)

## 🧪 Testing & Quality (Easy to Overlook)
- **Flutter lints**: `very_good_analysis` equivalent via `flutter_lints: ^6.0.0` + custom rules in `analysis_options.yaml`
  - Currently excludes: `lib/core/widgets/signature_widgets.dart`
  - Zero warnings goal: `flutter analyze --no-fatal-infos --no-fatal-warnings`
- **Backend tests**: 
  - Controllers: JUnit 5 + MockMvc
  - Repositories: `@DataJpaTest`
  - Service logic: Unit tests for queue position calculations
- **Run tests**: 
  - Flutter: `flutter test`
  - Backend: `./mvnw test` (once backend exists)

## 📱 Device & Emulator Gotchas
- **Emulator IP**: Use `10.0.2.2:8080` for localhost
- **Physical phone**: Must be on same WiFi as laptop; use laptop's LAN IP
- **Port forwarding**: `adb reverse tcp:8080 tcp:8080` needed for emulator to see backend
- **APK size**: Must stay <30MB split by ABI - enable `splitPerAbi` in `build.gradle`
- **Multidex**: Required for Flutter + Agora (when enabled) + other deps

## 🔌 Service Integrations (Third-Party Gotchas)
- **Paystack**: 
  - Verify payments **server-side ONLY** (`POST /api/payments/verify`)
  - Use test keys: `pk_test_...` / `sk_test_...` 
  - Amount in **kobo** (₦1 = 100 kobo)
  - Webhook: Validate `x-paystack-signature` with HMAC-SHA512
- **Agora** (when enabled):
  - Testing mode only for demo
  - Android: Requires specific ProGuard rules and NDK compatibility
  - Fallback: Bundled MP4 video when offline/no permission
- **Email**: 
  - Either EmailJS (client-side) OR Spring Mail + Gmail app password
  - **Critical**: Email failure MUST NOT block core flows (queue/appointment)

## 📱💨 Realtime Queue (The "WOW" Feature - Don't Fake This!)
- **Must be real**: Spring Boot WebSocket/STOMP (`/ws` with SockJS fallback)
- **Broadcast**: Full queue snapshot on `/topic/clinics/{id}/queue` for all changes
- **Per-user**: `/topic/users/{id}` for "you're next" alerts
- **Robustness**: 
  - Auto-reconnect with exponential backoff
  - Heartbeats enabled
  - Optimistic UI updates reconciled by server broadcast
  - Silent REST polling fallback (~3s) if WS fails
- **Two-device demo**: 
  - Staff board: projector/emulator #1 
  - Patient check-in: emulator #2 or physical phone
  - Hand phone to student to trigger live update

## 🚀 Build Order (Critical Path)
1. **Phase 0**: Backend skeleton + Flutter health check
2. **Phase 1**: Auth + onboarding (NDPA consent granular, never pre-checked)
3. **Phase 2**: Queue (realtime heart - MUST work across 2 devices)
4. **Phase 3-11**: Additional features (teleconsult, payments, Ada bot, etc.)

## 🚫 What NOT to Do
- Don't use Firebase/Firestore (superseded by Spring Boot + SQL)
- Don't commit secrets (use env vars/.env)
- Don't skip backend tests (JUnit 5 + MockMvc required)
- Don't make animations decorative (must relate to medical context)
- Don't break the vertical slice - keep both tiers runnable after each phase

## 📚 Key Reference Files
- **CLAUDE.md** - Primary spec (backend sections override BLUEPRINT.md)
- **docs/BLUEPRINT.md** - Frontend/domain only (palette, UX, medical context)
- **run_dev.ps1** - Dev workflow (note hardcoded paths)
- **.env.example** - Template for Flutter secrets
- **backend/application.yml.example** - Template for backend secrets