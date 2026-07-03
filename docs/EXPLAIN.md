# ClinicNow — how it works (defense notes)

Plain-language walkthrough of the app for the oral defense. Read this once
before you present; it maps every feature to the file(s) that implement it.

## 1. The big idea: demo mode

`lib/core/config/app_config.dart` defines a single flag:

```dart
static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
```

It's **on by default**. Every repository in the app (`AuthRepository`,
`QueueRepository`, `TeleconsultRepository`, `AssistantRepository`) checks
`AppConfig.demoMode` at the top of each method:

```dart
if (AppConfig.demoMode) { /* serve local data, no network */ }
/* ...otherwise call the real Spring Boot backend over Dio ... */
```

This means the **exact same UI code, providers, and screens** run whether or
not a backend is reachable — only the data source underneath swaps. To run
against the real backend instead: `flutter run --dart-define=DEMO_MODE=false
--dart-define=API_BASE_URL=http://<your-lan-ip>:8080`. The Spring Boot code
is untouched and still there — that's the "explain the backend in your
defense" story: you built both, and the client can talk to either.

## 2. Why there are no more "network error" banners

Two places used to make live network calls on every screen load:

- `core/network/health_provider.dart` pinged `/api/health` and showed a red
  "Cannot reach server" banner (`shared/widgets/connection_banner.dart`) on
  failure.
- Every repository hit Dio directly.

In demo mode, `HealthNotifier.check()` now short-circuits to
`BackendStatus.ok` without ever calling Dio — there's nothing to fail. Same
pattern in every repository. That's the whole fix: not "handle errors
better", but "don't make the call in the first place" when there's no
backend to call.

## 3. The live queue, without a server

`lib/core/demo/demo_queue_engine.dart` is a small in-memory state machine
that replaces the STOMP WebSocket connection:

- Seeded with 8 waiting patients (`lib/core/demo/demo_seed.dart` — Adaeze
  Okafor, Chidi Nwosu, Fatima Bello, etc.) at clinic "Ikorodu General
  Outpatient", ticket numbers 91–98.
- A `Timer.periodic(24s)` ticks the queue forward automatically: marks the
  currently-called patient as seen, calls the next waiting patient, and
  fires a "you're next" event — so the board never looks dead even if nobody
  touches it.
- `join()`, `callNext()`, `markDone()`, `markNoShow()` mutate the list
  synchronously and re-broadcast a full snapshot — exactly the same
  `QueueSnapshot` shape the real STOMP broadcasts use, so
  `queue_providers.dart` and every screen that consumes it (patient ticket,
  staff board) don't know or care that there's no socket.
- `QueueRepository.connectStomp()` in demo mode just calls `onConnected()`
  immediately instead of opening a WebSocket — the "Live" pill on the staff
  board still lights up green.

**In your defense**: this is the one thing you should be upfront about —
the realtime *architecture* (STOMP topics, broadcast-on-change, snapshot
reconciliation, REST-polling fallback) is real and implemented in Spring
Boot (`backend/`); today's demo runs the same client logic against a local
simulator instead of a socket, because presenting from a phone with no
laptop means there's no server to connect to.

## 4. Real local accounts, no backend required

`lib/core/demo/local_account_store.dart` is a tiny on-device "user table"
backed by `SharedPreferences`. Passwords are salted with the email and
SHA-256 hashed (`crypto` package) — never stored in plaintext, never sent
anywhere. Three accounts are seeded on first launch:

| Role | Email | Password |
|---|---|---|
| Admin | `manniboh@gmail.com` | `dylan/px4tm` |
| Staff | `staff@clinicnow.demo` | `Password123` |
| Patient | `patient@clinicnow.demo` | `Password123` |

Anyone can also sign up live on stage with a real email/password —
`LocalAccountStore.create()` checks for duplicates and persists the new
account immediately. `AuthRepository` branches on demo mode exactly like the
other repositories: `login()`/`register()`/`verifyOtp()`/`resendOtp()` all
have a local-store path and a real-backend path.

OTP still "feels" real: registering generates a random 6-digit code kept
in-memory (`AuthRepository._pendingOtps`), and `EmailJsService` still tries
to email it via EmailJS (client-side REST call, works over mobile data, no
laptop needed) — but if that fails or isn't configured, the OTP page has a
"Show demo code" reveal so the flow **never blocks** on stage.

## 5. Roles and dashboards

