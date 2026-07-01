> **Note for ClinicNow:** This is the **frontend + domain reference**. Its **backend sections are superseded by `CLAUDE.md`** — ignore everything here about Firebase, Firestore, the 50K-reads/day budget, Cloud Functions, custom claims, and FCM-as-primary. The project uses a **Spring Boot + JWT + SQL + WebSocket** backend instead. Everything else below — Flutter packages, palette, typography, Pidgin strings, Nigerian healthcare context, UX conventions, triage flow, immunisation/antenatal schedules, device constraints — still fully applies.

---

# ClinicNow build blueprint for peri-urban Nigeria

**Build ClinicNow on Flutter 3.41 + Riverpod 3.x + Firebase BoM 34, with `agora_rtc_engine 6.5.3`, `paystack_for_flutter 1.0.4`, and a Pidgin (`pcm`) locale layered over Material 3 in a teal-and-naira-green palette.** That stack hits the 2025-2026 sweet spot: every package is currently maintained, the free tiers are real (10,000 Agora minutes/month and 50,000 Firestore reads/day), and the architecture survives the connectivity reality of Ikorodu, Sango-Ota, Choba, and Rumuokoro — where 4G is only **50.85% of subscriptions**, **2G still accounts for 38.6%**, and the median peri-urban handset is a 2–4 GB Tecno or Infinix on Android 11–14. The biggest design decisions you should not deviate from: keep `minSdk = 21` and `targetSdk = 36`, store user roles in **Firebase Auth custom claims** (not Firestore), denormalize patient names onto queue entries to halve your Firestore reads, register an explicit `_PcmMaterialLocalizationsDelegate` because Flutter's bundled localizations don't ship `pcm`, and route all real money through a **Cloud Function webhook with HMAC-SHA512 verification** rather than trusting client-side Paystack callbacks. Everything below is concrete enough to drop into the codebase verbatim.

## Stack and version baseline (verified April 2026)

The Flutter stable channel is **3.41.x** (Dart **3.11**), and that pairs with `firebase_core 4.6.0`, `cloud_firestore 6.2.0`, `firebase_auth 6.3.0`, `firebase_messaging 16.1.0`, and `firebase_storage 13.3.0` — all sourced from pub.dev metadata and `firebase/flutterfire/VERSIONS.md`. Two breaking floors to plan for from earlier upgrades: **iOS deployment target ≥ 13** and **`firebase_auth` requires `minSdk 23`** (the rest of Firebase tolerates 21). For Android tooling, the current stable Android Studio is **Panda 4 (2025.3.4)** shipping AGP 9.1.1; pin your project to **AGP 8.7.x or 9.1.x, Gradle wrapper 8.10+, Kotlin 2.1.x, JDK 17**. AGP 9 plus Flutter plugin compatibility is solid but not all transitive plugins have caught up; if a build breaks, downgrade AGP to 8.7.3 first.

For the Nigerian Play Store target: Google Play mandates `targetSdk ≥ 35` for new uploads as of August 31, 2025, and the **API 36 (Android 16) requirement is being telegraphed for 2026**. Set `targetSdk = 36`, `compileSdk = 36`, `minSdk = 21` (or 23 if you keep `firebase_auth`). StatCounter's March 2026 Nigeria snapshot shows Android 13 (16.75%), 12 (16.03%), 11 (13.68%), 14 (12.21%), 15 (11.02%), and 10 (9.62%) — together with the long tail, **Android 8/9/10/11 still represents ~35–40% of Nigerian Android traffic**, so do not casually push `minSdk` upward.

The full minimal `pubspec.yaml` for ClinicNow:

