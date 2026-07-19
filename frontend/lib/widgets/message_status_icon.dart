import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Status de envio da mensagem.
enum MessageStatus { sent, delivered, read }

/// Widget proprietário de status de mensagem com design futurista.
///
/// Design: "Pulse Arc" — traços curvos elegantes representando fluxo de comunicação.
/// - Enviada: um arco único cinza (pulso em trânsito)
/// - Entregue: dois arcos paralelos cinza/prata (conexão estabelecida)
/// - Visualizada: dois arcos com cor vibrante + brilho sutil (confirmação)
class MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;
  final double size;
  final bool isDark;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 16,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = isDark || brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PulseArcPainter(status: status, isDark: dark),
      ),
    );
  }
}

/// Versão animada do ícone de status para transição ao visualizar.
class AnimatedMessageStatusIcon extends StatefulWidget {
  final MessageStatus status;
  final double size;
  final bool isDark;

  const AnimatedMessageStatusIcon({
    super.key,
    required this.status,
    this.size = 16,
    this.isDark = false,
  });

  @override
  State<AnimatedMessageStatusIcon> createState() =>
      _AnimatedMessageStatusIconState();
}

class _AnimatedMessageStatusIconState extends State<AnimatedMessageStatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(AnimatedMessageStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status &&
        widget.status == MessageStatus.read) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = widget.isDark || brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _PulseArcPainter(
              status: widget.status,
              isDark: dark,
              glowProgress: widget.status == MessageStatus.read
                  ? _glowAnimation.value
                  : 1.0,
            ),
          ),
        );
      },
    );
  }
}

/// Painter personalizado que desenha os arcos "Pulse Arc".
class _PulseArcPainter extends CustomPainter {
  final MessageStatus status;
  final bool isDark;
  final double glowProgress;

  _PulseArcPainter({
    required this.status,
    required this.isDark,
    this.glowProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    switch (status) {
      case MessageStatus.sent:
        _drawSingleArc(canvas, center, radius, size);
        break;
      case MessageStatus.delivered:
        _drawDoubleArc(canvas, center, radius, size, highlighted: false);
        break;
      case MessageStatus.read:
        _drawDoubleArc(canvas, center, radius, size, highlighted: true);
        break;
    }
  }

  /// Estado 1: Mensagem enviada — um traço curvo minimalista.
  /// Design: arco elegante com ponta arredondada, como um pulso em trânsito.
  void _drawSingleArc(Canvas canvas, Offset center, double radius, Size size) {
    final color = isDark
        ? const Color(0xFF94A3B8) // slate-400
        : const Color(0xFF9CA3AF); // gray-400

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    // Arco fluido — representando "em trânsito"
    final rect = Rect.fromCenter(
      center: Offset(center.dx - size.width * 0.05, center.dy),
      width: radius * 1.8,
      height: radius * 1.8,
    );

    canvas.drawArc(
      rect,
      -math.pi * 0.65, // início
      math.pi * 0.8, // ângulo
      false,
      paint,
    );
  }

  /// Estado 2 e 3: Dois arcos paralelos — conexão estabelecida.
  void _drawDoubleArc(
    Canvas canvas,
    Offset center,
    double radius,
    Size size, {
    required bool highlighted,
  }) {
    final Color arcColor;
    if (highlighted) {
      // Cor vibrante da marca com transição de glow
      final baseColor = const Color(0xFF6C63FF); // primary/roxo
      final glowColor = const Color(0xFF818CF8); // indigo-400
      arcColor = Color.lerp(
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
        baseColor,
        glowProgress,
      )!;

      // Efeito de brilho sutil no estado "read"
      if (glowProgress > 0.3) {
        final glowPaint = Paint()
          ..color = glowColor.withValues(alpha: 0.3 * glowProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.22
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.08);

        _drawArcPair(canvas, center, radius, size, glowPaint);
      }
    } else {
      arcColor = isDark
          ? const Color(0xFF94A3B8) // slate-400
          : const Color(0xFF9CA3AF); // gray-400
    }

    final paint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    _drawArcPair(canvas, center, radius, size, paint);
  }

  /// Desenha o par de arcos com espaçamento elegante.
  void _drawArcPair(
    Canvas canvas,
    Offset center,
    double radius,
    Size size,
    Paint paint,
  ) {
    final spacing = size.width * 0.15;

    // Primeiro arco (mais à esquerda)
    final rect1 = Rect.fromCenter(
      center: Offset(center.dx - spacing, center.dy),
      width: radius * 1.6,
      height: radius * 1.6,
    );
    canvas.drawArc(rect1, -math.pi * 0.6, math.pi * 0.7, false, paint);

    // Segundo arco (mais à direita) — ligeiramente deslocado
    final rect2 = Rect.fromCenter(
      center: Offset(center.dx + spacing, center.dy),
      width: radius * 1.6,
      height: radius * 1.6,
    );
    canvas.drawArc(rect2, -math.pi * 0.6, math.pi * 0.7, false, paint);
  }

  @override
  bool shouldRepaint(_PulseArcPainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.isDark != isDark ||
        oldDelegate.glowProgress != glowProgress;
  }
}
