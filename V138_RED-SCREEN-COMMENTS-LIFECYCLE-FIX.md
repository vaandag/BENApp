# BENApp V138 — Red Screen / Comments Lifecycle Fix

Based on IMG_0805.mp4, the Flutter assertion occurs during the CommentsScreen -> previous screen transition:
`_dependents.isEmpty`.

Changes:
- CommentsScreen now explicitly releases keyboard/text-field focus before popping.
- App-bar back uses the same safe close path.
- System back is intercepted so focus is released before the route is popped.
- Added a short 40ms handoff before Navigator.pop to avoid Android IME/inherited-widget lifecycle overlap.

V137's `BenTokens` import/analyzer fix is retained.

This is a targeted lifecycle mitigation; it must be verified on the Redmi 8 with the exact Comments -> Back -> Map flow from IMG_0805.mp4.