```yaml
environment:
  sdk: ">=3.11.0 <4.0.0"
  flutter: ">=3.41.0"
dependencies:
  flutter: { sdk: flutter }
  flutter_localizations: { sdk: flutter }
  # Firebase
  firebase_core: ^4.6.0
  cloud_firestore: ^6.2.0
  firebase_auth: ^6.3.0
  firebase_messaging: ^16.1.0
  firebase_storage: ^13.3.0
  cloud_functions: ^6.0.0
  # State + routing
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0
  go_router: ^14.2.0
  # Realtime media + payments
  agora_rtc_engine: ^6.5.3
  paystack_for_flutter: ^1.0.4
  # UI
  google_fonts: ^6.2.1
  lucide_icons_flutter: ^3.0.0
  flutter_animate: ^4.5.0
  lottie: ^3.1.2
  skeletonizer: ^1.4.2
  fl_chart: ^1.1.1
  cached_network_image: ^3.3.1
  flutter_form_builder: ^9.4.0
  form_builder_validators: ^11.0.0
  awesome_snackbar_content: ^0.1.5
  another_flushbar: ^1.12.30
  flutter_tts: ^4.0.2
  # Plumbing
  permission_handler: ^11.3.1
  shared_preferences: ^2.3.0
  connectivity_plus: ^6.0.0
  intl: ^0.20.2
dev_dependencies:
  flutter_test: { sdk: flutter }
  integration_test: { sdk: flutter }
  mocktail: ^1.0.4
  fake_cloud_firestore: ^3.0.0
  firebase_auth_mocks: ^0.14.0
  very_good_analysis: ^9.0.0
  flutter_native_splash: ^2.4.0
  flutter_launcher_icons: ^0.13.1
  riverpod_generator: ^3.0.0
  build_runner: ^2.4.0
```

## Firebase architecture, real-time queue, and the 50K/day budget

Use the **FlutterFire CLI** (`dart pub global activate flutterfire_cli`, then `flutterfire configure`). It generates `lib/firebase_options.dart`, drops `google-services.json` into `android/app/`, and patches `settings.gradle.kts` and `app/build.gradle.kts` with the `com.google.gms.google-services` plugin (≥ 4.4.3). On Flutter 3.41's Kotlin DSL projects, the CLI sometimes throws `PathNotFoundException` looking for Groovy `build.gradle` — the documented workaround is to create dummy Groovy files, run configure, then merge the generated lines into your `.kts` files (FlutterFire issue #16886).

**State management: pick Riverpod 3.x.** Riverpod 3.0 went stable late 2025 and added a feature that materially matters for ClinicNow's Firestore bill: `StreamProvider` now **auto-pauses its `StreamSubscription` when no widget is listening**. That alone slashes reads when staff tablets sit on the queue board overnight or patients background the app. Bloc remains a defensible enterprise alternative if your team standard demands it, but for a solo school project Riverpod's `AsyncValue.when` plus codegen `@riverpod` providers will produce more polished UI states with less code.

**Role-based auth must use custom claims, not Firestore role docs.** Claims live in the Firebase ID token, so Firestore security rules read `request.auth.token.role` for free — no extra read, no client tampering. Clients cannot write claims, so use a Cloud Function `setUserRole` callable that checks the caller is admin, calls `auth().setCustomUserClaims(uid, {role})`, and force-refreshes the client token via `await currentUser.getIdToken(true)`. Wire GoRouter's redirect to `idTokenChanges()` so the router reacts to claim changes, and gate `/staff/**` and `/admin/**` paths inside the redirect callback.

For the **50,000 reads/day Spark cap**, six rules keep ClinicNow well within budget: always `.limit()` snapshots (50 for staff queue boards, 20 for patient views), keep query shape stable inside a screen, default to `snapshots(includeMetadataChanges: false)`, paginate with `startAfterDocument`, run one-shot `count()` aggregations for "people ahead of me" instead of subscribing to all rows, and call `FirebaseFirestore.instance.persistentCacheIndexManager?.enableIndexAutoCreation()` so cached queries don't full-scan after long offline sessions. Patient apps should listen only to their own queue entry doc, not the whole queue.

**Data model.** Put `clinics`, `users`, `appointments`, `teleconsults`, `payments` at the top level; nest `clinics/{cid}/queue_entries/{qid}` and `clinics/{cid}/staff/{uid}` as subcollections. **Denormalize patientName and patientPhotoUrl onto every queue_entry** — this lets the staff queue render with a single 50-row listener instead of 50 extra user-doc fetches. Mirror the role onto the user doc for UI, even though the source of truth is the claim. Keep a `currentWaiting` integer on the clinic doc, updated by a Firestore-triggered Cloud Function, so patient screens render "12 waiting" with one cheap doc subscription. A representative queue_entry:

```jsonc
{
  "qid":"qe_0091","patientUid":"abc123",
  "patientName":"Adaeze Okafor","patientPhotoUrl":"https://...",
  "reason":"Follow-up: hypertension","ticketNumber":"A-091",
  "position":7,"status":"waiting",
  "checkInAt":"2026-04-26T08:32:11Z","calledAt":null,
  "assignedStaffUid":null,"estimatedWaitMins":22
}
```

