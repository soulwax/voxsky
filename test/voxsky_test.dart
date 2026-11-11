import 'package:test/test.dart';
import 'package:voxsky/voxsky.dart';

void main() {
  group('TimeOfDayClock & SolarEphemeris', () {
    test('advances 24h clock, rolls over days, and evaluates midday vs midnight sun elevation', () {
      final clock = TimeOfDayClock(initialHours: 23.0, dayLengthSeconds: 24.0);
      expect(clock.period, DayPeriod.midnight);
      expect(clock.formattedTime, '23:00');

      final wrapped = clock.advance(2.0); // +2h -> 01:00 next day
      expect(wrapped, isTrue);
      expect(clock.dayCount, 2);
      expect(clock.hours, closeTo(1.0, 1e-6));

      const ephemeris = SolarEphemeris(latitudeDegrees: 40.0);
      final noon = ephemeris.evaluate(12.0, dayCount: 1);
      final midnight = ephemeris.evaluate(0.0, dayCount: 1);

      expect(noon.sunDirection.y, greaterThan(0.6));
      expect(noon.daylightFactor, closeTo(1.0, 1e-6));
      expect(midnight.sunDirection.y, lessThan(-0.4));
      expect(midnight.daylightFactor, closeTo(0.0, 1e-6));
    });

    test('AtmosphericSkyRamp interpolates warm sunset vs cool night sky & stars', () {
      final ramp = AtmosphericSkyRamp.earthDefault();
      final sunset = ramp.evaluate(0.05);
      final deepNight = ramp.evaluate(-0.35);

      expect(sunset.horizonColor.r, greaterThan(sunset.horizonColor.b));
      expect(deepNight.starVisibility01, closeTo(1.0, 1e-6));
      expect(sunset.starVisibility01, lessThan(0.2));
    });
  });

  group('WeatherController & WindFieldSampler', () {
    test('blends clear to storm, accumulates wetness, and decays lightning flashes', () {
      final weather = WeatherController(
        initialKind: WeatherKind.clear,
        transitionDurationSeconds: 2.0,
      );
      weather.setWeather(WeatherKind.storm);
      weather.triggerLightningFlash(1.0);

      for (var i = 0; i < 4; i++) {
        weather.update(0.5);
      }

      final snap = weather.currentSnapshot;
      expect(snap.cloudCoverage01, closeTo(1.0, 1e-5));
      expect(snap.rainIntensity01, closeTo(1.0, 1e-5));
      expect(snap.wetness01, greaterThan(0.2));
      expect(snap.fogMultiplier, greaterThan(3.0));
      expect(snap.lightningFlash01, lessThan(0.2));
    });

    test('WindFieldSampler combines global gusts with local spherical radial zone', () {
      final sampler = WindFieldSampler(
        baseDirection: const SkyVec3(1.0, 0.0, 0.0),
        baseSpeed: 2.0,
        gustStrength: 0.5,
      )..zones.add(
          WindZoneDef(
            id: 'fan',
            position: const SkyVec3(10.0, 0.0, 0.0),
            radius: 6.0,
            strength: 12.0,
            shape: WindZoneShape.sphericalRadial,
          ),
        );

      final inside = sampler.sampleWind(const SkyVec3(12.0, 0.0, 0.0));
      final outside = sampler.sampleWind(const SkyVec3(50.0, 0.0, 0.0));
      expect(inside.length, greaterThan(outside.length + 5.0));
    });
  });
}
