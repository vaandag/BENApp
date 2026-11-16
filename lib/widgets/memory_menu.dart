import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

enum MemoryAction {
  photo,
  video,
  music,
  text,
  location,
  live,
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
      useSafeArea: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        final actions = <_MemoryActionOptionData>[
          _MemoryActionOptionData(
            icon: Icons.photo_camera_outlined,
            title: 'Fotoğraf',
            subtitle: 'Bir kare bırak',
            action: MemoryAction.photo,
          ),
          _MemoryActionOptionData(
            icon: Icons.videocam_outlined,
            title: 'Video',
            subtitle: 'Hareketli anını kaydet',
            action: MemoryAction.video,
          ),
          _MemoryActionOptionData(
            icon: Icons.graphic_eq_rounded,
            title: 'Müzik',
            subtitle: 'Sesinle iz bırak',
            action: MemoryAction.music,
          ),
          _MemoryActionOptionData(
            icon: Icons.edit_note_rounded,
            title: 'Yazı',
            subtitle: 'Bir düşünce paylaş',
            action: MemoryAction.text,
          ),
          _MemoryActionOptionData(
            icon: Icons.location_on_outlined,
            title: 'Konum',
            subtitle: 'Bir yere iz bırak',
            action: MemoryAction.location,
          ),
          _MemoryActionOptionData(
            icon: Icons.sensors_rounded,
            title: 'Canlı yayın',
            subtitle: 'Şimdi canlıya geç',
            action: MemoryAction.live,
            accent: BenTokens.danger,
          ),
        ];

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * .84),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1B1B1B), Color(0xFF090909)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(color: Color(0xFF45402A), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .34),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: BenTokens.gold.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: BenTokens.gold.withValues(alpha: .38),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: BenTokens.gold,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anı oluştur',
                              style: TextStyle(
                                color: BenTokens.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.6,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'BEN dünyasına yeni bir iz bırak.',
                              style: TextStyle(
                                color: BenTokens.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: actions
                            .map(
                              (item) => _MemoryOption(
                                width: itemWidth,
                                data: item,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  onSelected(item.action);
                                },
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'İnsan  •  Zaman  •  Yer  •  Anı',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .34),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MemoryActionOptionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final MemoryAction action;
  final Color accent;

  const _MemoryActionOptionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.accent = BenTokens.gold,
  });
}

class _MemoryOption extends StatelessWidget {
  final double width;
  final _MemoryActionOptionData data;
  final VoidCallback onTap;

  const _MemoryOption({
    required this.width,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = data.accent;
    return Material(
      color: const Color(0xFF181818),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(color: Colors.white.withValues(alpha: .085)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        splashColor: accent.withValues(alpha: .12),
        child: SizedBox(
          width: width,
          height: 116,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .105),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: .48),
                          width: 1,
                        ),
                      ),
                      child: Icon(data.icon, color: accent, size: 21),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white.withValues(alpha: .35),
                      size: 16,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BenTokens.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BenTokens.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
