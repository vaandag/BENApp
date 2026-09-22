# BEN V161 — Splash Hard Reset

The legacy raster splash resources that matched the old yellow pin (`splash.png`, `splash_full.png`, density splash PNGs, `ben_splash_logo.png`) have been removed. The old Flutter splash screen implementations were also removed. `SplashActivity` is the only launcher activity and renders `ParticleSplashView` directly.

Important for device testing: run `flutter clean` before building, uninstall `com.ben.app`, then build and manually install the APK. This prevents an old Gradle/APK artifact from being mistaken for V161.
