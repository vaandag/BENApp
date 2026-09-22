# BENApp V158 – Particle Logo Splash

- Splash no longer animates/rotates the PNG as a single image.
- `ParticleSplashView` samples the real `ben_splash_logo.png` into particles.
- Particles appear from a loose cloud, assemble the exact logo silhouette, then the particle field spins like a top and descends/settles onto a glowing target.
- The source PNG is never drawn directly by the splash view.
- Existing package/applicationId remains `com.ben.app`.
- Splash is native Android and transitions to `MainActivity` after the particle sequence.
