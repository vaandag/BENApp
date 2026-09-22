# V165 — Cinematic Particle Splash Fix

- Reworked splash formation to avoid a full logo popping in before formation.
- Logo contour is progressively drawn from particles.
- Inner opening is drawn progressively.
- Solid body resolves only after the contour is established.
- Spin/descend is applied after formation, not during initial construction.
- Target ring and landing shockwave are sequenced after the descent.
- Branding fades in after landing.
- No splash PNG is rendered by the Flutter splash painter.
- Version: 5.1.15+128
