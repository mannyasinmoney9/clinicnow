import 'dart:async';
import 'dart:math' as math;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import 'teleconsult_providers.dart';

// Injected at build time: --dart-define=AGORA_APP_ID=xxxx
const _agoraAppId = String.fromEnvironment(
  'AGORA_APP_ID',
  defaultValue: '',
);

class TeleconsultPage extends ConsumerStatefulWidget {
  const TeleconsultPage({super.key, this.asStaff = false});
  final bool asStaff;

  @override
  ConsumerState<TeleconsultPage> createState() => _TeleconsultPageState();
}

class _TeleconsultPageState extends ConsumerState<TeleconsultPage>
    with TickerProviderStateMixin {
  RtcEngine? _engine;
  bool _muted = false;
  bool _cameraOff = false;
  int _remoteUid = 0;

  // Timer
  Timer? _timer;
  int _seconds = 0;

  // Animations
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: 2000.ms)..repeat(reverse: true);
    _waveCtrl =
        AnimationController(vsync: this, duration: 1200.ms)..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _cleanupAgora();
    super.dispose();
  }

  Future<void> _start() async {
    // Create backend session first
    await ref
        .read(teleconsultProvider.notifier)
        .createAndConnect(asStaff: widget.asStaff);

    final state = ref.read(teleconsultProvider);
    if (state is CallFallback) return; // already in fallback

    final channelName =
        state is CallConnecting ? state.channelName : 'demo-consult-1';

    // Check App ID
    if (_agoraAppId.isEmpty) {
      ref.read(teleconsultProvider.notifier).enterFallback(
        'No App ID — running in demo mode',
      );
      return;
    }

    // Request permissions
    final micOk = await Permission.microphone.request();
    final camOk = await Permission.camera.request();
    if (!micOk.isGranted || !camOk.isGranted) {
      if (!mounted) return;
      ref.read(teleconsultProvider.notifier).enterFallback(
        'Camera/mic permission denied — demo mode',
      );
      return;
    }

    // Init Agora
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: _agoraAppId));
      await _engine!.enableVideo();
      await _engine!.startPreview();

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) _startTimer();
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) return;
          setState(() => _remoteUid = remoteUid);
          ref.read(teleconsultProvider.notifier).onAgoraConnected(remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) return;
          setState(() => _remoteUid = 0);
          ref.read(teleconsultProvider.notifier).onRemoteLeft();
        },
        onLeaveChannel: (connection, stats) {
          if (!mounted) return;
          ref.read(teleconsultProvider.notifier).end();
        },
      ));

      await _engine!.joinChannel(
        token: '',
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ref.read(teleconsultProvider.notifier).enterFallback(
        'Agora init failed — demo mode',
      );
      _cleanupAgora();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    _muted = !_muted;
    await _engine?.muteLocalAudioStream(_muted);
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    _cameraOff = !_cameraOff;
    await _engine?.muteLocalVideoStream(_cameraOff);
    setState(() {});
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    ref.read(teleconsultProvider.notifier).end();
    if (mounted) context.pop();
  }

  Future<void> _cleanupAgora() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(teleconsultProvider);

    // Navigate away when ended
    ref.listen<CallState>(teleconsultProvider, (_, next) {
      if (next is CallEnded && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (callState) {
        CallIdle() ||
        CallConnecting() => _ConnectingView(channelName:
              callState is CallConnecting ? callState.channelName : '…'),
        CallFallback(reason: final reason, channelName: final ch) =>
          _FallbackCallView(
            reason: reason,
            channelName: ch,
            muted: _muted,
            cameraOff: _cameraOff,
            timerLabel: _timerLabel,
            pulseCtrl: _pulseCtrl,
            waveCtrl: _waveCtrl,
            onMute: () => setState(() => _muted = !_muted),
            onCamera: () => setState(() => _cameraOff = !_cameraOff),
            onEnd: () => context.pop(),
          ),
        CallActive(channelName: final ch) => _ActiveCallView(
            engine: _engine,
            channelName: ch,
            remoteUid: _remoteUid,
            muted: _muted,
            cameraOff: _cameraOff,
            timerLabel: _timerLabel,
            onMute: _toggleMute,
            onCamera: _toggleCamera,
            onEnd: _endCall,
          ),
        CallError() => _ActiveCallView(
            engine: null,
            channelName: '?',
            remoteUid: 0,
            muted: _muted,
            cameraOff: _cameraOff,
            timerLabel: _timerLabel,
            onMute: _toggleMute,
            onCamera: _toggleCamera,
            onEnd: _endCall,
          ),
        CallEnded() => const SizedBox.shrink(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Connecting screen
// ---------------------------------------------------------------------------

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({required this.channelName});
  final String channelName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _DarkBg(),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DoctorAvatar(),
              const SizedBox(height: 32),
              const Text('Connecting to doctor…',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(channelName,
                  style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.trustTeal),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: const AppBackButtonDark(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Active real Agora call view
// ---------------------------------------------------------------------------

class _ActiveCallView extends StatelessWidget {
  const _ActiveCallView({
    required this.engine,
    required this.channelName,
    required this.remoteUid,
    required this.muted,
    required this.cameraOff,
    required this.timerLabel,
    required this.onMute,
    required this.onCamera,
    required this.onEnd,
  });

  final RtcEngine? engine;
  final String channelName;
  final int remoteUid;
  final bool muted;
  final bool cameraOff;
  final String timerLabel;
  final VoidCallback onMute;
  final VoidCallback onCamera;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Remote video (full screen)
        if (engine != null && remoteUid != 0)
          Positioned.fill(
            child: AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: engine!,
                canvas: VideoCanvas(uid: remoteUid),
                connection: RtcConnection(channelId: channelName),
              ),
            ),
          )
        else
          Stack(
            children: [
              const _DarkBg(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _DoctorAvatar(),
                    const SizedBox(height: 16),
                    const Text('Waiting for doctor to join…',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),

        // Local video PiP
        if (engine != null && !cameraOff)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 100,
                height: 140,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          )
        else if (!cameraOff)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _LocalPlaceholderPip(),
          ),

        // Top bar: timer + channel
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 60,
          right: 120,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.nairaGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(timerLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Back
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: const AppBackButtonDark(),
        ),

        // Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 0, right: 0,
          child: _CallControls(
            muted: muted,
            cameraOff: cameraOff,
            onMute: onMute,
            onCamera: onCamera,
            onEnd: onEnd,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback demo call view
// ---------------------------------------------------------------------------

class _FallbackCallView extends StatelessWidget {
  const _FallbackCallView({
    required this.reason,
    required this.channelName,
    required this.muted,
    required this.cameraOff,
    required this.timerLabel,
    required this.pulseCtrl,
    required this.waveCtrl,
    required this.onMute,
    required this.onCamera,
    required this.onEnd,
  });

  final String reason;
  final String channelName;
  final bool muted;
  final bool cameraOff;
  final String timerLabel;
  final AnimationController pulseCtrl;
  final AnimationController waveCtrl;
  final VoidCallback onMute;
  final VoidCallback onCamera;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _DarkBg(),

        // Animated waveform behind avatar
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow rings
                    for (int i = 0; i < 3; i++)
                      Container(
                        width: 80 + i * 28 + pulseCtrl.value * 14,
                        height: 80 + i * 28 + pulseCtrl.value * 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.trustTeal.withAlpha(
                              (60 - i * 15 - (pulseCtrl.value * 20).toInt()).clamp(0, 255),
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                    child!,
                  ],
                ),
                child: const _DoctorAvatar(),
              ),

              const SizedBox(height: 24),

              // Fake audio waveform
              AnimatedBuilder(
                animation: waveCtrl,
                builder: (_, _) => CustomPaint(
                  painter: _WaveformPainter(waveCtrl.value),
                  size: const Size(160, 32),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Dr. Oluwaseun Adeyemi',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(timerLabel,
                  style: const TextStyle(
                      color: AppColors.nairaGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        // Demo mode banner
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.waitAmber.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.waitAmber.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.waitAmber),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Demo mode: $reason',
                    style: const TextStyle(
                        color: AppColors.waitAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // Back
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: const AppBackButtonDark(),
        ),

        // Bottom controls (still interactive for demo)
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 0, right: 0,
          child: _CallControls(
            muted: muted,
            cameraOff: cameraOff,
            onMute: onMute,
            onCamera: onCamera,
            onEnd: onEnd,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared call controls bar
// ---------------------------------------------------------------------------

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.muted,
    required this.cameraOff,
    required this.onMute,
    required this.onCamera,
    required this.onEnd,
  });

  final bool muted;
  final bool cameraOff;
  final VoidCallback onMute;
  final VoidCallback onCamera;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CtrlButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: muted ? 'Unmute' : 'Mute',
          active: muted,
          onTap: onMute,
        ),
        const SizedBox(width: 20),
        // End call — big red button
        GestureDetector(
          onTap: onEnd,
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.emergencyRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xAADC2626),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.call_end_rounded,
                color: Colors.white, size: 30),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2000.ms, color: Colors.white.withAlpha(20)),
        const SizedBox(width: 20),
        _CtrlButton(
          icon: cameraOff
              ? Icons.videocam_off_rounded
              : Icons.videocam_rounded,
          label: cameraOff ? 'Camera on' : 'Camera off',
          active: cameraOff,
          onTap: onCamera,
        ),
      ],
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 400.ms);
  }
}

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: 200.ms,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? Colors.white.withAlpha(40)
                  : Colors.white.withAlpha(20),
              border: Border.all(
                color: active
                    ? Colors.white.withAlpha(120)
                    : Colors.white.withAlpha(40),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Doctor avatar
// ---------------------------------------------------------------------------

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.trustTeal, AppColors.nairaGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.trustTeal.withAlpha(100),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.medical_services_rounded,
          color: Colors.white, size: 36),
    );
  }
}

// ---------------------------------------------------------------------------
// Local video PiP placeholder
// ---------------------------------------------------------------------------

class _LocalPlaceholderPip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 100,
        height: 140,
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(Icons.person_rounded, color: Colors.white54, size: 36),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dark gradient background
// ---------------------------------------------------------------------------

class _DarkBg extends StatelessWidget {
  const _DarkBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF040E0D), Color(0xFF0A2928), Color(0xFF061918)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audio waveform painter (fake but animated)
// ---------------------------------------------------------------------------

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.t);
  final double t;

  static const _bars = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.trustTeal.withAlpha(200)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final barWidth = size.width / _bars;
    for (int i = 0; i < _bars; i++) {
      final phase = (t + i / _bars) % 1.0;
      final height = size.height *
          (0.2 + 0.7 * (math.sin(phase * 2 * math.pi * 2 + i * 0.5) * 0.5 + 0.5));
      final x = i * barWidth + barWidth / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.t != t;
}