import 'dart:math' as math;

import 'math.dart';

/// Broad coarse period classification across the 24-hour diurnal clock.
enum DayPeriod { midnight, dawn, morning, noon, dusk, night }

/// Continuous 24-hour clock tracking in-game time, day number, and formatted clock readouts.
final class TimeOfDayClock {
  double _hours;
  int _dayCount;
  double dayLengthSeconds;
  double timeScale;
  bool paused;

  TimeOfDayClock({
    double initialHours = 12.0,
    int initialDayCount = 1,
    this.dayLengthSeconds = 600.0,
    this.timeScale = 1.0,
    this.paused = false,
  })  : _hours = ((initialHours % 24.0) + 24.0) % 24.0,
        _dayCount = initialDayCount;

  double get hours => _hours;
  set hours(double value) {
    _hours = ((value % 24.0) + 24.0) % 24.0;
  }

  int get dayCount => _dayCount;
  set dayCount(int value) => _dayCount = math.max(0, value);

  double get normalizedDay => _hours / 24.0;
  int get hourOfDay => _hours.floor() % 24;
  int get minuteOfHour => ((_hours - _hours.floor()) * 60.0).floor() % 60;

  String get formattedTime {
    final hh = hourOfDay.toString().padLeft(2, '0');
    final mm = minuteOfHour.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  DayPeriod get period {
    if (_hours >= 5.0 && _hours < 7.5) return DayPeriod.dawn;
    if (_hours >= 7.5 && _hours < 11.5) return DayPeriod.morning;
    if (_hours >= 11.5 && _hours < 16.5) return DayPeriod.noon;
    if (_hours >= 16.5 && _hours < 19.5) return DayPeriod.dusk;
    if (_hours >= 19.5 && _hours < 23.0) return DayPeriod.night;
    return DayPeriod.midnight;
  }

  /// Advances clock by [deltaRealSeconds] * [timeScale] scaled by [dayLengthSeconds].
  /// Returns true if midnight rolled over during this update.
  bool advance(double deltaRealSeconds) {
    if (paused || deltaRealSeconds <= 0.0 || dayLengthSeconds <= 1e-6) return false;
    final deltaHours = (deltaRealSeconds * timeScale / dayLengthSeconds) * 24.0;
    final raw = _hours + deltaHours;
    final wrappedDays = (raw / 24.0).floor();
    _hours = ((raw % 24.0) + 24.0) % 24.0;
    if (wrappedDays != 0) {
      _dayCount += wrappedDays;
      return true;
    }
    return false;
  }
}

/// Spherical solar & lunar geometry evaluated at a given hour, day, and latitude.
final class SolarEphemerisState {
  /// Unit vector pointing TOWARD the sun in world space (`y > 0` during daylight).
  final SkyVec3 sunDirection;

  /// Unit direction light travels AWAY from primary celestial emitter (`-sunDirection` or `-moonDirection`).
  final SkyVec3 primaryLightDirection;

  /// Unit vector pointing TOWARD the moon in world space.
  final SkyVec3 moonDirection;

  final double sunElevationRadians;
  final double sunAzimuthRadians;
  final double daylightFactor;
  final double twilightFactor;
  final double moonPhase01;

  const SolarEphemerisState({
    required this.sunDirection,
    required this.primaryLightDirection,
    required this.moonDirection,
    required this.sunElevationRadians,
    required this.sunAzimuthRadians,
    required this.daylightFactor,
    required this.twilightFactor,
    required this.moonPhase01,
  });
}

/// Evaluates deterministic solar and lunar positions from clock time and observer latitude.
final class SolarEphemeris {
  final double latitudeDegrees;
  final double solarDeclinationDegrees;
  final double lunarCycleDays;
  final double sunAzimuthOffsetDegrees;

  const SolarEphemeris({
    this.latitudeDegrees = 38.0,
    this.solarDeclinationDegrees = 14.0,
    this.lunarCycleDays = 29.53,
    this.sunAzimuthOffsetDegrees = 0.0,
  });

  SolarEphemerisState evaluate(double timeHours, {int dayCount = 1}) {
    final h = ((timeHours % 24.0) + 24.0) % 24.0;
    // Hour angle: 0 rad at 12:00 solar noon, -pi/2 at 06:00, +pi/2 at 18:00.
    final hourAngle = ((h - 12.0) / 12.0) * math.pi;
    final lat = latitudeDegrees * math.pi / 180.0;
    final dec = solarDeclinationDegrees * math.pi / 180.0;

    final sinAlt = math.sin(lat) * math.sin(dec) +
        math.cos(lat) * math.cos(dec) * math.cos(hourAngle);
    final elevation = math.asin(sinAlt.clamp(-1.0, 1.0));

    final cosAlt = math.max(1e-5, math.cos(elevation));
    final cosAz = ((math.sin(dec) - math.sin(lat) * sinAlt) /
            (math.cos(lat).abs() > 1e-5 ? math.cos(lat) * cosAlt : cosAlt))
        .clamp(-1.0, 1.0);
    var azimuth = math.acos(cosAz);
    if (math.sin(hourAngle) > 0.0) {
      azimuth = math.pi * 2.0 - azimuth;
    }
    azimuth += sunAzimuthOffsetDegrees * math.pi / 180.0;

    final sx = math.cos(elevation) * math.sin(azimuth);
    final sy = math.sin(elevation);
    final sz = -math.cos(elevation) * math.cos(azimuth);
    final sunDir = SkyVec3(sx, sy, sz).normalized;

    final moonPhase01 = ((dayCount + h / 24.0) % lunarCycleDays) / lunarCycleDays;
    final moonOffsetAngle = moonPhase01 * math.pi * 2.0 + math.pi;
    final moonHour = hourAngle + moonOffsetAngle;
    final sinMoonAlt = math.sin(lat) * math.sin(-dec * 0.7) +
        math.cos(lat) * math.cos(-dec * 0.7) * math.cos(moonHour);
    final moonAlt = math.asin(sinMoonAlt.clamp(-1.0, 1.0));
    final moonDir = SkyVec3(
      math.cos(moonAlt) * math.sin(moonHour),
      math.sin(moonAlt),
      -math.cos(moonAlt) * math.cos(moonHour),
    ).normalized;

    final daylight = ((elevation + 0.06) / 0.45).clamp(0.0, 1.0);
    final twilight = math.exp(-((elevation - 0.01) * (elevation - 0.01)) / 0.018);

    final activeEmitter = sunDir.y >= -0.05 ? sunDir : moonDir;

    return SolarEphemerisState(
      sunDirection: sunDir,
      primaryLightDirection: -activeEmitter,
      moonDirection: moonDir,
      sunElevationRadians: elevation,
      sunAzimuthRadians: azimuth,
      daylightFactor: daylight,
      twilightFactor: twilight.clamp(0.0, 1.0),
      moonPhase01: moonPhase01,
    );
  }
}
