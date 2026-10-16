import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/ball_merge/ball_merge_board.dart';

void main() {
  group('Ball merge chamber physics', () {
    test('matching touching orbs fuse into the next tier exactly once', () {
      final MergeOrb left = MergeOrb(id: 1, tier: 1, x: .48, y: .55);
      final MergeOrb right = MergeOrb(id: 2, tier: 1, x: .48 + left.radius * 1.8, y: .55);
      final BallMergeBoard board = BallMergeBoard(initialOrbs: <MergeOrb>[left, right]);

      final List<BallMergeEvent> events = board.step(
        deltaSeconds: .016,
        worldHeight: 1.2,
        gravity: 3,
        flux: 0,
        elapsedSeconds: 0,
      );

      expect(events, hasLength(1));
      expect(events.single.tier, 2);
      expect(board.orbs, hasLength(1));
      expect(board.orbs.single.value, 4);
    });

    test('different values collide without fusing and walls contain the stack', () {
      final BallMergeBoard board = BallMergeBoard(
        initialOrbs: <MergeOrb>[
          MergeOrb(id: 1, tier: 0, x: .13, y: .45, vx: -1.4),
          MergeOrb(id: 2, tier: 1, x: .18, y: .45),
        ],
      );
      final List<BallMergeEvent> events = board.step(
        deltaSeconds: .02,
        worldHeight: 1.2,
        gravity: 3,
        flux: 1.1,
        elapsedSeconds: .7,
      );
      expect(events, isEmpty);
      expect(board.orbs, hasLength(2));
      expect(board.orbs.first.x, greaterThanOrEqualTo(.085 + board.orbs.first.radius));
      expect(board.orbs.every((MergeOrb orb) => orb.y.isFinite && orb.x.isFinite), isTrue);
    });

    test('drop is rejected when the chute is physically occupied', () {
      final BallMergeBoard board = BallMergeBoard();
      expect(board.addOrb(tier: 0, x: .5, y: .16), isTrue);
      expect(board.addOrb(tier: 1, x: .5, y: .16), isFalse);
      expect(board.orbs, hasLength(1));
    });
  });
}
