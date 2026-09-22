import 'package:flutter/material.dart';

import '../models/memory_collection.dart';

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
    return Material(
      color: Colors.white,
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
              color:
                  Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF0F1EE),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  size: 32,
                  color:
                      Color(0xFF172033),
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
                          color: Colors
                              .grey
                              .shade600,
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