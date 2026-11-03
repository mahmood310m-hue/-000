import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';

/// شريط أخبار متحرك من اليسار إلى اليمين. اضغط عليه للإيقاف/الاستئناف.
class NewsTicker extends StatefulWidget {
  const NewsTicker({super.key});
  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 30));
  String _text = '';
  bool _paused = false;
  static const _style =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark);

  @override
  void initState() {
    super.initState();
    _load();
    dataVersion.addListener(_load);
  }

  Future<void> _load() async {
    try {
      final rows = await sb.from('news').select('text').eq('active', true).order('sort');
      final t = rows.map((r) => (r['text'] ?? '').toString()).where((s) => s.isNotEmpty).join('      •      ');
      if (!mounted) return;
      setState(() => _text = t);
      if (t.isNotEmpty) {
        _c.duration = Duration(seconds: 12 + t.length ~/ 5);
        if (!_paused && !_c.isAnimating) _c.repeat();
      } else {
        _c.stop();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    dataVersion.removeListener(_load);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: _text.isEmpty
          ? const Center(
              child: Text('لا توجد أخبار حالياً',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)))
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _paused = !_paused;
                _paused ? _c.stop() : _c.repeat();
              }),
              child: LayoutBuilder(builder: (context, box) {
                final tp = TextPainter(
                  text: TextSpan(text: _text, style: _style),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                )..layout();
                final w = tp.width + 8;
                return AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) {
                    // من خارج الحافة اليسرى إلى خارج الحافة اليمنى
                    final left = -w + (box.maxWidth + w) * _c.value;
                    return Stack(children: [
                      Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: w,
                        child: Center(
                          child: Text(_text,
                              style: _style, softWrap: false, maxLines: 1),
                        ),
                      ),
                      if (_paused)
                        const Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: Icon(Icons.pause_circle_outline,
                              size: 16, color: AppColors.muted),
                        ),
                    ]);
                  },
                );
              }),
            ),
    );
  }
}
