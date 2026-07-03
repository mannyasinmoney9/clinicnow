/// Nurse Ada's fully offline brain — scripted, deterministic, never fails.
/// Used directly in demo mode (no network attempted at all) and as the
/// client-side fallback if the real backend/Gemini call ever errors.
///
/// Danger-sign triage follows the 7-question red/yellow/green flow from
/// docs/BLUEPRINT.md. Switches to Pidgin when the user writes in Pidgin.
abstract final class OfflineAdaEngine {
  static const _pidginHints = [
    'abeg', 'wetin', 'dey', 'na ', 'una', 'sabi', 'wahala', 'oyibo', 'wan ',
  ];

  static bool _isPidgin(String message) {
    final lower = message.toLowerCase();
    return _pidginHints.any(lower.contains);
  }

  static const _redFlagWords = [
    'chest pain', 'chest hurt', 'can\'t breathe', 'cannot breathe',
    'short of breath', 'breathe well', 'unconscious', 'seizure', 'convulsion',
    'heavy bleeding', 'bleeding a lot', 'severe bleeding', 'stroke',
    'can\'t wake', 'not breathing', 'blue lips', 'severe pain',
  ];

  static const _yellowFlagWords = [
    'fever', 'chills', 'vomit', 'headache', 'diarrhoea', 'diarrhea',
    'malaria', 'weak', 'dizzy', 'rash', 'cough', 'sore throat', 'pain',
  ];

  static String reply(String message, {String locale = 'en'}) {
    final lower = message.trim().toLowerCase();
    final pidgin = locale == 'pcm' || _isPidgin(message);

    if (lower.contains('antenatal') || lower.contains('pregnan')) {
      return pidgin
          ? 'For antenatal, WHO say make you get 8 ANC contact throughout your pregnancy. Book am for "Appointments" tab so we fit remind you. If you dey bleed, get serious belle pain, or the baby no dey move, go hospital sharp sharp. 🟢\n\nThis na guide. If you no sure, go hospital.'
          : 'For antenatal care, WHO recommends 8 ANC contacts across your pregnancy. You can book one from the Appointments tab and we\'ll remind you. If you have bleeding, severe abdominal pain, or reduced fetal movement, please go to the clinic immediately. 🟢\n\nThis is a guide. If you\'re not sure, go to hospital.';
    }

    if (lower.contains('queue') || lower.contains('join')) {
      return pidgin
          ? 'To join queue, go home page, tap "Join Queue", pick your clinic. You go see your ticket number and how many people dey ahead of you, e go update as e dey move — no need to dey refresh.'
          : 'To join the queue, go to the home screen, tap "Join Queue", and pick your clinic. You\'ll get a ticket number and see how many people are ahead of you — it updates live, no need to refresh.';
    }

    final hasRedFlag = _redFlagWords.any(lower.contains);
    if (hasRedFlag) {
      return pidgin
          ? '🔴 Wetin you dey feel sound serious. Abeg no wait — call 112 or Lagos 767 now now, or go emergency department sharp sharp.\n\nThis na guide. If you no sure, go hospital.'
          : '🔴 What you\'re describing sounds serious. Please don\'t wait — call 112 or Lagos 767 now, or go to the nearest emergency department right away.\n\nThis is a guide. If you\'re not sure, go to hospital.';
    }

    final hasYellowFlag = _yellowFlagWords.any(lower.contains);
    if (hasYellowFlag) {
      return pidgin
          ? '🟡 I hear you. Make we check small: (1) Fever pass 3 days? (2) You dey vomit anything wey you chop? (3) You dey find am hard to breathe? If na yes for any, abeg see doctor today — you fit join queue from home page. If na no, rest well, drink plenty water, and watch am. This na guide. If you no sure, go hospital.'
          : '🟡 Thanks for sharing. Let\'s check a few things: (1) Has the fever lasted more than 3 days? (2) Are you unable to keep fluids down? (3) Are you finding it hard to breathe? If yes to any of these, please see a doctor today — you can join the queue from the home screen. If no, rest, stay hydrated, and monitor closely.\n\nThis is a guide. If you\'re not sure, go to hospital.';
    }

    return pidgin
        ? 'I dey here to help with symptoms, appointments, or how to use ClinicNow. Tell me wetin dey happen, or tap one of the quick questions below. 👋'
        : 'I\'m here to help with symptoms, appointments, or how to use ClinicNow. Tell me what\'s going on, or tap one of the quick questions below. 👋';
  }

  /// The 7 yes/no danger-sign questions used by the standalone Triage screen.
  static const triageQuestions = [
    'Is the person unconscious or very difficult to wake up?',
    'Are they having severe difficulty breathing?',
    'Is there heavy bleeding that won\'t stop?',
    'Are they having a seizure/convulsion right now?',
    'Is there severe chest pain or pressure?',
    'Has the fever lasted more than 3 days or gone above 39°C?',
    'Are they unable to keep any fluids down?',
  ];

  /// Red if any of the first 4 (true emergencies) are yes; yellow if any of
  /// the rest are yes; otherwise green.
  static TriageResult scoreTriage(List<bool> answers) {
    for (var i = 0; i < 4 && i < answers.length; i++) {
      if (answers[i]) return TriageResult.red;
    }
    for (var i = 4; i < answers.length; i++) {
      if (answers[i]) return TriageResult.yellow;
    }
    return TriageResult.green;
  }
}

enum TriageResult { red, yellow, green }