**Offline persistence is on by default on mobile** in `cloud_firestore 6.x`, but explicitly set `Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)` for the 2G/3G case so today's queue and appointments survive across app kills. Firestore rejects offline-queued writes only when they reach the server, so always validate client-side before write and surface a snackbar from `set().catchError`. Offer a "data saver" toggle that calls `disableNetwork()` to read from cache only — peri-urban users on ₦1,500/2 GB MTN bundles will appreciate it.

**FCM in 2026 needs both notification and data payloads.** Notification messages auto-display when backgrounded but are suppressed in foreground; data messages let you build rich routing (`{type:'queue_next', clinicId, queueId}`) but require `flutter_local_notifications` to actually render. Send both. Add `POST_NOTIFICATIONS` to the manifest, request the permission via `FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()` (FCM's own `requestPermission()` doesn't trigger the Android 13 dialog), and create separate `clinicnow_queue` and `clinicnow_tele` channels. Persist FCM tokens per user in `users/{uid}.fcmTokens` and **delete them on logout** so a returned phone doesn't receive the next user's "you're next."

## Folder structure and routing skeleton

Use **feature-first, layered**, which Very Good Ventures, Invertase, and Andrea Bizzotto all default to. Concretely:

```
lib/
  main.dart
  app/                    # MaterialApp.router, GoRouter, theme
  core/                   # env, errors, network, firebase refs, utils
  shared/                 # widgets, services (FCM, analytics, secure storage)
  features/
    auth/{data,domain,presentation}
    queue/{data,domain,presentation/{patient,staff,widgets}}
    teleconsult/
    appointments/
    payments/
    triage/
    admin/
    profile/
  l10n/                   # app_en.arb, app_pcm.arb
```

Collapse the data/domain/presentation triad inside any feature with fewer than ~6 files — the discipline is for scale, not ceremony.

## Agora teleconsult on the free tier with graceful fallback

Agora's free tier is **10,000 Standard minutes per month** as of April 2026 (verified on docs.agora.io/pricing), shared across Voice, Video, and Live Streaming products. HD video bills at roughly 4× the standard rate, so 10K Std minutes ≈ 2,500 minutes of HD video — enormous headroom for a school demo. Sign up at console.agora.io with an email or Google account; **no payment method is required** for the free tier. Create a project in **Testing mode (App ID only)** for the simplest demo path, or generate a **24-hour Temp Token** from the Console for a more production-looking posture without standing up a token server.

Use **`agora_rtc_engine 6.5.3`** (built on Agora Native SDK 4.6.x). Initialize once with `createAgoraRtcEngine()` → `engine.initialize(RtcEngineContext(appId:...))` → `enableVideo()` → `joinChannel(token: '', channelId, uid: 0, options:...)` for App-ID-only mode. Register `RtcEngineEventHandler` callbacks for `onJoinChannelSuccess`, `onUserJoined`, `onUserOffline`, and `onError`. Render local video with `AgoraVideoView(controller: VideoViewController(rtcEngine, canvas: VideoCanvas(uid:0)))` and remote with `VideoViewController.remote(...)` once a remote uid is set in `onUserJoined`. End-call must call **both** `leaveChannel()` and `release()` to free native handles.

Six bugs you will hit on Android: **black remote video** (rebuild the remote view inside `setState` after `onUserJoined`); **audio in earpiece instead of speaker** (call `setDefaultAudioRouteToSpeakerphone(true)` before joining); **`ERR_NO_PERMISSION (9)`** (request CAMERA + RECORD_AUDIO via `permission_handler` before `joinChannel`); **hot reload corrupts engine state** (use hot restart while developing video screens); **channel name collisions** (channels are global within a project — generate a per-session UUID); and **Agora's R8 rules silently strip Firestore in release builds** (Agora-Flutter-SDK issue #359 — add `-keep class com.google.firebase.**`, `-keep class io.grpc.**`, and `-keep class io.agora.**` to `proguard-rules.pro`). Also add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" tools:node="remove"/>` because Agora 6.2.6+ injects this unconditionally and Play Store policy review will flag it.

For the **graceful fallback the brief explicitly requested**, wrap `_startCall()` in try/catch and detect three failure classes — empty App ID, denied permissions, and no connectivity — then transition to a `CallState.fallback` UI that plays a pre-recorded MP4 of a "doctor" with fake mic/camera toggles and a banner reading "Demo mode — live video unavailable." This guarantees the screen is never dead during your defense.

