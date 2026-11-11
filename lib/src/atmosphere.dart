import 'dart:math' as math;

import 'math.dart';

/// Atmospheric sky dome & lighting color keyframe indexed by `sunElevationRadians`.
final class SkyRampStop {
  final double sunElevationRadians;
  final SkyColor zenithColor;
  final SkyColor horizonColor;
  final SkyColor groundColor;
  final SkyColor sunColor;
  final SkyColor ambientColor;
  final SkyColor fogColor;
  final double sunIntensity;
  final double ambientIntensity;
  final double fogDensity;
  final double starVisibility01;

  const SkyRampStop({
    required this.sunElevationRadians,
    required this.zenithColor,
    required this.horizonColor,
    required this.groundColor,
    required this.sunColor,
    required this.ambientColor,
    required this.fogColor,
    required this.sunIntensity,
    required this.ambientIntensity,
    required this.fogDensity,
    required this.starVisibility01,
  });

  SkyRampStop lerpTo(SkyRampStop o, double t) {
    final s = t.clamp(0.0, 1.0);
    return SkyRampStop(
      sunElevationRadians:
          sunElevationRadians + (o.sunElevationRadians - sunElevationRadians) * s,
      zenithColor: SkyColor.lerp(zenithColor, o.zenithColor, s),
      horizonColor: SkyColor.lerp(horizonColor, o.horizonColor, s),
      groundColor: SkyColor.lerp(groundColor, o.groundColor, s),
      sunColor: SkyColor.lerp(sunColor, o.sunColor, s),
      ambientColor: SkyColor.lerp(ambientColor, o.ambientColor, s),
      fogColor: SkyColor.lerp(fogColor, o.fogColor, s),
      sunIntensity: sunIntensity + (o.sunIntensity - sunIntensity) * s,
      ambientIntensity: ambientIntensity + (o.ambientIntensity - ambientIntensity) * s,
      fogDensity: fogDensity + (o.fogDensity - fogDensity) * s,
      starVisibility01:
          starVisibility01 + (o.starVisibility01 - starVisibility01) * s,
    );
  }
}

/// Evaluates smoothly interpolated sky & lighting curves from solar elevation.
final class AtmosphericSkyRamp {
  final List<SkyRampStop> stops;

  AtmosphericSkyRamp({required List<SkyRampStop> stops})
      : stops = List<SkyRampStop>.from(stops)
          ..sort((a, b) => a.sunElevationRadians.compareTo(b.sunElevationRadians)) {
    if (stops.isEmpty) {
      throw ArgumentError('AtmosphericSkyRamp requires at least 1 stop');
    }
  }

  /// Clear-sky Earth-like diurnal color curve spanning midnight, twilight, golden hour, and noon.
  factory AtmosphericSkyRamp.earthDefault() => AtmosphericSkyRamp(
        stops: const [
          SkyRampStop(
            sunElevationRadians: -0.35,
            zenithColor: SkyColor(0.012, 0.018, 0.045),
            horizonColor: SkyColor(0.032, 0.045, 0.090),
            groundColor: SkyColor(0.015, 0.018, 0.028),
            sunColor: SkyColor(0.32, 0.42, 0.65),
            ambientColor: SkyColor(0.07, 0.10, 0.18),
            fogColor: SkyColor(0.025, 0.035, 0.068),
            sunIntensity: 0.22,
            ambientIntensity: 0.25,
            fogDensity: 0.008,
            starVisibility01: 1.0,
          ),
          SkyRampStop(
            sunElevationRadians: -0.06,
            zenithColor: SkyColor(0.07, 0.10, 0.24),
            horizonColor: SkyColor(0.45, 0.22, 0.24),
            groundColor: SkyColor(0.06, 0.05, 0.06),
            sunColor: SkyColor(0.85, 0.36, 0.22),
            ambientColor: SkyColor(0.20, 0.16, 0.24),
            fogColor: SkyColor(0.34, 0.22, 0.24),
            sunIntensity: 0.45,
            ambientIntensity: 0.42,
            fogDensity: 0.006,
            starVisibility01: 0.55,
          ),
          SkyRampStop(
            sunElevationRadians: 0.06,
            zenithColor: SkyColor(0.14, 0.32, 0.62),
            horizonColor: SkyColor(0.95, 0.56, 0.32),
            groundColor: SkyColor(0.20, 0.16, 0.14),
            sunColor: SkyColor(1.0, 0.72, 0.42),
            ambientColor: SkyColor(0.34, 0.30, 0.34),
            fogColor: SkyColor(0.82, 0.56, 0.42),
            sunIntensity: 1.35,
            ambientIntensity: 0.65,
            fogDensity: 0.005,
            starVisibility01: 0.05,
          ),
          SkyRampStop(
            sunElevationRadians: 0.30,
            zenithColor: SkyColor(0.14, 0.42, 0.82),
            horizonColor: SkyColor(0.58, 0.76, 0.94),
            groundColor: SkyColor(0.24, 0.26, 0.22),
            sunColor: SkyColor(1.0, 0.94, 0.84),
            ambientColor: SkyColor(0.36, 0.44, 0.54),
            fogColor: SkyColor(0.62, 0.74, 0.88),
            sunIntensity: 2.35,
            ambientIntensity: 0.88,
            fogDensity: 0.003,
            starVisibility01: 0.0,
          ),
          SkyRampStop(
            sunElevationRadians: 1.05,
            zenithColor: SkyColor(0.10, 0.38, 0.85),
            horizonColor: SkyColor(0.52, 0.74, 0.96),
            groundColor: SkyColor(0.28, 0.30, 0.26),
            sunColor: SkyColor(1.0, 0.98, 0.94),
            ambientColor: SkyColor(0.42, 0.50, 0.60),
            fogColor: SkyColor(0.68, 0.80, 0.92),
            sunIntensity: 2.85,
            ambientIntensity: 1.0,
            fogDensity: 0.0022,
            starVisibility01: 0.0,
          ),
        ],
      );

  SkyRampStop evaluate(double sunElevationRadians) {
    if (stops.length == 1 || sunElevationRadians <= stops.first.sunElevationRadians) {
      return stops.first;
    }
    if (sunElevationRadians >= stops.last.sunElevationRadians) {
      return stops.last;
    }
    for (var i = 0; i < stops.length - 1; i++) {
      final a = stops[i];
      final b = stops[i + 1];
      if (sunElevationRadians >= a.sunElevationRadians &&
          sunElevationRadians <= b.sunElevationRadians) {
        final span = math.max(1e-6, b.sunElevationRadians - a.sunElevationRadians);
        final rawT = (sunElevationRadians - a.sunElevationRadians) / span;
        final smoothT = rawT * rawT * (3.0 - 2.0 * rawT);
        return a.lerpTo(b, smoothT);
      }
    }
    return stops.last;
  }
}
