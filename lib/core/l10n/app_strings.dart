import 'package:flutter/material.dart';

/// All UI strings in English and Nigerian Pidgin (pcm).
/// Source: docs/BLUEPRINT.md — Pidgin localization table.
///
/// Usage: context.strings.login  or  AppStrings('pcm').login
class AppStrings {
  const AppStrings(this.locale);
  final String locale;
  bool get _p => locale == 'pcm';

  // ---- brand ----
  String get appName => 'ClinicNow';
  String get tagline => _p ? 'Healthcare wey dey your hand' : 'Healthcare in the palm of your hand';

  // ---- onboarding ----
  String get skip => 'Skip';
  String get next => 'Next';
  String get getStarted => _p ? 'Make we start' : 'Get started';
  String get chooseLanguage => _p ? 'Choose your language' : 'Choose your language';
  String get ob1Title => _p ? 'You welcome to ClinicNow' : 'Welcome to ClinicNow';
  String get ob1Sub  => tagline;
  String get ob2Title => _p ? 'Join queue from house' : 'Join the queue from anywhere';
  String get ob2Sub  => _p
      ? 'Get your token online, come when dem nearly call you'
      : 'Get your token online and arrive when you\'re nearly called';
  String get ob3Title => _p ? 'Talk to doctor for house' : 'Consult a doctor at home';
  String get ob3Sub  => _p
      ? 'Video call with doctor, no need travel'
      : 'Video consultation — no travel needed';
  String get ob4Title => chooseLanguage;
  String get ob4Sub  => _p
      ? 'Pick the language wey you like'
      : 'Pick the language you prefer';
  String get english => 'English';
  String get pidgin  => 'Pidgin';

  // ---- auth ----
  String get signUp    => _p ? 'Register' : 'Sign up';
  String get login     => 'Login';
  String get logout    => 'Logout';
  String get fullName  => _p ? 'Your full name' : 'Full name';
  String get email     => 'Email';
  String get password  => 'Password';
  String get phone     => _p ? 'Phone number' : 'Phone number';
  String get iAmPatient => _p ? 'I be patient' : 'I am a patient';
  String get iAmStaff  => _p ? 'I dey work for clinic' : 'I work at a clinic';
  String get alreadyHaveAccount => _p ? 'You don get account? Login' : 'Already have an account? Login';
  String get dontHaveAccount    => _p ? 'You never get account? Register' : 'Don\'t have an account? Sign up';
  String get patientOrStaff     => _p ? 'You be patient or you dey work for clinic?' : 'Are you a patient or clinic staff?';

  // ---- queue ----
  String get yourQueueTicket => _p ? 'Your queue ticket' : 'Your queue ticket';
  String get joinQueue       => _p ? 'Join queue' : 'Join queue';
  String get queueBoard      => _p ? 'Queue board' : 'Queue board';
  String peopleAhead(int n)  => _p ? '$n people dey front' : '$n people ahead';
  String etaMins(int n)      => '~$n min';

  // ---- triage ----
  String get howFeeling       => _p ? 'How your body dey today?' : 'How are you feeling today?';
  String get describeSymptoms => _p ? 'Tell us wetin dey worry you' : 'Describe your symptoms';
  String get emergency        => 'Emergency';
  String get callAmbulance    => _p ? 'Call ambulance' : 'Call ambulance';
  String get triageGuide      => _p
      ? 'This na guide. If you no sure, go hospital.'
      : 'This is a guide. If unsure, please visit a hospital.';

  // ---- appointments ----
  String get bookAppointment      => _p ? 'Book appointment' : 'Book appointment';
  String get appointmentConfirmed => _p ? 'Your appointment don set' : 'Appointment confirmed';
  String get cancelAppointment    => _p ? 'Cancel appointment' : 'Cancel appointment';

  // ---- payments ----
  String get payNow            => _p ? 'Pay now' : 'Pay now';
  String get paymentSuccessful => _p ? 'Payment don enter' : 'Payment successful';
  String get paymentFailed     => _p ? 'Payment no work' : 'Payment failed';

  // ---- reminders ----
  String get medicineReminder  => _p ? 'Remember: take your drugs' : 'Reminder: take your medicine';
  String get vaccineReminder   => _p ? 'Time don reach to give your pikin immunisation' : 'Vaccine reminder for your baby';
  String get antenatalTomorrow => _p ? 'Antenatal go hold tomorrow' : 'Antenatal appointment tomorrow';

  // ---- common ----
  String get retry    => _p ? 'Try again' : 'Retry';
  String get save     => 'Save';
  String get cancel   => _p ? 'Cancel' : 'Cancel';
  String get confirm  => _p ? 'Confirm' : 'Confirm';
  String get readAloud => _p ? 'Read am' : 'Read aloud';
  String get noData   => _p ? 'Nothing dey here' : 'Nothing here yet';
  String get errorMsg => _p ? 'Something go wrong' : 'Something went wrong';
  String get loading  => _p ? 'E dey load...' : 'Loading...';

  // ---- NDPA consent ----
  String get consentCamera   => _p ? 'Camera (for video call)' : 'Camera (video consultation)';
  String get consentMic      => _p ? 'Microphone (for video call)' : 'Microphone (video consultation)';
  String get consentLocation => _p ? 'Location (to find clinic near you)' : 'Location (find nearby clinics)';
  String get consentHealth   => _p ? 'Health data (for your treatment)' : 'Health data (for your treatment)';

  // ---- Registration NDPA consents ----
  String get ndpaTerms    => _p ? 'I agree to Terms & Privacy' : 'I agree to the Terms & Privacy Policy';
  String get ndpaTermsSub => _p ? 'Read how we protect your data' : 'Read how ClinicNow handles your information';
  String get ndpaData     => _p ? 'Allow health data processing' : 'Allow health data processing';
  String get ndpaDataSub  => _p ? 'We need am to give you medical help' : 'Required to provide you with medical services';
  String get ndpaMarketing => _p ? 'Receive health tips from us' : 'Receive health tips and updates (optional)';
}

extension AppStringsX on BuildContext {
  AppStrings get strings =>
      AppStrings(Localizations.localeOf(this).languageCode);
}
