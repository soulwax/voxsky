import 'dart:math' as math;

import 'math.dart';

/// Standard weather regimes supported by [WeatherController].
enum WeatherKind { clear, overcast, rain, storm, snow }

/// Target optical and surface parameters for a weather regime.
final class WeatherPreset {
  final double cloudCoverage01;
  final double precipitationRate01;
  final double rainFraction01;
  final double snowFraction01;
  final double fogMultiplier;
  final double sunAttenuation01;
  final double ambientScale01;
  final double targetWindSpeed;
  final double windGustiness;
  final double wetnessRatePerSec;
  final double snowRatePerSec;
  final double lightningRateHz;
  final SkyColor tintColor;

  const WeatherPreset({
    required this.cloudCoverage01,
    required this.precipitationRate01,
    required this.rainFraction01,
    required this.snowFraction01,
    required this.fogMultiplier,
    required this.sunAttenuation01,
    required this.ambientScale01,
    required this.targetWindSpeed,
    required this.windGustiness,
    required this.wetnessRatePerSec,
    required this.snowRatePerSec,
    required this.lightningRateHz,
    required this.tintColor,
  });

  static WeatherPreset forKind(WeatherKind kind) => switch (kind) {
        WeatherKind.clear => const WeatherPreset(
            cloudCoverage01: 0.15,
            precipitationRate01: 0.0,
            rainFraction01: 0.0,
            snowFraction01: 0.0,
            fogMultiplier: 1.0,
            sunAttenuation01: 1.0,
            ambientScale01: 1.0,
            targetWindSpeed: 3.0,
            windGustiness: 0.8,
            wetnessRatePerSec: -0.04,
            snowRatePerSec: -0.025,
            lightningRateHz: 0.0,
            tintColor: SkyColor(1.0, 1.0, 1.0),
          ),
        WeatherKind.overcast => const WeatherPreset(
            cloudCoverage01: 0.82,
            precipitationRate01: 0.0,
            rainFraction01: 0.0,
            snowFraction01: 0.0,
            fogMultiplier: 1.85,
            sunAttenuation01: 0.48,
            ambientScale01: 0.78,
            targetWindSpeed: 5.5,
            windGustiness: 1.4,
            wetnessRatePerSec: -0.01,
            snowRatePerSec: -0.01,
            lightningRateHz: 0.0,
            tintColor: SkyColor(0.76, 0.80, 0.85),
          ),
        WeatherKind.rain => const WeatherPreset(
            cloudCoverage01: 0.94,
            precipitationRate01: 0.7,
            rainFraction01: 1.0,
            snowFraction01: 0.0,
            fogMultiplier: 2.6,
            sunAttenuation01: 0.32,
            ambientScale01: 0.65,
            targetWindSpeed: 8.5,
            windGustiness: 2.5,
            wetnessRatePerSec: 0.18,
            snowRatePerSec: -0.08,
            lightningRateHz: 0.02,
            tintColor: SkyColor(0.62, 0.68, 0.76),
          ),
        WeatherKind.storm => const WeatherPreset(
            cloudCoverage01: 1.0,
            precipitationRate01: 1.0,
            rainFraction01: 1.0,
            snowFraction01: 0.0,
            fogMultiplier: 3.4,
            sunAttenuation01: 0.18,
            ambientScale01: 0.52,
            targetWindSpeed: 16.0,
            windGustiness: 5.5,
            wetnessRatePerSec: 0.35,
            snowRatePerSec: -0.1,
            lightningRateHz: 0.35,
            tintColor: SkyColor(0.45, 0.52, 0.64),
          ),
        WeatherKind.snow => const WeatherPreset(
            cloudCoverage01: 0.88,
            precipitationRate01: 0.65,
            rainFraction01: 0.0,
            snowFraction01: 1.0,
            fogMultiplier: 2.4,
            sunAttenuation01: 0.42,
            ambientScale01: 0.82,
            targetWindSpeed: 6.5,
            windGustiness: 2.0,
            wetnessRatePerSec: -0.02,
            snowRatePerSec: 0.14,
            lightningRateHz: 0.0,
            tintColor: SkyColor(0.86, 0.90, 0.96),
          ),
      };
}

/// Interpolated weather output for scene rendering, wet puddles, and particle spawners.
final class WeatherSnapshot {
  final WeatherKind targetKind;
  final double cloudCoverage01;
  final double precipitationRate01;
  final double rainIntensity01;
  final double snowIntensity01;
  final double fogMultiplier;
  final double sunAttenuation01;
  final double ambientScale01;
  final double windSpeed;
  final double windGustiness;
  final double wetness01;
  final double snowAccumulation01;
  final double lightningFlash01;
  final SkyColor skyTint;

  const WeatherSnapshot({
    required this.targetKind,
    required this.cloudCoverage01,
    required this.precipitationRate01,
    required this.rainIntensity01,
    required this.snowIntensity01,
    required this.fogMultiplier,
    required this.sunAttenuation01,
    required this.ambientScale01,
    required this.windSpeed,
    required this.windGustiness,
    required this.wetness01,
    required this.snowAccumulation01,
    required this.lightningFlash01,
    required this.skyTint,
  });
}

/// Continuous state-blending weather controller with wetness, snow depth, and lightning spikes.
final class WeatherController {
  WeatherKind _targetKind;
  WeatherPreset _fromPreset;
  WeatherPreset _targetPreset;
  double _blendProgress = 1.0;
  double transitionDurationSeconds;
  double _wetness01 = 0.0;
  double _snow01 = 0.0;
  double _lightningFlash01 = 0.0;
  double _lightningCooldown = 0.0;
  final math.Random _rng;

