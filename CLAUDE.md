# CLAUDE.md — ClinicNow build brief (read this first, every session)

You are my senior **full-stack** engineer + product designer building **ClinicNow**, a telemedicine + clinic-queue app for **peri-urban Nigeria** (Ikorodu, Sango-Ota, Choba, Rumuokoro). Final-year class project. **40 students present on Thursday and I am building to take first place.** Treat every screen and every endpoint as a portfolio piece.

This is **full-stack**: a **Flutter** app talking to a **Spring Boot** backend I am also building. **No budget — everything runs on free tiers with no credit card.** The backend runs **locally on my laptop** for the demo (no cloud, no cards, no cold starts).

- IDE: **IntelliJ IDEA Community Edition** (Flutter/Dart plugins for the app; plain Java/Maven for the backend).
- Repo root folder: **`ClinicNow2`**. The Flutter project already exists at the repo root. The Spring Boot backend lives in **`ClinicNow2/backend/`**.

---

## 0. Non-negotiable ground rules

1. **`docs/BLUEPRINT.md` is authoritative for the FRONTEND and DOMAIN only** — versions of Flutter packages, palette, typography, Pidgin strings, Nigerian healthcare context, UX conventions, triage flow, immunisation/antenatal schedules, device constraints. **Its BACKEND sections are SUPERSEDED by this file** — ignore everything in the blueprint about Firebase, Firestore, the 50K-reads budget, Cloud Functions, custom claims, and FCM-as-primary. We use **Spring Boot + JWT + a SQL database + WebSocket** instead.
2. **Vertical slice first.** The first thing that must work end-to-end is: register/login on the Flutter app → JWT from Spring Boot → patient joins queue → staff board updates live over WebSocket. Get that spine solid before any feature work.
3. **Both tiers must always run.** After every phase: the backend starts with one command and the Flutter app launches on the emulator and talks to it. Never end a session with either side broken.
4. **Commit after every working phase** (`feat(queue): live STOMP board`). Init git at the repo root with a `.gitignore` covering `build/`, `target/`, `.dart_tool/`, `*.jks`, `*.keystore`, `.env`, and any service-account/keys.
5. **Secrets never committed.** Backend secrets in `backend/src/main/resources/application.yml` read from env vars (`${GEMINI_API_KEY}` etc.); provide `application.yml.example`. Flutter secrets via `--dart-define`; provide `run_dev.sh`/`run_dev.ps1` and `.env.example`.
6. **Ask before destructive actions** (deleting files, `git reset --hard`, rewriting files you didn't create). Otherwise work autonomously.
7. **APK budget < 30 MB**, split by ABI. Offline-first on the client (38.6% of subscriptions are still 2G): cache, render optimistically, retry with jittered backoff.
8. End each phase with a short checklist of what now works and the exact commands to run/test it.

---

## 1. What makes this win

39 students will show plain CRUD apps. ClinicNow wins on **five** things:

- **⭐ Live, real (not mocked) realtime across two devices** — the queue board updates the instant a patient checks in, shown on a second screen in front of the class (full spec in §2). This is the moment that wins the room, and it's 100% free (Spring Boot WebSocket on your laptop).
- **A real backend.** A teacher can hit Swagger UI, watch live rows in the H2 console, and see server-side Paystack verification + JWT role security. This alone separates you from Firebase-only projects.
- **Bespoke, meaningful, medical-themed motion** (§5) — purposeful animation that *means* something, not fade-ins everywhere.
- **A real AI triage assistant** (§4) in English + Pidgin, proxied through the backend, with a rule-based offline fallback so it never dies on stage.
- **Genuine local fit** — Pidgin localization, NDPA consent (not HIPAA), kobo-correct payments, SMS-style receipts, traffic-light triage, immunisation/antenatal reminders.

Polish bar for every screen: skeleton loader, empty state (Lottie + copy + CTA), error state (retry), success animation, **🔊 read-aloud** (`flutter_tts`), 56dp tap targets. Zero `very_good_analysis` warnings on the app; clean layered code on the backend.

---

## 2. Architecture

```
[ Flutter app (emulator) ]  --HTTPS/REST + JWT-->  [ Spring Boot :8080 ]  --JPA-->  [ H2 / Postgres ]
            |                                              |
            +-------------- STOMP WebSocket  --------------+   (live queue board)
```

- **Frontend:** Flutter 3.41 / Dart 3.11, Riverpod 3.x (codegen `@riverpod`), go_router, Material 3 (`ColorScheme.fromSeed`), `dio` REST client with a JWT auth interceptor, `stomp_dart_client` for realtime.
- **Backend:** Spring Boot 3.x (latest stable), Java 21 LTS, Maven (with wrapper). Spring Web, Spring Security (JWT), Spring Data JPA, Validation, Spring WebSocket, springdoc-openapi (Swagger), Lombok.
- **Database:** **H2 file-mode** for the demo (zero install, persists to disk, has a web console). Optional `postgres` profile for a Docker Postgres or a free Supabase Postgres connection string — but **default to H2 so it just runs.**
- **No Firebase** in the default path. FCM is the only optional Firebase piece, kept solely for production background push; the demo uses WebSocket + `flutter_local_notifications`.

**Palette/type (from blueprint, unchanged):** Trust Teal `#0BA5A4`, Naira Green `#10B981`, Amber `#F59E0B`, Red `#DC2626`, off-white `#F8FAFB`; Plus Jakarta Sans (display) + Inter (body) via `google_fonts`, `.ttf` bundled for offline; tabular figures everywhere.

### ⭐ The realtime centerpiece — live queue across devices (real, not mocked)

This is the one part that is **genuinely realtime, free, and demo-proof**, and it must never be faked. It runs on **Spring Boot WebSocket/STOMP** on the laptop — no third-party service, ₦0. The "wow" isn't the feature, it's **showing it on two screens at once**: a patient action on one device updates the staff board on another *instantly, with no refresh*, live in front of the class. Build it robust enough to survive a live audience:

- **Two-device demo (design for this explicitly):** the **staff queue board runs on the projector** (emulator #1 or the laptop) and the **patient app on a second device** (emulator #2, or my phone on the same WiFi pointing at the laptop's LAN IP). Best moment: hand a willing student the patient check-in (or show a QR that deep-links to it) and let the whole class watch the board move as they join.
- **Live "you're next":** staff taps *Call next* → the patient device **immediately** vibrates + shows "You're next — abeg come" via a per-user topic `/topic/users/{id}`. Doing this live across two devices is the memory people leave with.
- **Live clinic counter / dashboard:** the "currently waiting" number and the throughput chart tick **up in realtime as people join**, very legible on a projector — drive them off the same broadcasts.
- **Robustness so it never looks dead:** STOMP **auto-reconnect** with backoff + heartbeats; the server broadcasts a **full queue snapshot** (idempotent) so a reconnecting client recovers instantly; **optimistic** local update on the patient's own check-in, reconciled by the broadcast; a visible green **"Live"** indicator on the board; and a silent **REST-polling fallback** (~every 3s) that takes over if the socket drops — still real server data, never a mock.

Everything else may have demo fallbacks. **This stays real.**

---

## 3. Backend spec (Spring Boot) — must "run smoothly"

Generate it at **start.spring.io** (IntelliJ Community has no Initializr wizard), import the Maven project into `ClinicNow2/backend/`, run via the main class ▶ or `./mvnw spring-boot:run`.

**"Runs smoothly" definition of done:**
- Starts with **one command**, no manual DB install, no cloud dependency, works fully offline on the demo laptop.
- **Seed data on startup** (`CommandLineRunner`): one demo clinic, demo accounts (admin@demo / staff@demo / patient@demo, password `Password123`), and ~8 sample queue entries so the board is alive instantly.
- **Swagger UI** at `/swagger-ui.html` and **H2 console** at `/h2-console` (both great demo props).
- **CORS** open in dev. **Global `@RestControllerAdvice`** returns clean JSON errors. Sensible startup logging. Health endpoint at `/api/health`.
- Reachable from the Android emulator at `http://10.0.2.2:8080`; from a physical phone on the same WiFi via the laptop's LAN IP (document both in `backend/README.md`).

**Layering:** `controller → service → repository`. Expose **DTOs**, never JPA entities. Constructor injection only. Bean Validation on request DTOs. `application.yml` profiles: `dev` (H2) default, `prod` (Postgres) optional.

**Auth:** `POST /api/auth/register`, `POST /api/auth/login` → returns a **JWT** (HS256, `jjwt`) carrying `sub`, `role`, exp. `BCrypt` password hashing. A `JwtAuthFilter` populates the SecurityContext; gate endpoints with `@PreAuthorize("hasRole('STAFF')")` etc. Roles: `PATIENT`, `STAFF`, `ADMIN`.

**Core entities/endpoints:**
- `User` (id, email, passwordHash, fullName, phone, role, photoUrl, hmoName, hmoEnrolleeId).
- `Clinic` (id, name, address, currentWaiting).
- `QueueEntry` (id, clinicId, patientId, **patientName denormalized**, reason, ticketNumber, position, status `WAITING|CALLED|SEEN|NO_SHOW`, checkInAt, calledAt, assignedStaffId, estimatedWaitMins). REST CRUD + on every change **broadcast over STOMP** to `/topic/clinics/{id}/queue`. `GET /api/clinics/{id}/queue/ahead?entryId=` returns the count ahead (the "people ahead of me" number).
- `Appointment` (id, patientId, clinicId, type `GENERAL|ANTENATAL|IMMUNISATION`, scheduledAt, status).
- `Teleconsult` (id, patientId, staffId, agoraChannel, feeNaira, paid, scheduledAt).
- `Payment` (id, teleconsultId, reference, amountKobo, status, verifiedAt).
- `Reminder` (id, patientId, kind `IMMUNISATION|ANTENATAL|MEDICINE`, dueDate, given) — generated from DOB (NPHCDA schedule) or LMP (WHO 8-contact ANC), per blueprint.

**Realtime:** Spring WebSocket + STOMP, endpoint `/ws` with SockJS fallback. Clients subscribe to `/topic/clinics/{id}/queue`; the service publishes the updated queue snapshot whenever an entry is created/called/reordered/removed. Also publish per-patient events to `/topic/users/{id}` for "you're next" and "doctor is calling."

**Payments (the standout):** `POST /api/payments/verify` takes a Paystack `reference`, calls Paystack's `GET /transaction/verify/{reference}` with the **secret key server-side**, confirms `status=success` and the amount matches (in kobo), then marks the teleconsult `paid=true`. Also implement `POST /api/payments/webhook` validating the **HMAC-SHA512** `x-paystack-signature`. This is real server-side verification — demo it proudly.

**AI proxy:** `POST /api/assistant/chat` (body: message + short history + locale) calls **Gemini** (`gemini-2.0-flash`, free tier) with the Nurse Ada system prompt (§4), returns the reply. Key stays in backend env (`GEMINI_API_KEY`). Never logs message bodies.

**Email:** you said **EmailJS** — keep it if you like (client-side, `http` POST, enable "Allow EmailJS API for non-browser applications"). But since you now have a backend, the cleaner option is **Spring Mail (`JavaMailSender`) + a free Gmail app password** so secrets stay server-side. Implement one `EmailService.send(...)` either way; an email failure must never block the core flow (queue/appointment still succeeds). **Confirm with me which one before building it.**

**File uploads** (patient photo, HMO card, immunisation card): a multipart endpoint storing to the backend's local `uploads/` dir, served back by URL. Free, simple, offline.

**Backend tests:** JUnit 5 + MockMvc for controllers, `@DataJpaTest` for repositories, a couple of service unit tests on queue position logic.

---

## 4. The AI bot — "Nurse Ada" (free, safe, never dies on stage)

Symptom triage + app help + appointment guidance, English and Pidgin, **routed through `POST /api/assistant/chat`**.

- **Engine:** Gemini `gemini-2.0-flash` (free tier, no card) called from the backend. I'll create the key at aistudio.google.com.
- **Mandatory client-side fallback:** if the backend is unreachable OR offline OR returns an error, the Flutter app falls back to a **deterministic rule-based triage engine** (the 7 yes/no danger-sign questions from BLUEPRINT.md → 🔴 Emergency / 🟡 Urgent today / 🟢 Routine). Show an "offline mode" chip. The bot answers something useful 100% of the time.
- **System prompt** (`backend` resource `ada_system_prompt.txt`): Ada is a friendly Nigerian clinic assistant; plain language; switches to Pidgin when the user does; keeps clinical nouns in English (malaria, BP, antenatal, ambulance); softens with "abeg/small"; avoids religious idioms; **never diagnoses or prescribes**; ends serious-symptom replies with "This na guide. If you no sure, go hospital"; surfaces the 🚑 Call 112 / Lagos 767 button on red flags.
- **UX:** WhatsApp-style bubbles, typing indicator, quick-reply chips for triage questions, 🔊 read-aloud on Ada's messages, a floating Ada button on the patient home. Hard-block dosage/prescription requests with a referral message.

---

## 5. Animations — meaningful, on-theme, not decorative

I asked for "GSAP-quality" motion. **GSAP is JavaScript and does not exist in Flutter.** Hit the same caliber with **Rive** (vector state machines — best for the syringe), **`CustomPainter` + `AnimationController`** (procedural spirals/orbits/heartbeat), **Lottie** (success), **flutter_animate** (UI choreography). Respect `MediaQuery.disableAnimations`. Keep 60fps on a low-end emulator; simplify before you ship jank.

Build each so it *relates to what's happening*:
1. **Spinning syringe loader** — syringe rotating slowly, plunger easing down, while vaccine/immunisation data loads (Rive; fall back to a `CustomPainter` syringe + rotation tween).
2. **Heartbeat / ECG line** — animated ECG trace pulsing while vitals submit or a teleconsult connects.
3. **Orbital queue loader** — dots orbiting a center (spiral/orbit) on the "people ahead of me" screen.
4. **Queue token reveal** — ticket number springs/scales in when a token is issued.
5. **Success checkmark draw-on** — stroke-animated tick for payment success / appointment confirmed.
6. **Page transitions** — shared-axis / fade-through via go_router page builders.
7. **Emergency button pulse** — slow red breathing glow so it always reads as urgent.

---

## 6. Free-tier reality

- **Backend cost: ₦0.** It runs on your laptop. H2 needs no install. No cloud, no card. If you ever want it online, Render/Koyeb have free tiers but most now want a card and have cold starts — **don't go near deployment before Thursday; local is correct and reliable.**
- **Database fallback:** if you'd rather a cloud DB, Spring Boot can use a **free Supabase Postgres** connection string (no card; ~500 MB; note Supabase free projects pause after 7 days of inactivity, so wake it the morning of the demo). H2 remains the smoother default.
- **Do not reintroduce Firebase/Firestore** unless I explicitly ask. The only allowed optional Firebase piece is **FCM** for production background push, and only after the core demo works.

---

## 7. Folder structure (monorepo)

```
ClinicNow2/
  lib/                      # Flutter app (already exists at root)
  android/ ios/ pubspec.yaml ...
  l10n/                     # app_en.arb, app_pcm.arb
  backend/                  # Spring Boot (Maven)
    pom.xml  mvnw  mvnw.cmd
    src/main/java/.../clinicnow/{config,security,auth,user,clinic,queue,appointment,teleconsult,payment,reminder,assistant,common}
    src/main/resources/{application.yml, application.yml.example, ada_system_prompt.txt}
    src/test/java/...
    README.md               # how to run + demo accounts
  docs/
    BLUEPRINT.md  SETUP.md  DEMO_SCRIPT.md
    production/paystack_webhook_notes.md
  run_dev.sh  run_dev.ps1  .env.example
```
Flutter feature folders mirror the blueprint (`features/{auth,queue,teleconsult,appointments,payments,triage,assistant,admin,profile}/{data,domain,presentation}`); collapse the triad in features with <6 files.

**IntelliJ Community notes:** install Flutter + Dart plugins (Settings → Plugins). Open `ClinicNow2` as the project; it holds both the Flutter app and the `backend/` Maven module. Community has no Spring wizard/tooling — scaffold the backend at start.spring.io, import `backend/pom.xml` as a Maven project, and run it from the main class' green ▶ or `./mvnw spring-boot:run`. You can run the backend and the Flutter app at the same time (two run configs).

---

## 8. Build order (today is Sun 28 Jun; demo is Thu 2 Jul) — vertical slices

Keep both tiers runnable after every phase.

**Phase 0 — Scaffold both.** Backend: Spring Boot project, H2, `/api/health`, Swagger, H2 console, CORS, global error handler, seed data, demo accounts. Flutter: pubspec wired, theme/fonts/palette, go_router skeleton, `dio` client with base URL `--dart-define=API_BASE_URL=http://10.0.2.2:8080`, app launches to a themed home that pings `/api/health`. Commit.

**Phase 1 — Design system + onboarding + auth API.** Frontend: reusable widgets (`QueueCard`, `EmptyState`, `ErrorState`, `SuccessOverlay`, `ConsentToggleTile`, `ReadAloudButton`, `PrimaryButton`), 3–4 onboarding screens (not gated, persistent skip, Pidgin/English toggle), `_PcmMaterialLocalizationsDelegate` + arb files (strings in blueprint), `LocaleNotifier`. Backend: `User`/`Clinic` entities, `register`/`login` → JWT, BCrypt, JwtAuthFilter, role enum.

**Phase 2 — Auth slice end-to-end.** Flutter login/register hitting `/api/auth`, JWT in `flutter_secure_storage`, dio interceptor attaches it, go_router redirect routes PATIENT/STAFF/ADMIN to different homes. Backend `@PreAuthorize` gates. Layered NDPA consent at first run (granular, never pre-checked).

**Phase 3 — Queue (the realtime heart — build to the ⭐ centerpiece in §2).** Backend: QueueEntry CRUD + STOMP broadcast of a **full queue snapshot** on every change + `ahead` count + per-user `/topic/users/{id}` events for "you're next." Flutter: STOMP client with **auto-reconnect + heartbeats + REST-polling fallback**; patient check-in → optimistic token with reveal animation → patient view with orbital loader + "people ahead"; staff board subscribes live with a green **Live** indicator, `ReorderableListView` to drag-prioritise (PATCH position → rebroadcast), `Dismissible` for seen/no-show/escalate; a live "currently waiting" counter. **Test it across two emulators/devices** — a check-in on one must move the board on the other with no refresh. This is the moment that wins the room; make it flawless.

**Phase 4 — Teleconsult.** Agora App-ID-only (Testing mode), join/leave, local+remote video, mute/camera/end (call both `leaveChannel()` and `release()`), the six Android fixes + ProGuard `-keep` rules from the blueprint, and the **graceful fallback** (`CallState.fallback`: bundled MP4 + fake toggles + "Demo mode" banner) when App ID missing / permission denied / offline. Backend stores teleconsult records + channel name.

**Phase 5 — Payments.** `paystack_for_flutter` test mode, **kobo arithmetic** (`naira*100`), test cards from blueprint. On client success → call backend `POST /api/payments/verify` (real server-side verify) → on confirmed, unlock the join button + checkmark animation + email receipt.

**Phase 6 — Nurse Ada.** Backend `/api/assistant/chat` → Gemini; client chat UI + rule-based offline fallback (§4).

**Phase 7 — Triage + reminders.** 7-question traffic-light triage (syringe/heartbeat loaders), persistent 🚑 button + disclaimer. Backend generates immunisation reminders from DOB (NPHCDA 2026) and antenatal from LMP (WHO 8-contact); client schedules 3-day/1-day/day-of local notifications + "mark given" with optional card photo upload.

**Phase 8 — Notifications + receipts.** STOMP `/topic/users/{id}` → local notifications for "you're next" / "doctor is calling." In-app SMS-style receipt cards for every token/appointment/prescription.

**Phase 9 — Animation & polish pass.** Finalise §5; transitions; skeleton/empty/error/success on every screen; admin/staff dashboard `fl_chart` (hourly throughput, symptom mix, trends) fed by backend aggregate endpoints.

**Phase 10 — NDPA compliance.** Consent management, in-app "Export my data" (JSON+PDF via backend), "Delete account" (30-day soft delete), Pidgin privacy policy screen.

**Phase 11 — Harden + ship.** Gradle survival block from blueprint (multidex, Kotlin 2.1.x, ndk pin, META-INF excludes, desugaring, `-keep` rules for Agora). `very_good_analysis` to zero. Backend tests green. Seed/demo accounts polished, run scripts written, split-ABI release APK <30MB built. Write `docs/DEMO_SCRIPT.md` (the exact 5-minute walkthrough).

**Must-ship spine if time runs short:** backend (auth + queue + WebSocket) + Flutter (themed, onboarding/Pidgin, auth, live queue, teleconsult-with-fallback, Ada). Drop polish before spine.

---

## 9. Code-quality bar

**Flutter:** sealed state classes + exhaustive switches · `AsyncValue.when` for every async UI · `if (!context.mounted) return;` after every `await` · dispose every controller/subscription · null-safe parsing of API responses · Riverpod `StreamProvider` auto-pause · lint set `very_good_analysis 9` + `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `unawaited_futures`, `use_build_context_synchronously`, `avoid_dynamic_calls`, `only_throw_errors`.

**Spring Boot:** strict `controller → service → repository` layering · DTOs only at the boundary, never expose entities · constructor injection · Bean Validation on inputs · `@RestControllerAdvice` global error handling · BCrypt + JWT + `@PreAuthorize` role gates · profiles for H2/Postgres · no secrets in source · JUnit 5 / MockMvc / `@DataJpaTest` coverage on auth and queue logic.

---

## 10. What I (the human) provide when asked

Java 21 + IntelliJ Community with Flutter/Dart plugins (installed) · `GEMINI_API_KEY` (backend env) · Agora App ID (Testing mode) · Paystack `pk_test`/`sk_test` · EmailJS keys **or** a Gmail app password (tell you which) · the Android emulator running, **plus a second emulator or my phone on the same WiFi** so the live two-device queue demo can be shown. If you need any one of these to proceed, **stop and ask me for just that**, then continue.

Start with **Phase 0** now. Confirm you've read `docs/BLUEPRINT.md` (frontend/domain only) and this file, list the 3 things you need from me before Phase 2, then scaffold the Spring Boot backend (running with seed data + Swagger) and the Flutter app (launching and pinging `/api/health`).
