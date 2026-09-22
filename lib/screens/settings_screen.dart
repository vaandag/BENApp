import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(
            'Görünüm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
            ),
          ),
          const SizedBox(height: 10),
          _ThemeChoice(
            icon: Icons.wb_sunny_outlined,
            title: 'Açık tema',
            subtitle: 'BEN\'i açık ve ferah görünümde kullan',
            selected: themeMode == ThemeMode.light,
            onTap: () { onThemeChanged(ThemeMode.light); Navigator.pop(context); },
          ),
          _ThemeChoice(
            icon: Icons.dark_mode_outlined,
            title: 'Koyu tema',
            subtitle: 'BEN\'i gece görünümünde kullan',
            selected: themeMode == ThemeMode.dark,
            onTap: () { onThemeChanged(ThemeMode.dark); Navigator.pop(context); },
          ),
          _ThemeChoice(
            icon: Icons.settings_suggest_outlined,
            title: 'Sistem',
            subtitle: 'Telefonun tema ayarını kullan',
            selected: themeMode == ThemeMode.system,
            onTap: () { onThemeChanged(ThemeMode.system); Navigator.pop(context); },
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF111A25)
                  : const Color(0xFFFFF6C9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: dark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD200),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF0E1014),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'BEN tasarımı',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.palette_outlined,
            title: 'BEN renkleri',
            subtitle: 'Sarı • Lacivert • Beyaz',
          ),
          _SettingTile(
            icon: Icons.verified_outlined,
            title: 'Rozetler ve seviyeler',
            subtitle: 'Profilindeki ilerleme sistemini yönet',
          ),
          _SettingTile(
            icon: Icons.map_outlined,
            title: 'Harita görünümü',
            subtitle: 'Harita stili ve konum tercihleri',
          ),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFFFFD200)
                    : Theme.of(context).dividerColor.withValues(alpha: .28),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFD200)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0E1014),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFFD200)
                          : (dark ? Colors.white38 : Colors.black26),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD200),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
