import 'package:flutter/material.dart';

import '../models/memory.dart';
import '../widgets/memory_timeline_group.dart';

class TimelineScreen
    extends StatelessWidget {
  final List<Memory> memories;

  const TimelineScreen({
    super.key,
    required this.memories,
  });

  @override
  Widget build(BuildContext context) {
    final groups =
        _groupByDate(memories);

    return Scaffold(
      backgroundColor:
          const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFAFAF8),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Zaman Çizelgesi',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'Henüz zaman çizelgende anı yok.',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                16,
                12,
                16,
                40,
              ),
              itemCount:
                  groups.length,
              itemBuilder:
                  (context, index) {
                final entry =
                    groups.entries
                        .elementAt(
                  index,
                );

                return MemoryTimelineGroup(
                  date: entry.key,
                  memories:
                      entry.value,
                );
              },
            ),
    );
  }

  Map<DateTime, List<Memory>>
      _groupByDate(
    List<Memory> memories,
  ) {
    final sorted = [...memories]
      ..sort(
        (a, b) =>
            b.createdAt.compareTo(
          a.createdAt,
        ),
      );

    final groups =
        <DateTime, List<Memory>>{};

    for (final memory in sorted) {
      final date = DateTime(
        memory.createdAt.year,
        memory.createdAt.month,
        memory.createdAt.day,
      );

      groups
          .putIfAbsent(
            date,
            () => [],
          )
          .add(memory);
    }

    return groups;
  }
}