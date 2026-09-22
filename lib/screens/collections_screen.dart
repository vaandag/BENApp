import 'package:flutter/material.dart';

import '../models/memory_collection.dart';
import '../services/memory_repository.dart';
import '../widgets/collection_card.dart';

class CollectionsScreen
    extends StatefulWidget {
  const CollectionsScreen({
    super.key,
  });

  @override
  State<CollectionsScreen>
      createState() =>
          _CollectionsScreenState();
}

class _CollectionsScreenState
    extends State<CollectionsScreen> {
  final MemoryRepository _repository =
      MemoryRepository();

  List<MemoryCollection>
      _collections = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    await _repository.initialize();

    final collections =
        await _repository
            .getCollections();

    if (!mounted) return;

    setState(() {
      _collections =
          collections;
      _loading = false;
    });
  }

  Future<void> _createCollection() async {
    final result =
        await _showCollectionDialog();

    if (result == null) return;

    final name = result.$1;
    final description =
        result.$2;

    await _repository
        .createCollection(
      name: name,
      description: description,
    );

    await _load();
  }

  Future<(String, String?)?>
      _showCollectionDialog() async {
    final nameController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    return showDialog<
        (String, String?)>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Yeni koleksiyon',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller:
                    nameController,
                autofocus: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Koleksiyon adı',
                  hintText:
                      'Örn. Giresun',
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller:
                    descriptionController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Açıklama',
                  hintText:
                      'İsteğe bağlı',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final name =
                    nameController
                        .text
                        .trim();

                if (name.isEmpty) {
                  return;
                }

                final description =
                    descriptionController
                        .text
                        .trim();

                Navigator.pop(
                  dialogContext,
                  (
                    name,
                    description
                            .isEmpty
                        ? null
                        : description,
                  ),
                );
              },
              child:
                  const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCollection(
    MemoryCollection collection,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title: const Text(
          'Koleksiyon silinsin mi?',
        ),
        content: Text(
          '"${collection.name}" koleksiyonu silinecek. Anıların kendisi silinmez.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child:
                const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _repository
        .deleteCollection(
      collection.id,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
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
          'Koleksiyonlar',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            const Color(0xFF172033),
        foregroundColor:
            Colors.white,
        onPressed:
            _createCollection,
        child: const Icon(
          Icons.add_rounded,
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _collections.isEmpty
              ? _EmptyCollections(
                  onCreate:
                      _createCollection,
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    16,
                    16,
                    110,
                  ),
                  itemCount:
                      _collections.length,
                  separatorBuilder:
                      (_, _) =>
                          const SizedBox(
                    height: 12,
                  ),
                  itemBuilder:
                      (context, index) {
                    final collection =
                        _collections[
                            index];

                    return CollectionCard(
                      collection:
                          collection,
                      onDelete: () =>
                          _deleteCollection(
                        collection,
                      ),
                    );
                  },
                ),
    );
  }
}

class _EmptyCollections
    extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyCollections({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFF0F1EE),
                borderRadius:
                    BorderRadius.circular(
                  26,
                ),
              ),
              child: const Icon(
                Icons.folder_outlined,
                size: 38,
                color:
                    Color(0xFF172033),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Henüz koleksiyon yok',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Anılarını istediğin gibi gruplamak için ilk koleksiyonunu oluştur.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                height: 1.45,
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Koleksiyon oluştur',
              ),
            ),
          ],
        ),
      ),
    );
  }
}