  WeatherController({
    WeatherKind initialKind = WeatherKind.clear,
    this.transitionDurationSeconds = 5.0,
    int seed = 1080,
  })  : _targetKind = initialKind,
        _fromPreset = WeatherPreset.forKind(initialKind),
        _targetPreset = WeatherPreset.forKind(initialKind),
        _rng = math.Random(seed);

  WeatherKind get targetKind => _targetKind;
  double get wetness01 => _wetness01;
  double get snowAccumulation01 => _snow01;
  double get lightningFlash01 => _lightningFlash01;

  void setWeather(WeatherKind kind, {bool immediate = false}) {
    if (immediate) {
      _targetKind = kind;
      final preset = WeatherPreset.forKind(kind);
      _fromPreset = preset;
      _targetPreset = preset;
      _blendProgress = 1.0;
      if (kind == WeatherKind.rain || kind == WeatherKind.storm) {
        _wetness01 = math.max(_wetness01, 0.5);
      } else if (kind == WeatherKind.snow) {
        _snow01 = math.max(_snow01, 0.4);
      }
      return;
    }

    if (_targetKind == kind) return;
    final current = _interpolatedPreset();
    _fromPreset = current;
    _targetKind = kind;
    _targetPreset = WeatherPreset.forKind(kind);
    _blendProgress = 0.0;
  }

  /// Manually fires an immediate lightning flash impulse (used by gameplay or storm bursts).
  void triggerLightningFlash([double strength = 1.0]) {
    _lightningFlash01 = strength.clamp(0.0, 1.0);
  }

  WeatherSnapshot update(double dt) {
    if (dt > 0.0) {
      if (_blendProgress < 1.0) {
        final dur = math.max(1e-4, transitionDurationSeconds);
        _blendProgress = (_blendProgress + dt / dur).clamp(0.0, 1.0);
      }

      final active = _interpolatedPreset();
      _wetness01 = (_wetness01 + active.wetnessRatePerSec * dt).clamp(0.0, 1.0);
      _snow01 = (_snow01 + active.snowRatePerSec * dt).clamp(0.0, 1.0);

      // Decay active lightning flash exponentially.
      _lightningFlash01 = math.max(0.0, _lightningFlash01 - dt * 3.5);
      _lightningCooldown -= dt;
      if (active.lightningRateHz > 1e-4 && _lightningCooldown <= 0.0) {
        if (_rng.nextDouble() < active.lightningRateHz * dt * 2.5) {
          _lightningFlash01 = 0.75 + _rng.nextDouble() * 0.25;
          _lightningCooldown = 0.8 + _rng.nextDouble() * 2.2;
        }
      }
    }

    return currentSnapshot;
  }

  WeatherSnapshot get currentSnapshot {
    final p = _interpolatedPreset();
    return WeatherSnapshot(
      targetKind: _targetKind,
      cloudCoverage01: p.cloudCoverage01,
      precipitationRate01: p.precipitationRate01,
      rainIntensity01: p.precipitationRate01 * p.rainFraction01,
      snowIntensity01: p.precipitationRate01 * p.snowFraction01,
      fogMultiplier: p.fogMultiplier,
      sunAttenuation01: p.sunAttenuation01,
      ambientScale01: p.ambientScale01,
      windSpeed: p.targetWindSpeed,
      windGustiness: p.windGustiness,
      wetness01: _wetness01,
      snowAccumulation01: _snow01,
      lightningFlash01: _lightningFlash01,
      skyTint: p.tintColor,
    );
  }

  WeatherPreset _interpolatedPreset() {
    final t = _blendProgress;
    final s = t * t * (3.0 - 2.0 * t);
    double lerp(double a, double b) => a + (b - a) * s;
    return WeatherPreset(
      cloudCoverage01: lerp(_fromPreset.cloudCoverage01, _targetPreset.cloudCoverage01),
      precipitationRate01:
          lerp(_fromPreset.precipitationRate01, _targetPreset.precipitationRate01),
      rainFraction01: lerp(_fromPreset.rainFraction01, _targetPreset.rainFraction01),
      snowFraction01: lerp(_fromPreset.snowFraction01, _targetPreset.snowFraction01),
      fogMultiplier: lerp(_fromPreset.fogMultiplier, _targetPreset.fogMultiplier),
      sunAttenuation01: lerp(_fromPreset.sunAttenuation01, _targetPreset.sunAttenuation01),
      ambientScale01: lerp(_fromPreset.ambientScale01, _targetPreset.ambientScale01),
      targetWindSpeed: lerp(_fromPreset.targetWindSpeed, _targetPreset.targetWindSpeed),
      windGustiness: lerp(_fromPreset.windGustiness, _targetPreset.windGustiness),
      wetnessRatePerSec:
          lerp(_fromPreset.wetnessRatePerSec, _targetPreset.wetnessRatePerSec),
      snowRatePerSec: lerp(_fromPreset.snowRatePerSec, _targetPreset.snowRatePerSec),
      lightningRateHz: lerp(_fromPreset.lightningRateHz, _targetPreset.lightningRateHz),
      tintColor: SkyColor.lerp(_fromPreset.tintColor, _targetPreset.tintColor, s),
    );
  }
}
