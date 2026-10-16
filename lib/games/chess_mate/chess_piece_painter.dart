import 'package:flutter/material.dart';

import 'chess_mate_puzzle.dart';

class ChessPiecePainter extends CustomPainter {
  const ChessPiecePainter({required this.piece});

  final ChessPiece piece;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final bool white = piece.side == ChessSide.white;
    final Color fill = white
        ? const Color(0xFFFFFBF2)
        : const Color(0xFF26333B);
    final Color edge = white
        ? const Color(0xFF35464B)
        : const Color(0xFFFFF4DA);
    final Color detail = white
        ? const Color(0xFF9B6D3E)
        : const Color(0xFFD9B66E);
    final Paint silhouette = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final Paint outline = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = white ? 5.5 : 4.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final Paint accent = Paint()
      ..color = detail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // A double-tier plinth gives every piece a shared, grounded silhouette.
    final Path plinth = Path()
      ..moveTo(23, 82)
      ..lineTo(77, 82)
      ..lineTo(84, 94)
      ..quadraticBezierTo(50, 100, 16, 94)
      ..close();
    canvas.drawPath(plinth, silhouette);
    canvas.drawPath(plinth, outline);
    canvas.drawLine(const Offset(22, 88), const Offset(78, 88), accent);

    switch (piece.type) {
      case ChessPieceType.pawn:
        final Path body = Path()
          ..moveTo(35, 79)
          ..cubicTo(37, 68, 43, 63, 43, 55)
          ..cubicTo(43, 47, 38, 43, 38, 38)
          ..cubicTo(38, 25, 62, 25, 62, 38)
          ..cubicTo(62, 43, 57, 47, 57, 55)
          ..cubicTo(57, 63, 63, 68, 65, 79)
          ..close();
        canvas.drawPath(body, silhouette);
        canvas.drawPath(body, outline);
        canvas.drawCircle(const Offset(50, 19), 12, silhouette);
        canvas.drawCircle(const Offset(50, 19), 12, outline);
        canvas.drawLine(const Offset(43, 69), const Offset(57, 69), accent);
      case ChessPieceType.rook:
        final Path tower = Path()
          ..moveTo(28, 78)
          ..lineTo(31, 37)
          ..lineTo(25, 37)
          ..lineTo(25, 20)
          ..lineTo(38, 20)
          ..lineTo(38, 29)
          ..lineTo(46, 29)
          ..lineTo(46, 20)
          ..lineTo(55, 20)
          ..lineTo(55, 29)
          ..lineTo(63, 29)
          ..lineTo(63, 20)
          ..lineTo(76, 20)
          ..lineTo(76, 37)
          ..lineTo(69, 37)
          ..lineTo(72, 78)
          ..close();
        canvas.drawPath(tower, silhouette);
        canvas.drawPath(tower, outline);
        canvas.drawLine(const Offset(36, 47), const Offset(64, 47), accent);
        canvas.drawLine(const Offset(35, 64), const Offset(65, 64), accent);
      case ChessPieceType.bishop:
        final Path bishop = Path()
          ..moveTo(29, 79)
          ..cubicTo(34, 65, 39, 58, 39, 48)
          ..cubicTo(39, 39, 32, 35, 34, 27)
          ..cubicTo(36, 16, 64, 16, 66, 27)
          ..cubicTo(68, 35, 61, 39, 61, 48)
          ..cubicTo(61, 58, 66, 65, 71, 79)
          ..close();
        canvas.drawPath(bishop, silhouette);
        canvas.drawPath(bishop, outline);
        canvas.drawCircle(const Offset(50, 25), 3.7, Paint()..color = detail);
        canvas.drawLine(const Offset(57, 35), const Offset(43, 49), accent);
        canvas.drawLine(const Offset(39, 66), const Offset(61, 66), accent);
      case ChessPieceType.knight:
        final Path knight = Path()
          ..moveTo(28, 79)
          ..lineTo(29, 65)
          ..cubicTo(33, 56, 35, 50, 34, 43)
          ..lineTo(27, 38)
          ..lineTo(38, 20)
          ..lineTo(47, 31)
          ..cubicTo(54, 22, 66, 24, 73, 34)
          ..lineTo(69, 43)
          ..cubicTo(63, 47, 59, 53, 62, 61)
          ..lineTo(72, 79)
          ..close();
        canvas.drawPath(knight, silhouette);
        canvas.drawPath(knight, outline);
        canvas.drawCircle(const Offset(59, 37), 2.8, Paint()..color = detail);
        canvas.drawLine(const Offset(42, 53), const Offset(57, 53), accent);
      case ChessPieceType.queen:
        final Path crown = Path()
          ..moveTo(27, 78)
          ..lineTo(31, 47)
          ..lineTo(23, 28)
          ..lineTo(39, 39)
          ..lineTo(49, 17)
          ..lineTo(56, 39)
          ..lineTo(77, 25)
          ..lineTo(67, 49)
          ..lineTo(73, 78)
          ..close();
        canvas.drawPath(crown, silhouette);
        canvas.drawPath(crown, outline);
        canvas.drawCircle(const Offset(23, 25), 4.5, Paint()..color = detail);
        canvas.drawCircle(const Offset(50, 14), 4.5, Paint()..color = detail);
        canvas.drawCircle(const Offset(78, 22), 4.5, Paint()..color = detail);
        canvas.drawLine(const Offset(35, 59), const Offset(65, 59), accent);
      case ChessPieceType.king:
        final Path king = Path()
          ..moveTo(27, 79)
          ..lineTo(32, 56)
          ..cubicTo(35, 45, 41, 42, 44, 37)
          ..lineTo(44, 30)
          ..lineTo(35, 30)
          ..lineTo(35, 22)
          ..lineTo(44, 22)
          ..lineTo(44, 12)
          ..lineTo(56, 12)
          ..lineTo(56, 22)
          ..lineTo(65, 22)
          ..lineTo(65, 30)
          ..lineTo(56, 30)
          ..lineTo(56, 37)
          ..cubicTo(59, 42, 65, 45, 68, 56)
          ..lineTo(73, 79)
          ..close();
        canvas.drawPath(king, silhouette);
        canvas.drawPath(king, outline);
        canvas.drawLine(const Offset(37, 61), const Offset(63, 61), accent);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChessPiecePainter oldDelegate) =>
      oldDelegate.piece.side != piece.side ||
      oldDelegate.piece.type != piece.type;
}
