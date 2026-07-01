import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/app_theme.dart';

class ReadAloudButton extends StatefulWidget {
  const ReadAloudButton({
    super.key,
    required this.text,
    this.size = 36,
  });

  final String text;
  final double size;

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  late final FlutterTts _tts;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('en-NG').ignore();
    _tts.setSpeechRate(0.5).ignore();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop().ignore();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      if (!mounted) return;
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await _tts.speak(widget.text);
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Read aloud',
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _speaking ? Icons.stop_rounded : Icons.volume_up_outlined,
            size: widget.size * 0.5,
            color: context.colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