`UserModel.role` (`PATIENT` / `STAFF` / `ADMIN`) drives routing in
`lib/app/router.dart` — `_AuthRouterNotifier._homeFor()` sends each role to
its own home: `/home/patient`, `/home/staff`, `/home/admin`. Each is a
separate widget (`lib/features/home/*.dart`) with a role-appropriate feature
set: patients get the queue/booking/Ada/triage grid, staff get the live
board + video consult, admin gets stats + quick actions (Staff/Reports/
Clinics currently show a "coming soon" sheet — honest placeholders, not dead
buttons — since they need the real backend's aggregate endpoints).

## 6. Nurse Ada, fully offline

`lib/core/demo/offline_ada_engine.dart` is a deterministic, rule-based
responder: keyword matching for red/yellow/green danger signs (the same 7
questions used by the standalone Triage screen), antenatal/queue help text,
and Pidgin detection (switches reply language if your message contains
Pidgin markers like "abeg"/"wetin"/"dey"). `AssistantRepository.chat()`
calls this directly in demo mode — no network attempted at all, ~500ms
simulated latency so the typing indicator still shows. The same engine
backs `TriageResult scoreTriage()` for the dedicated 7-question Triage
screen (`lib/features/triage/presentation/triage_page.dart`).

## 7. Teleconsult and Payment

- **Teleconsult**: Agora isn't linked into this build (see the pubspec
  comment — NDK path issues), so the call screen has always used a
  polished simulated call UI (`_FallbackCallView` in `teleconsult_page.dart`:
  pulsing doctor avatar, animated waveform, working mute/camera toggles,
  timer). In demo mode, `TeleconsultRepository.createSession()` returns a
  fake session instantly instead of attempting a POST first.
- **Payment**: `lib/features/payment/presentation/payment_page.dart` is a
  self-contained 3-stage screen (choose method → processing shimmer →
  animated checkmark + receipt card) with a `PopScope` that blocks the
  Android back button mid-payment. It doesn't touch Paystack in demo mode;
  the real server-side verification flow (`POST /api/payments/verify`) is
  still implemented in the backend for when a real backend is connected.

## 8. New screens this pass added

Four screens existed only as mockups in `docs/clinicnow_design_board.html`
and are now real, wired-up Flutter screens:

- `features/triage/presentation/triage_page.dart` — 7-question flow, animated
  progress bar, red/yellow/green result with "join queue" CTA.
- `features/appointments/presentation/appointments_page.dart` +
  `appointments_providers.dart` — tabbed Appointments/Reminders, seeded from
  `DemoSeed.appointments`/`.reminders` (NPHCDA immunisation + WHO 8-contact
  ANC schedule), book-appointment bottom sheet, mark-given action.
- `features/payment/presentation/payment_page.dart` — see above.
- `features/profile/presentation/profile_page.dart` — avatar, language
  switch, the `ThemeToggle` (also now in every home app bar), read-aloud
  toggle, export-data placeholder, and a real "Delete account" flow that
  removes the local account and clears the session.

All four are registered in `lib/app/router.dart` and reachable from the
patient home quick-actions grid (now 6 tiles) and the profile/settings menu
item added to every home app bar.

## 9. Theming, locale, and read-aloud

- `shared/providers/theme_provider.dart` — `ThemeMode` persisted to
  `SharedPreferences`. `ThemeToggle` (`core/widgets/signature_widgets.dart`)
  is a pure presentational sun/moon switch; three places now drive it
  (patient/staff/admin home app bars + the new Profile screen) so it's
  always one tap away, as required.
- `shared/providers/locale_provider.dart` + `core/l10n/` — English/Pidgin,
  switched from onboarding or Settings.
- `flutter_tts`-backed `ReadAloudButton` — `shared/providers/
  read_aloud_provider.dart` adds a persisted on/off preference surfaced in
  Settings.

## 10. Animation & performance choices

- Every looping `CustomPaint` background (splash syringe, login/OTP/
  onboarding/thank-you/home glows) is wrapped in `RepaintBoundary` so its
  repaints don't force a repaint of the whole widget tree above it.
- All `MaskFilter.blur` glow effects were **removed** from those painters.
  Gaussian blur is one of the more expensive things you can ask a low-end
  GPU to do every frame, and this app targets a Samsung A12 for the defense
  — the "glow" look is kept through layered low-alpha solid shapes instead,
  which costs almost nothing.
- Multiple independent animations on one screen share a single
  `AnimationController`/`Listenable.merge` and one `AnimatedBuilder`
  wherever practical (see `splash_page.dart`, `login_page.dart`) instead of
  one controller per effect.
- `flutter_animate` is used for one-shot entrance choreography (fade/slide/
  scale on staggered delays) rather than always-on `AnimatedBuilder` loops,
  so most of the UI is static once it's settled in.

## 11. What's still backend-only (by design)

The Spring Boot code in `backend/` (JWT auth, `QueueEntry`/`Appointment`/
`Teleconsult`/`Payment` entities, STOMP broadcast, Paystack server-side
verification, Gemini proxy) is untouched and fully described in
`CLAUDE.md`/`docs/BLUEPRINT.md`. It's not running today because the defense
is phone-only with no laptop — but every demo-mode code path has a sibling
`else` branch that calls it, so flipping `DEMO_MODE=false` and pointing
`API_BASE_URL` at a running backend brings the real system online with zero
UI changes.
