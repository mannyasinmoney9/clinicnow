/// Nurse Ada's fully offline brain — scripted, deterministic, never fails.
/// Used directly in demo mode (no network attempted at all) and as the
/// client-side fallback if the real backend/Gemini call ever errors.
///
/// Each symptom gets a specific, medically-appropriate response.
/// Danger-sign triage follows the 7-question red/yellow/green flow.
/// Switches to Pidgin when the user writes in Pidgin.
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

  static String reply(String message, {String locale = 'en'}) {
    final lower = message.trim().toLowerCase();
    final pidgin = locale == 'pcm' || _isPidgin(message);

    // ── Specific symptom responses ──────────────────────────────────────

    if (lower.contains('headache') || lower.contains('head pain') || lower.contains('head ache')) {
      return pidgin
          ? '🟡 Headache fit pass through different reasons:\n\n'
              '• Tension — stress, no sleep, or stay for sun too long\n'
              '• Malaria — especially if you get fever plus\n'
              '• Eye strain — if you dey look screen too much\n'
              '• Dehydration — no drink enough water\n\n'
              'Wetin you fit do now:\n'
              '1. Drink plenty water\n'
              '2. Rest for quiet, dark room\n'
              '3. Paracetamol (500mg) fit help — no use ibuprofen for empty stomach\n\n'
              '🔴 Go hospital sharp sharp if:\n'
              '• The headache na the worst one you ever get\n'
              '• You dey vomit\n'
              '• Your neck dey stiff\n'
              '• You get blurred vision\n\n'
              'You wan join queue make doctor check am? Go home page, tap "Join Queue".'
          : '🟡 Headaches can come from several causes:\n\n'
              '• Tension — stress, poor sleep, or sun exposure\n'
              '• Malaria — especially with fever\n'
              '• Eye strain — too much screen time\n'
              '• Dehydration — not drinking enough water\n\n'
              'What you can do now:\n'
              '1. Drink plenty of water\n'
              '2. Rest in a quiet, dark room\n'
              '3. Paracetamol (500mg) can help — avoid ibuprofen on an empty stomach\n\n'
              '🔴 See a doctor immediately if:\n'
              '• This is the worst headache of your life\n'
              '• You\'re vomiting\n'
              '• Your neck is stiff\n'
              '• You have blurred vision\n\n'
              'Want to join the queue? Go to the home screen and tap "Join Queue".';
    }

    if ((lower.contains('fever') && lower.contains('chill')) || lower.contains('fever and chill') || (lower.contains('temperature') && lower.contains('cold'))) {
      return pidgin
          ? '🟡 Fever plus chills fit mean infection — malaria na the common one for Nigeria.\n\n'
              'Wetin you fit do now:\n'
              '1. Paracetamol to bring down the temperature\n'
              '2. Drink plenty fluids — water, ORS, or tea\n'
              '3. Wear light clothes — no cover up too much\n'
              '4. Rest well\n\n'
              '🔴 Go hospital immediately if:\n'
              '• Fever pass 39°C or e don pass 3 days\n'
              '• You dey vomit and no fit keep food down\n'
              '• You get stiff neck or confusion\n'
              '• You get difficulty breathing\n\n'
              '🟡 If e don pass 3 days, see doctor today. You fit join queue from home page.'
          : '🟡 Fever with chills often points to an infection — malaria is the most common cause in Nigeria.\n\n'
              'What you can do now:\n'
              '1. Take paracetamol to reduce the temperature\n'
              '2. Drink plenty of fluids — water, ORS, or warm tea\n'
              '3. Wear light clothing — don\'t over-bundle\n'
              '4. Rest as much as possible\n\n'
              '🔴 See a doctor immediately if:\n'
              '• Fever is above 39°C or has lasted more than 3 days\n'
              '• You\'re vomiting and can\'t keep fluids down\n'
              '• You have a stiff neck or confusion\n'
              '• You have difficulty breathing\n\n'
              '🟡 If it\'s been more than 3 days, see a doctor today. You can join the queue from the home screen.';
    }

    if (lower.contains('chest hurt') || lower.contains('chest pain') || lower.contains('chest tight')) {
      return pidgin
          ? '🔴 Chest pain no be something wey you fit manage for house. This fit be:\n'
              '• Heart problem\n'
              '• Lung infection or blockage\n'
              '• Severe acid reflux\n'
              '• Muscle strain\n\n'
              'Call 112 or Lagos 767 now now. Or go emergency department sharp sharp.\n\n'
              'While you dey wait:\n'
              '• Sit down and try breathe slow\n'
              '• No dey move around too much\n'
              '• If you get access to aspirin (and you no dey allergic), chew one slowly\n\n'
              'This na emergency. No wait.'
          : '🔴 Chest pain is something you should never ignore. It could be:\n'
              '• A heart problem\n'
              '• Lung infection or blood clot\n'
              '• Severe acid reflux\n'
              '• Muscle strain\n\n'
              'Call 112 or Lagos 767 now, or go to the nearest emergency department immediately.\n\n'
              'While you wait:\n'
              '• Sit down and try to breathe slowly\n'
              '• Don\'t move around too much\n'
              '• If you have aspirin (and aren\'t allergic), chew one slowly\n\n'
              'This is an emergency. Don\'t wait.';
    }

    if (lower.contains('short of breath') || lower.contains('breath') || lower.contains('breathe') || lower.contains('breathing')) {
      return pidgin
          ? '🔴 If you no fit breathe well, this na emergency.\n\n'
              'Possible causes:\n'
              '• Asthma attack\n'
              '• Heart problem\n'
              '• Lung infection (pneumonia)\n'
              '• Allergic reaction\n\n'
              'Do this now:\n'
              '1. Sit upright — no lie down\n'
              '2. Try breathe slow and steady\n'
              '3. If you get inhaler, use am\n'
              '4. Call 112 or go hospital now\n\n'
              '🔴 If your lips dey blue or you dey gasp, call 112 now now.'
          : '🔴 If you\'re having trouble breathing, this is an emergency.\n\n'
              'Possible causes:\n'
              '• Asthma attack\n'
              '• Heart problem\n'
              '• Lung infection (pneumonia)\n'
              '• Allergic reaction\n\n'
              'Do this now:\n'
              '1. Sit upright — don\'t lie down\n'
              '2. Try to breathe slowly and steadily\n'
              '3. If you have an inhaler, use it\n'
              '4. Call 112 or go to hospital now\n\n'
              '🔴 If your lips are turning blue or you\'re gasping for air, call 112 immediately.';
    }

    if (lower.contains('malaria') || lower.contains('mala')) {
      return pidgin
          ? '🟡 Malaria na the most common sickness for Nigeria. Na mosquito bite cause am.\n\n'
              'Signs:\n'
              '• Fever and chills\n'
              '• Body pain and headache\n'
              '• Vomiting or loss of appetite\n'
              '• Feeling tired and weak\n\n'
              'Wetin you fit do:\n'
              '1. Go clinic do malaria test (rapid test or blood slide)\n'
              '2. If e positive, take the medicine the doctor give you — complete the full course\n'
              '3. Drink plenty water and rest\n'
              '4. Use insecticide-treated mosquito net\n\n'
              '🔴 Go hospital immediately if:\n'
              '• You get high fever (above 39°C)\n'
              '• You dey vomit and no fit keep medicine down\n'
              '• You dey confused or very weak\n'
              '• You get convulsion\n\n'
              '⚠️ No buy medicine for road — resistance don increase. Test first, then treat.'
          : '🟡 Malaria is the most common illness in Nigeria, caused by mosquito bites.\n\n'
              'Symptoms:\n'
              '• Fever and chills\n'
              '• Body aches and headache\n'
              '• Vomiting or loss of appetite\n'
              '• Fatigue and weakness\n\n'
              'What to do:\n'
              '1. Go to a clinic for a malaria test (rapid test or blood slide)\n'
              '2. If positive, take prescribed medication — complete the full course\n'
              '3. Drink plenty of water and rest\n'
              '4. Use an insecticide-treated mosquito net\n\n'
              '🔴 See a doctor immediately if:\n'
              '• High fever (above 39°C)\n'
              '• You\'re vomiting and can\'t keep medication down\n'
              '• Confusion or extreme weakness\n'
              '• Seizures\n\n'
              '⚠️ Don\'t buy drugs from the street — resistance is increasing. Test first, then treat.';
    }

    if (lower.contains('antenatal') || lower.contains('pregnan') || lower.contains('pregnancy') || lower.contains('baby') || lower.contains('ANC')) {
      return pidgin
          ? '🟢 For antenatal care, WHO say make you get 8 ANC contact throughout your pregnancy.\n\n'
              'Schedule:\n'
              '• First trimester: At least 1 visit\n'
              '• Second trimester: 2 visits (around 20-26 weeks)\n'
              '• Third trimester: 5 visits (28-38 weeks)\n\n'
              'Important:\n'
              '• Take your iron and folic acid tablets\n'
              '• Attend all your appointments\n'
              '• Book am for "Appointments" tab so we fit remind you\n\n'
              '🔴 Go hospital sharp sharp if:\n'
              '• You dey bleed\n'
              '• Severe belle pain\n'
              '• The baby no dey move\n'
              '• Severe headache with swollen face\n\n'
              'This na guide. If you no sure, go hospital.'
          : '🟢 For antenatal care, WHO recommends 8 ANC contacts across your pregnancy.\n\n'
              'Schedule:\n'
              '• First trimester: At least 1 visit\n'
              '• Second trimester: 2 visits (around 20-26 weeks)\n'
              '• Third trimester: 5 visits (28-38 weeks)\n\n'
              'Important:\n'
              '• Take your iron and folic acid tablets daily\n'
              '• Attend all your appointments\n'
              '• Book from the "Appointments" tab so we can remind you\n\n'
              '🔴 Go to hospital immediately if:\n'
              '• You have bleeding\n'
              '• Severe abdominal pain\n'
              '• Reduced fetal movement\n'
              '• Severe headache with swollen face\n\n'
              'This is a guide. If you\'re not sure, go to hospital.';
    }

    if (lower.contains('queue') || lower.contains('join')) {
      return pidgin
          ? 'To join queue, go home page, tap "Join Queue", pick your clinic. You go see your ticket number and how many people dey ahead of you, e go update as e dey move — no need to dey refresh.\n\n'
              'When e be your turn, you go get notification. You fit also dey watch the live queue board for real-time updates.'
          : 'To join the queue, go to the home screen, tap "Join Queue", and pick your clinic. You\'ll get a ticket number and see how many people are ahead of you — it updates live, no need to refresh.\n\n'
              'When it\'s your turn, you\'ll get a notification. You can also watch the live queue board for real-time updates.';
    }

    // ── Red-flag emergencies ────────────────────────────────────────────

    final hasRedFlag = _redFlagWords.any(lower.contains);
    if (hasRedFlag) {
      return pidgin
          ? '🔴 Wetin you dey feel sound serious. Abeg no wait — call 112 or Lagos 767 now now, or go emergency department sharp sharp.\n\n'
              'This na guide. If you no sure, go hospital.'
          : '🔴 What you\'re describing sounds serious. Please don\'t wait — call 112 or Lagos 767 now, or go to the nearest emergency department right away.\n\n'
              'This is a guide. If you\'re not sure, go to hospital.';
    }

    // ── Yellow-flag: generic for other yellow-flag words ────────────────
    if (lower.contains('vomit') || lower.contains('diarrhoea') || lower.contains('diarrhea')) {
      return pidgin
          ? '🟡 Vomiting or diarrhea fit cause dehydration quickly. Do this:\n\n'
              '1. Drink small small water or ORS (oral rehydration salt)\n'
              '2. No drink juice or milk — e fit worsen am\n'
              '3. Eat light food — rice, bread, or banana\n'
              '4. Rest well\n\n'
              '🔴 Go hospital if:\n'
              '• You dey vomit everything you take\n'
              '• E don pass 24 hours and e no dey improve\n'
              '• You dey dizzy or very weak\n'
              '• Blood dey inside the vomit or stool'
          : '🟡 Vomiting or diarrhoea can cause dehydration quickly. Do this:\n\n'
              '1. Sip water or ORS (oral rehydration salt) frequently\n'
              '2. Avoid juice or milk — it can make it worse\n'
              '3. Eat light foods — rice, bread, or banana\n'
              '4. Rest well\n\n'
              '🔴 See a doctor if:\n'
              '• You can\'t keep any fluids down\n'
              '• It hasn\'t improved after 24 hours\n'
              '• You feel dizzy or very weak\n'
              '• There\'s blood in your vomit or stool';
    }

    if (lower.contains('rash') || lower.contains('skin')) {
      return pidgin
          ? '🟡 Skin rash fit come from different things — infection, allergy, or reaction to medicine.\n\n'
              'Wetin you fit do:\n'
              '1. No scratch am — e fit worsen\n'
              '2. Wash am gentle with clean water\n'
              '3. If e dey itch, cold compress fit help\n'
              '4. Check if you start any new medicine\n\n'
              '🔴 Go hospital if:\n'
              '• E dey spread fast\n'
              '• You get fever plus\n'
              '• E dey pain or dey form blisters\n'
              '• You dey swell up (face, lips, tongue)'
          : '🟡 A skin rash can come from many causes — infection, allergy, or medication reaction.\n\n'
              'What to do:\n'
              '1. Don\'t scratch — it can make it worse\n'
              '2. Gently wash with clean water\n'
              '3. If it\'s itchy, a cold compress can help\n'
              '4. Check if you started any new medication\n\n'
              '🔴 See a doctor if:\n'
              '• It\'s spreading rapidly\n'
              '• You have a fever too\n'
              '• It\'s painful or forming blisters\n'
              '• You\'re swelling up (face, lips, tongue)';
    }

    if (lower.contains('cough') || lower.contains('cold') || lower.contains('sore throat') || lower.contains('throat')) {
      return pidgin
          ? '🟡 Cough and sore throat most times na viral infection — e go pass within 7-10 days.\n\n'
              'Wetin you fit do:\n'
              '1. Drink warm water with honey and lemon\n'
              '2. Rest your voice\n'
              '3. Paracetamol for pain and fever\n'
              '4. Gargle warm salt water for sore throat\n'
              '5. No dey smoke or dey dusty place\n\n'
              '🔴 Go hospital if:\n'
              '• Cough don pass 2 weeks\n'
              '• You dey cough blood\n'
              '• You get difficulty breathing\n'
              '• You get high fever'
          : '🟡 Coughs and sore throats are usually viral infections — they resolve within 7-10 days.\n\n'
              'What you can do:\n'
              '1. Drink warm water with honey and lemon\n'
              '2. Rest your voice\n'
              '3. Paracetamol for pain and fever\n'
              '4. Gargle warm salt water for sore throat\n'
              '5. Avoid smoke and dusty environments\n\n'
              '🔴 See a doctor if:\n'
              '• Cough has lasted more than 2 weeks\n'
              '• You\'re coughing up blood\n'
              '• You have difficulty breathing\n'
              '• You have a high fever';
    }

    if (lower.contains('weak') || lower.contains('dizzy') || lower.contains('tired') || lower.contains('fatigue')) {
      return pidgin
          ? '🟡 Feeling weak or dizzy fit come from:\n\n'
              '• Not enough sleep\n'
              '• Dehydration — no drink enough water\n'
              '• Low blood sugar — you never chop\n'
              '• Malaria or other infection\n'
              '• Anaemia (low blood)\n\n'
              'Wetin you fit do:\n'
              '1. Drink water and eat something\n'
              '2. Rest well\n'
              '3. If e dey come often, go clinic do blood test\n\n'
              '🔴 Go hospital if you dey faint or e no dey stop.'
          : '🟡 Feeling weak or dizzy can come from:\n\n'
              '• Not enough sleep\n'
              '• Dehydration — not enough water\n'
              '• Low blood sugar — you haven\'t eaten\n'
              '• Malaria or other infection\n'
              '• Anaemia (low blood)\n\n'
              'What to do:\n'
              '1. Drink water and eat something\n'
              '2. Rest well\n'
              '3. If it happens often, see a doctor for a blood test\n\n'
              '🔴 Go to hospital if you faint or it doesn\'t improve.';
    }

    if (lower.contains('pain')) {
      return pidgin
          ? '🟡 Body pain fit come from different things — stress, infection, or injury.\n\n'
              'Wetin you fit do:\n'
              '1. Rest the area wey dey pain\n'
              '2. Paracetamol (500mg) every 6-8 hours\n'
              '3. Hot compress for muscle pain\n'
              '4. Stretch gentle if e be stiffness\n\n'
              '🔴 Go hospital if:\n'
              '• Pain dey very bad or e no dey stop\n'
              '• You no fit move that part\n'
              '• You get fever plus\n'
              '• E dey come suddenly after injury'
          : '🟡 Body pain can come from various causes — stress, infection, or injury.\n\n'
              'What to do:\n'
              '1. Rest the affected area\n'
              '2. Paracetamol (500mg) every 6-8 hours\n'
              '3. Hot compress for muscle pain\n'
              '4. Gentle stretching if it\'s stiffness\n\n'
              '🔴 See a doctor if:\n'
              '• The pain is severe or won\'t stop\n'
              '• You can\'t move the affected part\n'
              '• You have a fever too\n'
              '• It came on suddenly after an injury';
    }

    // ── Default catch-all ───────────────────────────────────────────────

    return pidgin
        ? 'I dey here to help with symptoms, appointments, or how to use ClinicNow. Tell me wetin dey happen — for example:\n\n'
            '• "I have a headache"\n'
            '• "I have fever and chills"\n'
            '• "My chest hurts"\n'
            '• "Is malaria serious?"\n\n'
            'Or tap one of the quick questions below. 👋'
        : 'I\'m here to help with symptoms, appointments, or how to use ClinicNow. Tell me what\'s going on — for example:\n\n'
            '• "I have a headache"\n'
            '• "I have fever and chills"\n'
            '• "My chest hurts"\n'
            '• "Is malaria serious?"\n\n'
            'Or tap one of the quick questions below. 👋';
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
