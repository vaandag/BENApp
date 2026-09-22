# BENApp V164 - Analyzer Cleanup

- Removed ApiClient token getter/setter wrapper; token remains a static field and auth service uses it directly.
- Removed unused HomeScreen imports, _showSearch, and _RoundButton.
- Replaced deprecated Color.withOpacity with Color.withValues(alpha: ...).
- Removed unused splash local variable.
- Replaced deprecated Matrix4 translate/scale calls with translateByDouble/scaleByDouble.
- Guarded async BuildContext use with context.mounted / mounted after awaits.
- Removed unused ProfileScreen imports.
- Renamed splash AnimatedBuilder parameters to avoid multiple-underscore lint.