## Paystack in test mode with kobo arithmetic

The most-maintained Paystack Flutter package as of April 2026 is **`paystack_for_flutter ^1.0.4`** (~3 months since last update, WebView-based, single-call API). The original `flutter_paystack` by wilburx9 has been stagnant since 2022 and its old http dependency causes pubspec resolution conflicts — avoid it. `flutter_paystack_plus` is a strong runner-up if you also need web. Sign up at dashboard.paystack.com with a Nigerian business name; **business verification is only required for live mode payouts, not test mode**. Grab `pk_test_...` and `sk_test_...` from Settings → API Keys & Webhooks.

**Paystack always works in kobo (1 NGN = 100 kobo)**, which is the single most common bug in Flutter Paystack code. ₦500 → 50000, ₦1500 → 150000, ₦2000 → 200000. A teleconsult fee call:

```dart
PaystackFlutter().pay(
  context: context,
  secretKey: const String.fromEnvironment('PAYSTACK_TEST_SK'),
  amount: feeNaira * 100,                       // kobo
  email: patient.email,
  reference: 'TC-${DateTime.now().millisecondsSinceEpoch}',
  currency: Currency.NGN,
  paymentOptions: const [PaymentOption.card, PaymentOption.bankTransfer, PaymentOption.ussd],
  metaData: {'consult_id': consultId},
  onSuccess: (cb) => /* navigate to success, save reference */,
  onCancelled: (cb) => /* show cancel toast */,
);
```

Test cards (verified current on paystack.com/docs/payments/test-payments): successful Visa **4084 0840 8408 4081** with CVV 408, any future expiry; insufficient funds **4084 0800 0000 0409**; Verve with PIN+OTP **5060 6666 6666 6666 666** (PIN 1234, OTP **123456** — universal 3DS test OTP). For the demo, the client-side `onSuccess` callback is acceptable; document this as a known limitation. **For production you must verify server-side** because clients can be tampered with: deploy a Cloud Function at `/paystack/webhook` that computes `crypto.createHmac('sha512', SECRET).update(rawBody).digest('hex')`, compares against the `x-paystack-signature` header, and only then writes `consults/{id}.paid = true` to Firestore. The client listens to that doc and unlocks the teleconsult join button. Pass the test secret via `--dart-define=PAYSTACK_TEST_SK=sk_test_xxx` so it never lives in committed source.

## Pidgin localization without breaking Material widgets

Nigerian Pidgin's ISO 639-3 code is **`pcm`**, recognized by CLDR but **not shipped with Flutter's bundled `GlobalMaterialLocalizations`**. The Flutter docs' Nynorsk delegate pattern is the canonical workaround: declare a `_PcmMaterialLocalizationsDelegate` whose `load()` actually returns the English MaterialLocalizations bundle, and register it before `GlobalMaterialLocalizations.delegate` in `localizationsDelegates`. Do the same for `CupertinoLocalizations`. This avoids the `intl` DateFormat crash because we reuse English symbols, while still letting your own `app_pcm.arb` strings load through the generated `AppLocalizations` class. Set `synthetic-package: false` in `l10n.yaml` because Flutter is removing the synthetic package, and add `pcm` to iOS `CFBundleLocalizations` so the system language picker exposes it.

Persist the user's choice with `shared_preferences` and a small `LocaleNotifier` Riverpod provider; expose it via a `SegmentedButton` in Settings. Override `MaterialApp.locale` from the provider — without this, Android in Nigeria reports `en_NG` and Pidgin would never auto-select.

The Pidgin translations below were curated against BBC News Pidgin (the reference register for ~75M speakers), the British Council Pidgin guide, the Wikivoyage Nigerian Pidgin phrasebook, Naijalingo, and Glosbe. They use the decreolised media-press orthography that peri-urban readers parse fastest on small screens, and they work across Lagos/Ogun (Yoruba-inflected) and Port Harcourt (closer-to-creole) registers:

