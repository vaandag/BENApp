import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

enum MemoryAction {
  photo,
  video,
  music,
  text,
  location,
}

class MemoryMenu {
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<MemoryAction> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).brightness == Brightness.dark ? BenTokens.panel : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Anı oluştur',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Şimdi bırakmak istediğin anıyı seç.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _MemoryOption(
                  icon: Icons.photo_camera_outlined,
                  title: 'Fotoğraf',
                  subtitle: 'Bir fotoğrafla anı bırak',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(MemoryAction.photo);
                  },
                ),
                _MemoryOption(
                  icon: Icons.videocam_outlined,
                  title: 'Video',
                  subtitle: 'Bir video ile anı bırak',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(MemoryAction.video);
                  },
                ),
                _MemoryOption(
                  icon: Icons.music_note_outlined,
                  title: 'Müzik',
                  subtitle: 'Müzik ve sözlerle anı bırak',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(MemoryAction.music);
                  },
                ),
                _MemoryOption(
                  icon: Icons.edit_outlined,
                  title: 'Yazı',
                  subtitle: 'Bir hikâye veya düşünce bırak',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(MemoryAction.text);
                  },
                ),
                _MemoryOption(
                  icon: Icons.location_on_outlined,
                  title: 'Konum',
                  subtitle: 'Anına bir konum ekle',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(MemoryAction.location);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemoryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MemoryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 9,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF172033),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark ? BenTokens.ink : Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
            ),
          ],
        ),
      ),
    );
  }
}