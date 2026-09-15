import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../game/board.dart';
import '../game/game_engine.dart';
import '../game/piece.dart';

class BoardView extends StatelessWidget {
  final GameEngine engine;

  const BoardView({
    super.key,
    required this.engine,
  });

  static const double boardWidth = 800;
  static const double boardHeight = 800;

  static const Map<int, Offset> stationPositions = {
    // Start bottom-right, moving upward.
    0: Offset(690, 690),
    1: Offset(690, 570),
    2: Offset(690, 450),
    3: Offset(690, 330),
    4: Offset(690, 210),
    5: Offset(690, 90),

    // Top row moving left.
    6: Offset(570, 90),
    7: Offset(450, 90),
    8: Offset(330, 90),
    9: Offset(210, 90),
    10: Offset(90, 90),

    // Left side moving down.
    11: Offset(90, 210),
    12: Offset(90, 330),
    13: Offset(90, 450),
    14: Offset(90, 570),
    15: Offset(90, 690),

    // Bottom row moving right.
    16: Offset(210, 690),
    17: Offset(330, 690),
    18: Offset(450, 690),
    19: Offset(570, 690),

    // Bottom-right corner path to center.
    20: Offset(575, 575),
    21: Offset(490, 490),

    // Top-right corner path to center.
    22: Offset(575, 205),
    23: Offset(490, 290),

    // Top-left corner path to center.
    24: Offset(205, 205),
    25: Offset(290, 290),

    // Bottom-left corner path to center.
    26: Offset(205, 575),
    27: Offset(290, 490),

    // Center.
    28: Offset(390, 390),
  };

  static const List<List<int>> visualEdges = [
    // Outer square path.
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [8, 9],
    [9, 10],
    [10, 11],
    [11, 12],
    [12, 13],
    [13, 14],
    [14, 15],
    [15, 16],
    [16, 17],
    [17, 18],
    [18, 19],
    [19, 0],

    // Four corner paths to center, two spaces before center.
    [0, 20],
    [20, 21],
    [21, 28],

    [5, 22],
    [22, 23],
    [23, 28],

    [10, 24],
    [24, 25],
    [25, 28],

    [15, 26],
    [26, 27],
    [27, 28],
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: boardWidth,
          height: boardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: const BoardPainter(),
                ),
              ),
              for (var station = 0; station < Board.stationCount; station++)
                _StationWidget(
                  stationIndex: station,
                  position: stationPositions[station]!,
                  pieces: _piecesAtStation(station),
                ),
              const Positioned(
                left: 642,
                top: 730,
                child: Text(
                  'START',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Piece> _piecesAtStation(int stationIndex) {
    final pieces = <Piece>[];

    for (final player in engine.players) {
      for (final piece in player.pieces) {
        if (piece.stationIndex == stationIndex) {
          pieces.add(piece);
        }
      }
    }

    return pieces;
  }
}

class BoardPainter extends CustomPainter {
  const BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.black87;

    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black87;

    for (final edge in BoardView.visualEdges) {
      final start = BoardView.stationPositions[edge[0]]!;
      final end = BoardView.stationPositions[edge[1]]!;

      final adjustedStart = _shortenLine(start, end, 38);
      final adjustedEnd = _shortenLine(end, start, 38);

      canvas.drawLine(adjustedStart, adjustedEnd, linePaint);
      _drawArrowHead(canvas, adjustedStart, adjustedEnd, arrowPaint);
    }
  }

  Offset _shortenLine(Offset from, Offset to, double amount) {
    final direction = to - from;
    final distance = direction.distance;

    if (distance == 0) {
      return from;
    }

    final unit = direction / distance;
    return from + unit * amount;
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final direction = end - start;

    if (direction.distance == 0) {
      return;
    }

    final angle = math.atan2(direction.dy, direction.dx);

    const arrowLength = 16.0;
    const arrowAngle = math.pi / 7;

    final p1 = Offset(
      end.dx - arrowLength * math.cos(angle - arrowAngle),
      end.dy - arrowLength * math.sin(angle - arrowAngle),
    );

    final p2 = Offset(
      end.dx - arrowLength * math.cos(angle + arrowAngle),
      end.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return false;
  }
}

class _StationWidget extends StatelessWidget {
  final int stationIndex;
  final Offset position;
  final List<Piece> pieces;

  const _StationWidget({
    required this.stationIndex,
    required this.position,
    required this.pieces,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 32,
      top: position.dy - 32,
      child: SizedBox(
        width: 72,
        height: 82,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(1, 3),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$stationIndex',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (pieces.isNotEmpty)
              Positioned(
                bottom: 0,
                child: Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  alignment: WrapAlignment.center,
                  children: pieces.take(8).map((piece) {
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _pieceColor(piece.ownerId),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _pieceColor(int ownerId) {
    switch (ownerId) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}