| Key | English | Pidgin (pcm) |
|---|---|---|
| appWelcome | Welcome to ClinicNow | You welcome to ClinicNow |
| signUp / login / logout | Sign up / Login / Logout | Register / Login / Logout |
| bookAppointment | Book appointment | Book appointment |
| findClinic | Find a clinic near you | Find clinic wey dey near you |
| queueNumber | Your queue number is {n} | Your queue number na {n} |
| youAreNumber | You are number {n} in line | You be number {n} for line |
| doctorWillSee | Doctor will see you in {minutes} minutes | Doctor go see you for {minutes} minutes time |
| pleaseWait | Please wait | Abeg wait small |
| payNow / paymentSuccessful / paymentFailed | Pay now / Payment successful / Payment failed | Pay now / Payment don enter / Payment no work |
| emergency / callAmbulance | Emergency / Call ambulance | Emergency / Call ambulance |
| howFeeling | How are you feeling today? | How your body dey today? |
| describeSymptoms | Describe your symptoms | Tell us wetin dey worry you |
| fever / headache / cough / stomachPain / bodyWeak | Fever / Headache / Cough / Stomach pain / Body weak | Body dey hot / Head dey pain me / Cough / Belle dey pain me / Body dey weak |
| startVideoConsult | Start video consultation | Start video call with doctor |
| doctorIsCalling / endCall | Doctor is calling you / End call | Doctor dey call you / End call |
| appointmentConfirmed / cancelAppointment | Appointment confirmed / Cancel appointment | Your appointment don set / Cancel appointment |
| medicineReminder | Reminder: take your medicine | Remember: take your drugs |
| vaccineReminder | Vaccine reminder for your baby | Time don reach to give your pikin immunisation |
| antenatalTomorrow | Antenatal appointment tomorrow | Antenatal go hold tomorrow |
| patientOrStaff | Are you a patient or clinic staff? | You be patient or you dey work for clinic? |

Three cultural rules apply. **Keep clinical nouns in English** — *malaria, BP, antenatal, immunisation, ambulance, prescription, tablet, injection* — because Pidginizing them is patronizing and clinically risky. **Soften imperatives with "abeg" and "small"** — bare commands feel rude in Pidgin. **Avoid religious idioms** like "by God's grace" and "God dey" — Nigeria is religiously plural, and a clinical app must feel competent and secular so users don't substitute prayer for treatment. Code-switching is fine: leave navigation labels (Settings, Notifications, Profile) in English and Pidginize the explanatory sentences, exactly as Opay, Bolt, and WhatsApp do for the Nigerian market. The single biggest open question is whether single-word labels like "Fever" should stay English or render as "Body dey hot" — A/B test with users; clinic posters in Lagos commonly use both side-by-side.

## Peri-urban Nigerian healthcare context that drives the UX

The target users carry **Tecno Spark, Infinix Smart 9/10, Itel A-series, Samsung A05, or Redmi A4** handsets — Transsion Holdings (Tecno + Infinix + Itel) controls **50.7% of Nigerian handset usage**. Typical specs: 2–4 GB RAM (with marketing "extended RAM"), 32–64 GB storage, 720p IPS LCD, 5,000–6,000 mAh battery (designed around grid instability), Unisoc T606/T615 or MediaTek Helio G36/G81 chipsets. Your APK budget is **under 25–30 MB**; ship split-APKs by ABI (arm64-v8a + armeabi-v7a), cap `cached_network_image` at ~50 MB disk and 20 MB memory, downscale assets to 720 px wide, avoid Lottie files over 100 KB, and minimize blur/shader effects which crawl on these GPUs.

Connectivity numbers from the **NCC's July 2025 industry statistics**: 169.3 million telecom subscriptions, 142.6 million internet subscribers, **4G at 50.85%, 2G at 38.6%, 3G at 7.38%, 5G at 3.17%** — meaning **5G is effectively a non-feature** in your target areas, and the design must assume 3G/2G fallback during rainy-season tower flooding in Port Harcourt and grid-driven night-time shutdowns in Sango-Ota. Post the January 2025 NCC tariff hike, MTN's 2 GB/30-day bundle costs ₦1,500 and 10 GB costs ₦4,500, with PAYG at ₦3.07/MB — every kilobyte counts. Build offline-first with Hive or Drift for local caching, render queue-join optimistically before server ack, gzip every list response, and retry with exponential backoff (1→2→4→8→30s, jittered, max 5 attempts).

