<p align="center">
  <img src="assets/logo.svg" width="88" alt="voxsky logo"/>
</p>

# voxsky

Pure Dart astronomical time-of-day clock, solar/lunar ephemeris, atmospheric sky color ramps, weather transitions, and turbulent spatial wind fields.

## Features

- **Time-of-Day & Ephemeris (`TimeOfDayClock`, `SolarEphemeris`)**: 24h cycle with day tracking, sunrise/noon/dusk/night period classification, spherical solar/lunar directions, and lunar phase.
- **Atmospheric Sky Curves (`AtmosphericSkyRamp`)**: Smooth multi-stop interpolation of zenith, horizon, ground, sun, ambient, and fog colors across solar elevation.
- **Weather Controller (`WeatherController`)**: Continuous cross-blending across `clear`, `overcast`, `rain`, `storm`, and `snow` with wetness/snow accumulation and lightning impulses.
- **Turbulent Wind Fields (`WindFieldSampler`)**: Prevailing gusting wind plus localized directional, radial, and vortex spatial wind zones.
