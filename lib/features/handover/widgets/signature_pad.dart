import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.label,
    required this.party,
    required this.signed,
    required this.onSign,
    required this.onClear,
  });

  final String label;
  final String party;
  final bool signed;
  final ValueChanged<String> onSign;
  final VoidCallback onClear;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  int _commitCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(widget.party, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              Text(
                widget.signed ? 'Bertanda tangan' : 'Belum bertanda tangan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.signed ? AppColors.green : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = _Stroke(points: [details.localPosition]);
                  });
                },
                onPanUpdate: (details) {
                  if (_currentStroke != null) {
                    setState(() {
                      _currentStroke!.points.add(details.localPosition);
                    });
                  }
                },
                onPanEnd: (details) {
                  if (_currentStroke != null && _currentStroke!.points.length > 1) {
                    setState(() {
                      _strokes.add(_currentStroke!);
                      _commitCount++;
                      widget.onSign(_encodeStrokes());
                    });
                  }
                  _currentStroke = null;
                },
                child: Container(
                  width: constraints.maxWidth,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: CustomPaint(
                    painter: _SignaturePainter(strokes: _strokes, currentStroke: _currentStroke),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
          if (_strokes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text('Tanda tangan di sini', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _strokes.clear();
                  widget.onClear();
                });
              },
              child: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  String _encodeStrokes() {
    return _strokes.map((s) => s.points.map((p) => '${p.dx.toStringAsFixed(1)},${p.dy.toStringAsFixed(1)}').join(';')).join('|');
  }
}

class _Stroke {
  _Stroke({required this.points});
  final List<Offset> points;
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, this.currentStroke});
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    if (currentStroke != null && currentStroke!.points.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke!.points.first.dx, currentStroke!.points.first.dy);
      for (int i = 1; i < currentStroke!.points.length; i++) {
        path.lineTo(currentStroke!.points[i].dx, currentStroke!.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
