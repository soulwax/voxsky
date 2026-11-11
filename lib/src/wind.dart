import 'dart:math' as math;

import 'math.dart';

/// Spatial wind effector mode for local [WindZoneDef] volumes.
enum WindZoneShape { directional, sphericalRadial, sphericalVortex }

/// Localized 3D wind field volume overriding or boosting global atmospheric wind.
final class WindZoneDef {
  final String id;
  SkyVec3 position;
  SkyVec3 direction;
  double radius;
  double strength;
  double turbulence;
  WindZoneShape shape;
  bool enabled;

  WindZoneDef({
    required this.id,
    this.position = SkyVec3.zero,
    SkyVec3 direction = const SkyVec3(1.0, 0.0, 0.3),
    this.radius = 10.0,
    this.strength = 6.0,
    this.turbulence = 0.5,
    this.shape = WindZoneShape.directional,
    this.enabled = true,
  }) : direction = direction.normalized;
}

/// Evaluates continuous harmonic wind gusts + localized spatial [WindZoneDef] impulses.
final class WindFieldSampler {
  SkyVec3 baseDirection;
  double baseSpeed;
  double gustStrength;
  double gustFrequency;
  double turbulenceScale;
  double timeSeconds = 0.0;

  final List<WindZoneDef> zones = [];

  WindFieldSampler({
    SkyVec3 baseDirection = const SkyVec3(1.0, 0.0, 0.25),
    this.baseSpeed = 3.0,
    this.gustStrength = 1.2,
    this.gustFrequency = 0.65,
    this.turbulenceScale = 0.12,
  }) : baseDirection = baseDirection.normalized;

  void advance(double dt) {
    if (dt > 0.0) timeSeconds += dt;
  }

  /// Samples instantaneous 3D wind velocity vector (`m/s`) at [worldPosition].
  SkyVec3 sampleWind(SkyVec3 worldPosition, {double? timeOverride}) {
    final t = timeOverride ?? timeSeconds;
    final phase = worldPosition.x * turbulenceScale +
        worldPosition.z * (turbulenceScale * 0.7) -
        t * gustFrequency * math.pi * 2.0;

    final gustWave = 0.5 * math.sin(phase) + 0.35 * math.cos(phase * 1.73 + 0.9);
    final dir = baseDirection.normalized;
    var wind = dir * math.max(0.0, baseSpeed + gustWave * gustStrength);

    // Subtle orthogonal turbulence eddy.
    final lateral = SkyVec3(-dir.z, 0.15, dir.x).normalized;
    wind += lateral * (math.sin(phase * 1.3 + worldPosition.z * 0.2) * gustStrength * 0.35);

    // Accumulate local spatial wind zones with smooth radial quadratic falloff.
    for (final zone in zones) {
      if (!zone.enabled || zone.radius <= 1e-4) continue;
      final rel = worldPosition - zone.position;
      final dist = rel.length;
      if (dist >= zone.radius) continue;

      final falloff = 1.0 - (dist / zone.radius);
      final weight = falloff * falloff * (3.0 - 2.0 * falloff);
      final pulse = 1.0 + math.sin(t * 5.0 + dist) * 0.15 * zone.turbulence;

      switch (zone.shape) {
        case WindZoneShape.directional:
          wind += zone.direction.normalized * (zone.strength * weight * pulse);
        case WindZoneShape.sphericalRadial:
          final outDir = dist > 1e-5 ? (rel / dist) : SkyVec3.unitY;
          wind += outDir * (zone.strength * weight * pulse);
        case WindZoneShape.sphericalVortex:
          final tangent = SkyVec3(-rel.z, 0.25 * zone.radius, rel.x).normalized;
          wind += tangent * (zone.strength * weight * pulse);
      }
    }

    return wind;
  }
}