Nigeria's **NHIA Act 2022** replaced the older NHIS Act and made health insurance mandatory, but ~90% of Nigerians still pay out of pocket. Major HMOs operating in the target areas include **Hygeia, Avon Healthcare (~2,500 facilities, strong Rivers presence), Reliance Health (now corporate-only as of 2026), AXA Mansard (the cheapest individual plans), Leadway Health, Total Health Trust, Clearline, Hallmark (HQ on Ikorodu Road), Greenbay, IHMS, Princeton, AIICO Multishield, Redcare, Bastion**, plus state schemes (Lagos LSHMA, Ogun OGSHIS, Rivers RIVCHIMA). **Critically: there is no public NHIA-wide eligibility API.** Each major HMO has private B2B integrations (Helium Health negotiates them deal-by-deal). For ClinicNow, store enrollee ID + HMO name + assigned PHCP as user-entered text with an HMO picker, allow a photo capture of the card, and surface this to clinic staff for **manual verification at counter** — never promise real-time eligibility checks.

**Real public-clinic queue mechanics** are what ClinicNow disrupts. At a peri-urban General Hospital GOPD, patients arrive at 06:00–07:00 to register, then queue for records (single clerk, paper folders, ₦200–₦1,000 card fee), vitals, doctor consultation, lab/X-ray, pharmacy, and cashier — **median wait at National Hospital Abuja is 2.7 hours** and **29.4% of Lagos patients wait ≥3 hours before seeing a doctor** (Akinyinka et al.). ClinicNow's value proposition is pre-registration with a QR code, virtual queue tokens with live position estimates so users can sit outside or run errands, vitals self-entry, symptom pre-triage that fast-lanes truly urgent cases, and SMS pickup notifications from pharmacy. SMS receipts persist offline and are trusted more than in-app messages — emit one for every queue token, appointment, and prescription.

For triage, Nigerian primary care uses **WHO IMCI for under-5s** (danger signs: unable to drink, vomits everything, convulsions, lethargic) and adapted **Manchester Triage System** at tertiary EDs (Red/Orange/Yellow/Green/Blue with 0/10/60/120/240-minute targets). A defensible mobile triage flow asks 7 yes/no questions in plain Pidgin and routes to **🔴 Emergency / 🟡 Urgent today / 🟢 Routine**, with a persistent "🚑 Call 112 / Lagos 767" button on every screen and a disclaimer "This na guide. If you no sure, go hospital." The seven questions cover difficulty breathing, chest pain radiating to arm/jaw, unconsciousness or convulsions, uncontrolled bleeding (including pregnancy bleeding), severe child dehydration, high fever with rash or stiff neck, and severe injury or suspected fracture.

**NPHCDA's 2026 routine immunisation schedule** runs BCG/OPV0/HepB0 at birth; Penta+OPV+PCV+Rota at 6/10/14 weeks; **R21/Matrix-M malaria vaccine at 5/6/7 months and a booster at 15 months** (introduced December 2024, phased rollout); Measles–Rubella (MR1, integrated October 2025), Yellow Fever, MenA at 9 months; MR2 at 15 months; HPV at 9 years for girls. **Antenatal care follows the WHO 2016 model** that Nigeria's FMOH adopted — 8 contacts at <12, 20, 26, 30, 34, 36, 38, 40 weeks, with TT vaccine, IPTp-SP for malaria at contacts 2–4, iron/folate, dating and anatomy ultrasounds. ClinicNow should auto-schedule reminders from date of birth (immunisations) or last menstrual period (ANC), push 3-day, 1-day, and day-of alerts, allow caregivers to mark "given" with optional card photo, and flag missed doses for "zero-dose" follow-up.

Five UX conventions consistently work in Nigerian peri-urban mHealth research (Helium Health UX principles, MyBelle Oyo study PMC 11794200, mTrac, mTBA): icon **plus** text labels never icon-only; WhatsApp-familiar metaphors (chat bubbles, voice notes); traffic-light color coding; multi-account quick-switch because phones are shared in households; and SMS receipts as a parallel persistence layer. For low-literacy and older users, add a 🔊 button on every screen using `flutter_tts` (English TTS works; pre-record Pidgin/Yoruba/Igbo because TTS for those is poor), provide a body-map screen for tapping where pain is rather than typing symptoms, support 4-digit numeric PINs instead of passwords, and offer 16/22/28 sp font scales.

## Design system, dashboards, and production polish

