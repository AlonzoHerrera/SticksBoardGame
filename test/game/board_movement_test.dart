import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/game/board.dart';
import 'package:homework1game/game/game_rule_exception.dart';

void main() {
  late Board board;

  setUp(() {
    board = Board();
  });

  group('Board structure', () {
    test('contains exactly 29 visible stations', () {
      expect(board.connections.length, Board.stationCount);
    });

    test('finish progress is not a visible station', () {
      expect(Board.finishProgress, 29);
      expect(board.isValidStation(Board.finishProgress), isFalse);
      expect(board.isFinishProgress(Board.finishProgress), isTrue);
    });

    test('only stations 5, 10, 15, and 28 branch', () {
      expect(board.neighborsOf(5), equals(<int>[6, 22]));
      expect(board.neighborsOf(10), equals(<int>[11, 24]));
      expect(board.neighborsOf(15), equals(<int>[16, 26]));
      expect(board.neighborsOf(28), equals(<int>[19, 20]));
    });
  });

  group('Movement validation', () {
    test('rejects a move value below 1', () {
      expect(
        () => board.destinationsAfterMove(0, 0),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('rejects a move value above 5', () {
      expect(
        () => board.destinationsAfterMove(0, 6),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('rejects progress below inactive state', () {
      expect(
        () => board.destinationsAfterMove(-2, 1),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('finished pieces cannot move again', () {
      expect(
        () => board.destinationsAfterMove(Board.finishProgress, 1),
        throwsA(isA<GameRuleException>()),
      );
    });
  });

  group('Inactive piece movement', () {
    test('throw of 1 places an inactive piece on station 0', () {
      expect(board.destinationsAfterMove(-1, 1), equals(<int>[0]));
    });

    test('throw of 2 places an inactive piece on station 1', () {
      expect(board.destinationsAfterMove(-1, 2), equals(<int>[1]));
    });

    test('throw of 5 places an inactive piece on station 4', () {
      expect(board.destinationsAfterMove(-1, 5), equals(<int>[4]));
    });

    test('inactive piece cannot enter a diagonal from start', () {
      expect(board.destinationsAfterMove(-1, 5), isNot(contains(22)));
    });
  });

  group('Normal outside movement', () {
    test('station 0 plus 1 reaches station 1', () {
      expect(board.destinationsAfterMove(0, 1), equals(<int>[1]));
    });

    test('station 1 plus 4 reaches station 5', () {
      expect(board.destinationsAfterMove(1, 4), equals(<int>[5]));
    });

    test('station 6 plus 4 reaches station 10', () {
      expect(board.destinationsAfterMove(6, 4), equals(<int>[10]));
    });

    test('station 11 plus 4 reaches station 15', () {
      expect(board.destinationsAfterMove(11, 4), equals(<int>[15]));
    });

    test('station 16 plus 3 reaches station 19', () {
      expect(board.destinationsAfterMove(16, 3), equals(<int>[19]));
    });
  });

  group('Branches only open when movement starts there', () {
    test('station 4 plus 5 reaches only station 9', () {
      expect(board.destinationsAfterMove(4, 5), equals(<int>[9]));
    });

    test('passing station 5 does not open its diagonal', () {
      final destinations = board.destinationsAfterMove(4, 5);

      expect(destinations, equals(<int>[9]));
      expect(destinations, isNot(contains(22)));
      expect(destinations, isNot(contains(28)));
      expect(destinations, isNot(contains(Board.finishProgress)));
    });

    test('passing station 10 does not open its diagonal', () {
      expect(board.destinationsAfterMove(9, 3), equals(<int>[12]));
    });

    test('passing station 15 does not open its diagonal', () {
      expect(board.destinationsAfterMove(14, 4), equals(<int>[18]));
    });
  });

  group('Station 5 route choice', () {
    test('throw of 1 offers stations 6 and 22', () {
      expect(board.destinationsAfterMove(5, 1), equals(<int>[6, 22]));
    });

    test('throw of 2 offers stations 7 and 23', () {
      expect(board.destinationsAfterMove(5, 2), equals(<int>[7, 23]));
    });

    test('throw of 3 offers station 8 and station 28', () {
      expect(board.destinationsAfterMove(5, 3), equals(<int>[8, 28]));
    });

    test('station 5 plus 3 cannot cross the finish', () {
      expect(
        board.destinationsAfterMove(5, 3),
        isNot(contains(Board.finishProgress)),
      );
    });

    test('throw of 4 continues outside or through the center', () {
      expect(
        board.destinationsAfterMove(5, 4),
        equals(<int>[9, 27]),
      );
    });

    test('throw of 5 reaches station 10 or station 26', () {
      expect(
        board.destinationsAfterMove(5, 5),
        equals(<int>[10, 26]),
      );
    });
  });

  group('Station 10 route choice', () {
    test('throw of 1 offers stations 11 and 24', () {
      expect(board.destinationsAfterMove(10, 1), equals(<int>[11, 24]));
    });

    test('throw of 2 offers stations 12 and 25', () {
      expect(board.destinationsAfterMove(10, 2), equals(<int>[12, 25]));
    });

    test('throw of 3 offers station 13 and station 28', () {
      expect(board.destinationsAfterMove(10, 3), equals(<int>[13, 28]));
    });

    test('throw of 4 continues outside or through the center', () {
      expect(
        board.destinationsAfterMove(10, 4),
        equals(<int>[14, 21]),
      );
    });

    test('throw of 5 reaches station 15 or station 20', () {
      expect(
        board.destinationsAfterMove(10, 5),
        equals(<int>[15, 20]),
      );
    });
  });

  group('Station 15 route choice', () {
    test('throw of 1 offers stations 16 and 26', () {
      expect(board.destinationsAfterMove(15, 1), equals(<int>[16, 26]));
    });

    test('throw of 2 offers stations 17 and 27', () {
      expect(board.destinationsAfterMove(15, 2), equals(<int>[17, 27]));
    });

    test('throw of 3 offers station 18 and station 28', () {
      expect(board.destinationsAfterMove(15, 3), equals(<int>[18, 28]));
    });

    test('throw of 4 reaches station 19 or station 23', () {
      expect(
        board.destinationsAfterMove(15, 4),
        equals(<int>[19, 23]),
      );
    });

    test('throw of 5 reaches station 22 or crosses the finish', () {
      expect(
        board.destinationsAfterMove(15, 5),
        equals(<int>[22, Board.finishProgress]),
      );
    });
  });

  group('Diagonal routes continue through station 28', () {
    test('station 22 plus 1 reaches station 23', () {
      expect(board.destinationsAfterMove(22, 1), equals(<int>[23]));
    });

    test('station 22 plus 2 reaches station 28', () {
      expect(board.destinationsAfterMove(22, 2), equals(<int>[28]));
    });

    test('station 22 plus 3 continues through center to station 27', () {
      expect(
        board.destinationsAfterMove(22, 3),
        equals(<int>[27]),
      );
    });

    test('station 23 plus 1 reaches station 28', () {
      expect(board.destinationsAfterMove(23, 1), equals(<int>[28]));
    });

    test('station 23 plus 2 continues through center to station 27', () {
      expect(
        board.destinationsAfterMove(23, 2),
        equals(<int>[27]),
      );
    });

    test('station 23 plus 3 reaches station 26', () {
      expect(
        board.destinationsAfterMove(23, 3),
        equals(<int>[26]),
      );
    });

    test('station 24 plus 2 reaches station 28', () {
      expect(board.destinationsAfterMove(24, 2), equals(<int>[28]));
    });

    test('station 25 plus 1 reaches station 28', () {
      expect(board.destinationsAfterMove(25, 1), equals(<int>[28]));
    });

    test('station 26 plus 2 reaches station 28', () {
      expect(board.destinationsAfterMove(26, 2), equals(<int>[28]));
    });

    test('station 27 plus 1 reaches station 28', () {
      expect(board.destinationsAfterMove(27, 1), equals(<int>[28]));
    });
  });

  group('Movement beginning at station 28', () {
    test('throw of 1 offers stations 19 and 20', () {
      expect(board.destinationsAfterMove(28, 1), equals(<int>[19, 20]));
    });

    test('throw of 2 reaches station 21', () {
      expect(board.destinationsAfterMove(28, 2), equals(<int>[21]));
    });

    test('throw of 3 offers station 19 or finish', () {
      expect(
        board.destinationsAfterMove(28, 3),
        equals(<int>[19, Board.finishProgress]),
      );
    });

    test('throw of 4 crosses the finish', () {
      expect(
        board.destinationsAfterMove(28, 4),
        equals(<int>[Board.finishProgress]),
      );
    });

    test('throw of 5 crosses the finish', () {
      expect(
        board.destinationsAfterMove(28, 5),
        equals(<int>[Board.finishProgress]),
      );
    });
  });

  group('Finish movement', () {
    test('station 19 plus 1 crosses the finish', () {
      expect(
        board.destinationsAfterMove(19, 1),
        equals(<int>[Board.finishProgress]),
      );
    });

    test('station 19 allows finish overshoot', () {
      expect(
        board.destinationsAfterMove(19, 5),
        equals(<int>[Board.finishProgress]),
      );
    });

    test('station 18 plus 2 crosses the finish', () {
      expect(
        board.destinationsAfterMove(18, 2),
        equals(<int>[Board.finishProgress]),
      );
    });

    test('station 17 plus 3 crosses the finish', () {
      expect(
        board.destinationsAfterMove(17, 3),
        equals(<int>[Board.finishProgress]),
      );
    });

    test('station 16 plus 4 crosses the finish', () {
      expect(
        board.destinationsAfterMove(16, 4),
        equals(<int>[Board.finishProgress]),
      );
    });
  });

  group('nextProgress', () {
    test('returns a destination when only one route exists', () {
      expect(board.nextProgress(4, 5), 9);
    });

    test('throws when multiple destinations exist', () {
      expect(
        () => board.nextProgress(5, 1),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('returns station 26 after crossing the center', () {
      expect(board.nextProgress(23, 3), 26);
    });
  });

  group('Station conversion', () {
    test('inactive progress has no visible station', () {
      expect(board.stationForProgress(-1), isNull);
    });

    test('finished progress has no visible station', () {
      expect(board.stationForProgress(Board.finishProgress), isNull);
    });

    test('normal progress returns the same station', () {
      expect(board.stationForProgress(15), 15);
    });

    test('invalid progress throws', () {
      expect(
        () => board.stationForProgress(30),
        throwsA(isA<GameRuleException>()),
      );
    });
  });
}