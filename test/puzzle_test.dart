import 'dart:math' as math;

import 'package:slide_puzzle/src/puzzle.dart';
import 'package:test/test.dart';

final _rnd = math.Random();

Puzzle _ordered(int width, int height, {int offset = 0}) {
  final length = width * height;
  final list = List<int>.generate(length, (i) {
    return (i - offset) % length;
  });
  return Puzzle.raw(width, list);
}

// printOnFailure trims input – which is weird – so adding a leading line
void _printPuzzleOnFailure(Puzzle puzzle) {
  printOnFailure('* here is the puzzle\n$puzzle');
}

void main() {
  test('must be at least 3 x 3', () {
    expect(() => Puzzle.raw(3, []), throwsArgumentError);
    expect(() => Puzzle.raw(3, [0, 1, 2]), throwsArgumentError);
    expect(() => Puzzle.raw(3, [0, 1, 2, 3, 4, 5]), throwsArgumentError);
  });

  test('initial values must be correct', () {
    expect(
        () => Puzzle.raw(3, [0, 1, 2, 3, 4, 5, 6, 7, 7]), throwsArgumentError);

    final width = 3, height = 3;

    final puzzle = _ordered(width, height);
    expect(puzzle.width, width);
    expect(puzzle.height, height);
    expect(puzzle.length, width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        expect(puzzle.value(x, y), x + y * width);
      }
    }
  });

  test('toString', () {
    final puzzle = _ordered(4, 4);
    _printPuzzleOnFailure(puzzle);
    expect(puzzle.toString(), '''
 0  1  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15''');
  });

  group('click', () {
    bool doClick(Puzzle puzzle, int x, int y) {
      final startCount = puzzle.clickCount;
      final startString = puzzle.toString();
      final clickResult = puzzle.click(x, y);
      if (clickResult) {
        expect(puzzle.clickCount, startCount + 1);
        expect(puzzle.toString(), isNot(startString));
      } else {
        expect(puzzle.clickCount, startCount);
        expect(puzzle.toString(), startString);
      }
      return clickResult;
    }

    test('click on zero is a noop', () {
      var puzzle = _ordered(4, 4);
      expect(puzzle.value(0, 0), 0);
      expect(doClick(puzzle, 0, 0), isFalse);

      puzzle = _ordered(3, 3, offset: 2);
      expect(puzzle.toString(), '''
7 8 0
1 2 3
4 5 6''');

      expect(puzzle.value(2, 0), 0);
      expect(doClick(puzzle, 2, 0), isFalse);

      for (var i = 0; i < 10; i++) {
        puzzle = Puzzle(5, 5);
        final zeroLocation = puzzle.coordinatesOf(0);
        expect(doClick(puzzle, zeroLocation.x, zeroLocation.y), isFalse);
      }
    });

    test('click on a cell not aligned with zero is a noop', () {
      var puzzle = _ordered(4, 4);
      expect(puzzle.value(1, 1), 5);
      expect(doClick(puzzle, 1, 1), isFalse);

      puzzle = _ordered(3, 3, offset: 2);
      expect(puzzle.value(0, 1), 1);
      expect(doClick(puzzle, 0, 1), isFalse);

      for (var i = 0; i < 10; i++) {
        puzzle = Puzzle(5, 5);
        final zeroLocation = puzzle.coordinatesOf(0);

        for (var j = 0; j < 10; j++) {
          math.Point<int> randomPoint;
          do {
            randomPoint = math.Point(
                _rnd.nextInt(puzzle.width), _rnd.nextInt(puzzle.height));
          } while (randomPoint.x == zeroLocation.x ||
              randomPoint.y == zeroLocation.y);

          expect(doClick(puzzle, randomPoint.x, randomPoint.y), isFalse);
        }
      }
    });

    test('click to shift', () {
      final puzzle = _ordered(4, 4);
      expect(puzzle.incorrectTiles, 15);

      expect(puzzle.value(1, 0), 1);
      expect(doClick(puzzle, 1, 0), isTrue);
      expect(puzzle.toString(), '''
 1  0  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15''');

      expect(doClick(puzzle, 1, 0), isFalse);
      expect(doClick(puzzle, 0, 0), isTrue);
      expect(puzzle.toString(), '''
 0  1  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15''');

      expect(doClick(puzzle, 0, 0), isFalse);
      expect(doClick(puzzle, 0, 1), isTrue);
      expect(puzzle.toString(), '''
 4  1  2  3
 0  5  6  7
 8  9 10 11
12 13 14 15''');

      expect(doClick(puzzle, 0, 1), isFalse);
      expect(doClick(puzzle, 0, 0), isTrue);
      expect(puzzle.toString(), '''
 0  1  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15''');

      expect(doClick(puzzle, 0, 0), isFalse);
      expect(doClick(puzzle, 3, 0), isTrue);
      expect(puzzle.toString(), '''
 1  2  3  0
 4  5  6  7
 8  9 10 11
12 13 14 15''');

      expect(puzzle.incorrectTiles, 12);
      expect(doClick(puzzle, 3, 0), isFalse);
      expect(doClick(puzzle, 3, 3), isTrue);
      expect(puzzle.toString(), '''
 1  2  3  7
 4  5  6 11
 8  9 10 15
12 13 14  0''');

      expect(doClick(puzzle, 3, 3), isFalse);
      expect(doClick(puzzle, 0, 3), isTrue);
      expect(puzzle.toString(), '''
 1  2  3  7
 4  5  6 11
 8  9 10 15
 0 12 13 14''');

      expect(doClick(puzzle, 0, 3), isFalse);
      expect(doClick(puzzle, 0, 0), isTrue);
      expect(puzzle.toString(), '''
 0  2  3  7
 1  5  6 11
 4  9 10 15
 8 12 13 14''');

      expect(puzzle.incorrectTiles, 13);
      expect(puzzle.clickCount, 8);
    });
  });

  test('new puzzles should have all tiles in incorrect positions', () {
    for (var i = 0; i < 100; i++) {
      final puzzle = Puzzle(4, 4);
      expect(puzzle.incorrectTiles, 15);
    }
  });

  test('reset', () {
    final width = 4, height = 4;
    final tileCount = (width * height) - 1;
    final puzzle = Puzzle(width, height);
    expect(puzzle.incorrectTiles, tileCount);

    do {
      puzzle.click(_rnd.nextInt(puzzle.width), _rnd.nextInt(puzzle.height));
    } while (puzzle.incorrectTiles == tileCount);

    expect(puzzle.incorrectTiles, lessThan(tileCount));
    expect(puzzle.clickCount, greaterThan(0));

    puzzle.reset();

    expect(puzzle.incorrectTiles, tileCount);
    expect(puzzle.clickCount, 0);
  });
}
