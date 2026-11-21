import 'package:flutter/material.dart';

import '../models/memory_collection.dart';
import '../core/theme/app_tokens.dart';

class CollectionCard
    extends StatelessWidget {
  final MemoryCollection collection;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CollectionCard({
    super.key,
    required this.collection,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(22),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration:
                    BoxDecoration(
                  color: dark ? BenTokens.panel2 : BenTokens.paper,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  size: 30,
                  color: BenTokens.gold,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    if (collection
                            .description !=
                        null &&
                        collection
                            .description!
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        collection
                            .description!,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: .58),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected:
                    (value) {
                  if (value ==
                      'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder:
                    (_) => const [
                  PopupMenuItem<
                      String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
                          color:
                              Colors.red,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Sil'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}