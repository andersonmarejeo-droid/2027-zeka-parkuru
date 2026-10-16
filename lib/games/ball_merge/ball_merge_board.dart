import 'dart:math' as math;

class MergeOrb {
  MergeOrb({
    required this.id,
    required this.tier,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
  });

  final int id;
  int tier;
  double x;
  double y;
  double vx;
  double vy;

  double get radius => .028 * math.pow(1.18, tier).toDouble();
  double get mass => math.pow(2, tier).toDouble();
  int get value => 1 << tier;
}

class BallMergeEvent {
  const BallMergeEvent({required this.x, required this.y, required this.tier});

  final double x;
  final double y;
  final int tier;
}

/// Small deterministic circle-physics solver. Coordinates use board-width
/// units, making the same physics portable across phones and tablets.
class BallMergeBoard {
  BallMergeBoard({List<MergeOrb> initialOrbs = const <MergeOrb>[]})
    : orbs = List<MergeOrb>.of(initialOrbs);

  final List<MergeOrb> orbs;
  int _nextId = 1;

  bool addOrb({required int tier, required double x, required double y}) {
    final double safeX = x.clamp(.09, .91).toDouble();
    final double safeY = y.clamp(.10, .42).toDouble();
    final MergeOrb candidate = MergeOrb(
      id: _nextId++,
      tier: tier,
      x: safeX,
      y: safeY,
    );
    for (final MergeOrb orb in orbs) {
      final double dx = orb.x - candidate.x;
      final double dy = orb.y - candidate.y;
      if (dx * dx + dy * dy < math.pow(orb.radius + candidate.radius, 2)) {
        return false;
      }
    }
    orbs.add(candidate);
    return true;
  }

  List<BallMergeEvent> step({
    required double deltaSeconds,
    required double worldHeight,
    required double gravity,
    required double flux,
    required double elapsedSeconds,
  }) {
    if (orbs.isEmpty) return const <BallMergeEvent>[];
    final double delta = deltaSeconds.clamp(0, .025).toDouble();
    final double floor = worldHeight - .085;
    final List<BallMergeEvent> events = <BallMergeEvent>[];

    for (final MergeOrb orb in orbs) {
      final double gust =
          flux * math.sin(elapsedSeconds * (1.5 + flux) + orb.y * 3.1);
      orb.vx += gust * delta;
      orb.vy += gravity * delta;
      orb.vx *= math.pow(.999, delta * 60).toDouble();
      orb.vy *= math.pow(.9995, delta * 60).toDouble();
      orb.x += orb.vx * delta;
      orb.y += orb.vy * delta;

      final double left = .085 + orb.radius;
      final double right = .915 - orb.radius;
      if (orb.x < left) {
        orb.x = left;
        orb.vx = orb.vx.abs() * .38;
      } else if (orb.x > right) {
        orb.x = right;
        orb.vx = -orb.vx.abs() * .38;
      }
      if (orb.y + orb.radius > floor) {
        orb.y = floor - orb.radius;
        if (orb.vy > .055) orb.vy = -orb.vy * .20;
        if (orb.vy.abs() < .055) orb.vy = 0;
        orb.vx *= .88;
        if (orb.vx.abs() < .018) orb.vx = 0;
      }
    }

    // A pair can only fuse once per step. Restarting after a fusion permits
    // chain reactions while the hard cap keeps malformed piles bounded.
    for (int chain = 0; chain < 8; chain++) {
      bool fused = false;
      for (int firstIndex = 0;
          firstIndex < orbs.length && !fused;
          firstIndex++) {
        for (int secondIndex = firstIndex + 1;
            secondIndex < orbs.length;
            secondIndex++) {
          final MergeOrb first = orbs[firstIndex];
          final MergeOrb second = orbs[secondIndex];
          final double dx = second.x - first.x;
          final double dy = second.y - first.y;
          final double distance = math.sqrt(dx * dx + dy * dy);
          final double minimum = first.radius + second.radius;
          if (distance >= minimum || distance == 0) continue;

          final double nx = dx / distance;
          final double ny = dy / distance;
          if (first.tier == second.tier && first.tier < 12) {
            final double firstMass = first.mass;
            final double secondMass = second.mass;
            final double totalMass = firstMass + secondMass;
            final MergeOrb merged = MergeOrb(
              id: _nextId++,
              tier: first.tier + 1,
              x: (first.x * firstMass + second.x * secondMass) / totalMass,
              y: (first.y * firstMass + second.y * secondMass) / totalMass,
              vx: (first.vx * firstMass + second.vx * secondMass) / totalMass,
              vy: (first.vy * firstMass + second.vy * secondMass) / totalMass -
                  .06,
            );
            orbs
              ..removeAt(secondIndex)
              ..removeAt(firstIndex)
              ..add(merged);
            events.add(
              BallMergeEvent(x: merged.x, y: merged.y, tier: merged.tier),
            );
            fused = true;
            break;
          }

          final double overlap = minimum - distance;
          final double firstShare = second.mass / (first.mass + second.mass);
          final double secondShare = first.mass / (first.mass + second.mass);
          first.x -= nx * overlap * firstShare;
          first.y -= ny * overlap * firstShare;
          second.x += nx * overlap * secondShare;
          second.y += ny * overlap * secondShare;
          final double relativeVelocity =
              (second.vx - first.vx) * nx + (second.vy - first.vy) * ny;
          if (relativeVelocity < 0) {
            final double impulse = -relativeVelocity * .24;
            first.vx -= impulse * nx * firstShare;
            first.vy -= impulse * ny * firstShare;
            second.vx += impulse * nx * secondShare;
            second.vy += impulse * ny * secondShare;
          }
        }
      }
      if (!fused) break;
    }
    return events;
  }

  bool get isSettled => orbs.every(
    (MergeOrb orb) => orb.vx.abs() < .035 && orb.vy.abs() < .035,
  );

  bool isCrowded(double worldHeight) => orbs.any(
    (MergeOrb orb) => orb.y - orb.radius < math.min(.24, worldHeight * .27),
  );
}