Build on **Material 3** (`useMaterial3: true` is the default since Flutter 3.16) with a custom `ColorScheme.fromSeed`. Don't reach for Cupertino or roll your own widget set — both are wasted effort for an Android-first NG demo. The recommended palette: **Trust Teal `#0BA5A4`** as primary (calm medical teal blending blue trust and green health), **Naira Green `#10B981`** as confirmation accent (resonates with the flag), **Amber `#F59E0B`** for queue-waiting states, **Red `#DC2626`** strictly for emergency and errors, and a **warm off-white `#F8FAFB`** background instead of pure white (which reads as sterile and Western-hospital-cold to Nigerian users used to Opay/PalmPay/Kuda warmth). Paystack and Flutterwave both built their identities on blue specifically for "professionalism, stability, trust" — ClinicNow inherits that lineage and adds the green-health overlap. For typography, **pair `Inter` body with `Plus Jakarta Sans` display** via the `google_fonts` package; bundle the .ttf files in `assets/fonts/` so the package prefers local files over HTTP for offline-first behavior. Tabular figures via `FontFeature.tabularFigures()` make queue numbers and vitals line up.

> Typography note for ClinicNow: this project upgrades the pairing to **Bricolage Grotesque (display) + Manrope (body)** — see `CLAUDE.md` §5 and `lib/core/theme/app_theme.dart`.

The clinic dashboard wants tablet-aware responsive layouts: BottomNavigationBar plus single column under 600 dp; collapsed NavigationRail plus master-detail at 600–1024 dp; expanded NavigationRail plus 3-pane (rail / queue list / patient detail with vitals) above 1024 dp. Use `go_router`'s `ShellRoute` to keep the rail persistent. The queue list itself should be a `ReorderableListView` so triage staff can drag-prioritize, with `Dismissible` for swipe-to-mark-seen / no-show / emergency-escalate. Incoming teleconsult requests need a three-channel alert: top banner via `another_flushbar`, distinctive sound via `audioplayers`, and twin 300ms vibration pulses via the `vibration` package. The dashboard analytics row uses `fl_chart` for hourly throughput (LineChart), daily symptom mix (PieChart), and monthly trends (BarChart).

For state-driven UI, lean on Riverpod's `AsyncValue.when` plus `Skeletonizer` for loading, a friendly retry widget for errors, and Lottie illustrations for empty states. Animate list entry with `flutter_animate`'s `.fadeIn().slideY()` chain, staggered by index. Build five reusable widgets once and use them everywhere: `QueueCard`, `EmptyState(lottie, title, cta, onTap)`, `ErrorState(message, onRetry)`, `SuccessOverlay`, and `ConsentToggleTile`. For splash and icons, configure `flutter_native_splash` with the **Android 12+ icon-on-background spec** (1152×1152 image, content within the inner 768 px circle) and `flutter_launcher_icons` with adaptive foreground/background and iOS 18 dark/tinted variants. Onboarding is **3–4 screens, never gated behind login**, with skip persistent at top-right and a Pidgin/English language toggle on the last screen.

**Compliance is NDPA, not HIPAA.** Nigeria's **Data Protection Act 2023** (signed 12 June 2023) plus the **NDPC General Application and Implementation Directive 2025** govern ClinicNow. Health data is **Sensitive Personal Data under NDPA s.30**, requiring explicit, granular consent. Any controller processing health data automatically becomes a **Data Controller of Major Importance**, which means you must register with NDPC, appoint a DPO, file a Compliance Audit Return by March 31 each year, and notify breaches within 72 hours. Build in: layered consent screens at first run (separate toggles for camera, mic, location, health-data sharing — never pre-checked, per GAID Article 19), a Pidgin version of the privacy policy, in-app "Export my data" (JSON+PDF) and "Delete account" (30-day soft-delete), a documented retention policy (consultation notes 7 years per Nigerian medical records guidance, queue history 90 days, teleconsult recordings 30 days unless flagged), and a documented DPIA before launch. Cross-border transfers to Firebase/GCP need adequacy or explicit consent — bake the consent into your sign-up flow.

## Testing, lint discipline, and Gradle survival

For testing in 2026, **`mocktail` has overtaken `mockito`** in pub.dev downloads (~2.58M vs 1.78M weekly mid-2025), is null-safe, and needs no codegen — pick it. Pair with **`fake_cloud_firestore`** and **`firebase_auth_mocks`** for unit/widget tests, the SDK-bundled `integration_test` package for E2E, and **`alchemist`** (Betterment) for golden tests since `golden_toolkit` was archived in 2024. Run integration tests against the **Firebase Emulator Suite** (`firebase init emulators` for Auth + Firestore, then `useAuthEmulator('10.0.2.2', 9099)` and `useFirestoreEmulator('10.0.2.2', 8080)` from `setUpAll`).

