import 'dart:math' as math;

/// Minimal pure-Dart 3D vector for solar directions and wind fields in `voxsky`.
final class SkyVec3 {
  final double x;
  final double y;
  final double z;

  const SkyVec3(this.x, this.y, this.z);

  static const SkyVec3 zero = SkyVec3(0.0, 0.0, 0.0);
  static const SkyVec3 unitX = SkyVec3(1.0, 0.0, 0.0);
  static const SkyVec3 unitY = SkyVec3(0.0, 1.0, 0.0);
  static const SkyVec3 unitZ = SkyVec3(0.0, 0.0, 1.0);

  SkyVec3 operator +(SkyVec3 o) => SkyVec3(x + o.x, y + o.y, z + o.z);
  SkyVec3 operator -(SkyVec3 o) => SkyVec3(x - o.x, y - o.y, z - o.z);
  SkyVec3 operator -() => SkyVec3(-x, -y, -z);
  SkyVec3 operator *(double s) => SkyVec3(x * s, y * s, z * s);
  SkyVec3 operator /(double s) => SkyVec3(x / s, y / s, z / s);

  double dot(SkyVec3 o) => x * o.x + y * o.y + z * o.z;

  SkyVec3 cross(SkyVec3 o) => SkyVec3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  double get lengthSquared => x * x + y * y + z * z;
  double get length => math.sqrt(lengthSquared);

  SkyVec3 get normalized {
    final len = length;
    if (len <= 1e-12) return SkyVec3.unitY;
    return SkyVec3(x / len, y / len, z / len);
  }

  static SkyVec3 lerp(SkyVec3 a, SkyVec3 b, double t) => SkyVec3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t,
      );
}

/// Linear RGB atmospheric/lighting color triple in `[0.0, +inf)` for `voxsky`.
final class SkyColor {
  final double r;
  final double g;
  final double b;

  const SkyColor(this.r, this.g, this.b);

  static const SkyColor black = SkyColor(0.0, 0.0, 0.0);
  static const SkyColor white = SkyColor(1.0, 1.0, 1.0);

  SkyColor operator +(SkyColor o) => SkyColor(r + o.r, g + o.g, b + o.b);
  SkyColor operator *(double s) => SkyColor(r * s, g * s, b * s);

  SkyColor clamp01() => SkyColor(
        r.clamp(0.0, 1.0),
        g.clamp(0.0, 1.0),
        b.clamp(0.0, 1.0),
      );

  static SkyColor lerp(SkyColor a, SkyColor b, double t) => SkyColor(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t,
      );

  @override
  String toString() =>
      'SkyColor(${r.toStringAsFixed(3)}, ${g.toStringAsFixed(3)}, ${b.toStringAsFixed(3)})';
}