For lint hygiene, base `analysis_options.yaml` on **`very_good_analysis 9.0.0`** and explicitly enable `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `unawaited_futures`, `use_build_context_synchronously`, `avoid_dynamic_calls`, and `only_throw_errors`. These catch the seven most common Flutter+Firebase bugs: undisposed `StreamSubscription`s, `BuildContext` use across async gaps (always `if (!context.mounted) return;` after every `await`), `LateInitializationError` from premature `late` reads, `Future.wait` swallowing errors (pass `eagerError: true`), streams subscribed inside `build()`, listener leaks on hot reload, and unclosed `StreamController`s. Adopt Dart 3.x patterns aggressively: **sealed `CallState` classes** with exhaustive switch expressions, records for cheap multi-return, `late final` only when initialization is provably complete before first read, and `(data['name'] as String?) ?? ''` rather than `data['name']!` for Firestore deserialization.

**Gradle conflicts are inevitable** when you combine Firebase + Agora + Paystack and you should fix them preemptively: enable `multiDexEnabled = true`, force Kotlin Gradle Plugin 2.1.x in `settings.gradle.kts` to avoid the `firebase_crashlytics` "incompatible Kotlin metadata 2.1.0" error (FlutterFire #17063), pin `ndkVersion = "27.0.12077973"` to align Agora's prebuilt `.so` files with Firebase's natives, add the META-INF excludes block (`META-INF/LICENSE`, `*.kotlin_module`, etc.) to packaging.resources to kill duplicate-license errors, set `jniLibs.useLegacyPackaging = true` for Agora's iris libs, enable `coreLibraryDesugaring` for `java.time` on minSdk 21, and add the ProGuard `-keep` rules for `com.google.firebase.**`, `io.grpc.**`, and `io.agora.**` — without those the Agora R8 ruleset kills Firestore in release builds permanently. The full AndroidManifest needs INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, WAKE_LOCK, POST_NOTIFICATIONS, CAMERA, RECORD_AUDIO, MODIFY_AUDIO_SETTINGS, READ_PHONE_STATE, BLUETOOTH_CONNECT, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MICROPHONE, and FOREGROUND_SERVICE_CAMERA, with the `tools:node="remove"` directive on FOREGROUND_SERVICE_MEDIA_PROJECTION.

## What "production-quality demo" looks like at submission

The teacher-impressive version of ClinicNow shows nine concrete things working: a Material 3 themed app with the teal/naira-green palette and Plus Jakarta Sans + Inter typography; an onboarding flow with Pidgin language toggle that persists; a custom-claim-driven role router that actually redirects patient/staff/admin to different home screens; a real-time staff queue board reading 50 entries from Firestore with denormalized patient names and reorderable triage priority; a patient queue view with one-shot count aggregation showing "people ahead of me"; a live Agora 1-on-1 video call with mute/camera/end-call and graceful fallback to a simulated demo if the App ID is missing or permissions are denied; a Paystack test payment in kobo for a ₦500–₦2,000 teleconsult fee; FCM push notifications via Cloud Functions for "you're next" and "doctor is calling"; and an NDPA-compliant consent flow with granular toggles plus in-app data export and delete. Every state has a skeleton, an empty illustration, an error retry, and a Lottie success animation. Every screen has a 🔊 read-aloud option and 56 dp tap targets. The codebase passes `very_good_analysis` with zero warnings and ships under a 30 MB APK split.

## Conclusion

The technical risks for ClinicNow are not the popular ones — Riverpod 3.x and Material 3 are stable, Firebase free tier is plenty, Agora's 10K free minutes are confirmed, and Paystack test mode is straightforward. The real risks are **the Agora-Firestore release-mode interaction** (silent failure unless ProGuard rules are correct), **client-trusted Paystack callbacks** (production demands the HMAC webhook), **the missing NHIA eligibility API** (manual verification only), **Pidgin Material delegate registration** (without it, `MaterialApp` throws on `pcm`), and **NDPA's Major Importance threshold** which ClinicNow trips on day one. Address those five upfront and the rest of the build is conventional Flutter work. The deepest insight from this research is that the design constraints driving ClinicNow's UX — offline-first because 38.6% of subscriptions are still 2G, denormalize aggressively because the free Firestore tier is real, prefer SMS receipts because users trust them more than in-app notifications, keep clinical nouns in English because Pidginizing them is patronizing and risky — are the same constraints that made Helium Health, Reliance, and Avon successful. ClinicNow is not building against the Nigerian peri-urban environment; it is building with it.
