import 'dart:math' as math;
import 'dart:io';
import '../services/auth_service.dart';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_tokens.dart';
import '../core/network/api_client.dart';
import '../models/memory.dart';
import 'memory_map_detail_screen.dart';
import 'memory_fullscreen_viewer.dart';

/// BEN ana akışı. Gerçek backend anıları kaynak veridir; demo/bot içerik eklenmez.
class HomeScreen extends StatefulWidget {
  final List<Memory> memories;
  final List<Memory> connectionMemories;
  final ValueChanged<Memory>? onDelete;
  final VoidCallback? onCreate;
  final VoidCallback? onOpenLive;
  final ValueChanged<Memory>? onOpenMap;
  final BenUser? currentUser;

  const HomeScreen({
    super.key,
    required this.memories,
    this.connectionMemories = const <Memory>[],
    this.onDelete,
    this.onCreate,
    this.onOpenLive,
    this.onOpenMap,
    this.currentUser,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _ambient;
  int _activeFilter = 0;
  int _page = 0;

  final Set<String> _liked = <String>{};
  final Set<String> _saved = <String>{};
  final ApiClient _api = ApiClient();

  List<_DemoPerson> get _people {
    if (widget.currentUser == null) return const <_DemoPerson>[];
    final ownMemories = widget.memories.where((memory) => memory.isStory && !memory.isExpired).take(6).toList();
    if (ownMemories.isEmpty) return const [];
    final stories = ownMemories.map((memory) => _DemoStory(
      memory.text?.isNotEmpty == true ? memory.text! : 'Yeni bir an bıraktım.',
      memory.title ?? (memory.latitude != null && memory.longitude != null ? 'Konumlu anı' : 'Konum eklenmedi'),
      memory.type == MemoryType.video ? Icons.play_circle_fill_rounded : Icons.photo_camera_rounded,
      memory: memory,
    )).toList();
    return [
      _DemoPerson(widget.currentUser!.username, 'Şimdi', Icons.person_rounded, stories),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: .88);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _loadSocialState();
  }

  Future<void> _loadSocialState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLikes = prefs.getStringList('ben_liked_memories') ?? const <String>[];
    if (!mounted) return;
    setState(() => _liked.addAll(savedLikes));
  }

  Future<void> _persistLikes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ben_liked_memories', _liked.toList());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ambient.dispose();
    super.dispose();
  }

  List<_FeedMemory> get _feed {
    // Akış = keşfet mantığı. Bağlar = takip ettiğimiz kişilerden gelen akış.
    // Backend scope desteği yoksa MainScreen aynı veri kümesini güvenli şekilde
    // sağlayabilir; UI yine tek ve tutarlı bir akış deneyimi sunar.
    final source = _activeFilter == 1 ? widget.connectionMemories : widget.memories;
    final real = source.map(_FeedMemory.fromReal).toList();
    return real;
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? BenTokens.night : const Color(0xFFF1F5F6),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (_, _) => CustomPaint(
                painter: _LiveBackdropPainter(
                  phase: _ambient.value,
                  dark: dark,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: BenTokens.gold,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 500));
                if (mounted) setState(() {});
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _homeIntro(context, feed.length)),
                  SliverToBoxAdapter(child: _stories(context)),
                  SliverToBoxAdapter(child: _filterBar(context)),
                  SliverToBoxAdapter(child: _liveHeader(context, feed.length)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 414,
                      child: feed.isEmpty
                          ? _emptyState(context)
                          : PageView.builder(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: feed.length,
                              onPageChanged: (value) => setState(() => _page = value),
                              itemBuilder: (context, index) {
                                final item = feed[index];
                                return AnimatedBuilder(
                                  animation: _pageController,
                                  builder: (context, child) {
                                    double scale = 1;
                                    if (_pageController.hasClients && _pageController.position.haveDimensions) {
                                      final current = _pageController.page ?? _page.toDouble();
                                      scale = (1 - ((current - index).abs() * .07)).clamp(.93, 1.0);
                                    }
                                    return Transform.scale(scale: scale, child: child);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 14),
                                    child: _LiveMemoryCard(
                                      key: ValueKey<String>('live-memory-${item.id}'),
                                      item: item,
                                      liked: _liked.contains(item.id),
                                      saved: _saved.contains(item.id),
                                      onLike: () => _toggleRemote(item, like: true),
                                      onSave: () => _toggleRemote(item, like: false),
                                      onComment: () {},
                                      onOpen: () => _openMemory(context, item),
                                      onOpenMap: item.memory?.hasLocation == true ? () => _openMemoryMap(context, item) : null,
                                      onShare: () => _shareMemory(context, item),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 130)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stories(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
        scrollDirection: Axis.horizontal,
        itemCount: _people.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: widget.onCreate,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle, border: Border.all(color: BenTokens.cyan.withValues(alpha: .75), width: 1.5)),
                    child: const Icon(Icons.camera_alt_rounded, color: BenTokens.cyan, size: 23),
                  ),
                  const SizedBox(height: 4),
                  const Text('Sen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }
          final p = _people[index - 1];
          return SizedBox(
            width: 76,
            child: InkWell(
              borderRadius: BorderRadius.circular(38),
              splashColor: BenTokens.cyan.withValues(alpha: .18),
              onTap: () => _showStoryViewer(context, index - 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [BenTokens.gold, Color(0xFFFFF3A1), BenTokens.gold])),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(color: const Color(0xFF151C2C), shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                      child: Icon(p.icon, color: BenTokens.gold, size: 23),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _homeIntro(BuildContext context, int count) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bugün', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .48), letterSpacing: .4)),
                const SizedBox(height: 2),
                const Text('Şehirden anlar.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.8)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: dark ? Colors.white.withValues(alpha: .045) : Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BenTokens.cyan.withValues(alpha: .12)),
            ),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: BenTokens.success, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('$count iz', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(BuildContext context) {
    const items = [
      ('Akış', Icons.explore_rounded),
      ('Bağlar', Icons.hub_rounded),
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 7),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final active = _activeFilter == index;
          return GestureDetector(
            onTap: () => setState(() {
              _activeFilter = index;
              _page = 0;
              if (_pageController.hasClients) _pageController.jumpToPage(0);
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [BenTokens.cyan, BenTokens.cyanBright]) : null,
                color: active ? null : (dark ? Colors.white.withValues(alpha: .045) : Colors.white.withValues(alpha: .72)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? Colors.transparent : Theme.of(context).dividerColor.withValues(alpha: .24)),
                boxShadow: active ? [BoxShadow(color: BenTokens.cyan.withValues(alpha: .14), blurRadius: 14, offset: const Offset(0, 5))] : const [],
              ),
              child: Row(children: [
                Icon(items[index].$2, size: 15, color: active ? BenTokens.ink : Theme.of(context).colorScheme.onSurface.withValues(alpha: .58)),
                const SizedBox(width: 6),
                Text(items[index].$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? BenTokens.ink : Theme.of(context).colorScheme.onSurface.withValues(alpha: .72))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _liveHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 7),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF39E58C), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('CANLI AKIŞ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const Spacer(),
          Text('$count an', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45))),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.auto_awesome_rounded, color: BenTokens.gold, size: 42), const SizedBox(height: 12), const Text('Akış sessiz.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('İlk anını bırak ve BEN dünyasını başlat.', textAlign: TextAlign.center), const SizedBox(height: 18), FilledButton.icon(onPressed: widget.onCreate, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('İlk anını bırak'))])));
  }

  void _openMemory(BuildContext context, _FeedMemory item) {
    final memory = item.memory;
    if (memory == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryFullscreenViewer(memory: memory, memories: widget.memories)));
  }

  void _openMemoryMap(BuildContext context, _FeedMemory item) {
    final memory = item.memory;
    if (memory == null || !memory.hasLocation) return;
    if (widget.onOpenMap != null) {
      widget.onOpenMap!(memory);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryMapDetailScreen(memory: memory, memories: widget.memories)));
  }

  Future<void> _shareMemory(BuildContext context, _FeedMemory item) async {
    final memory = item.memory;
    if (memory == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Anıyı paylaş', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
            const SizedBox(height: 12),
            ListTile(leading: const Icon(Icons.people_alt_rounded), title: const Text('BEN’de gönder'), subtitle: const Text('Bağlarından birine gönder'), onTap: () { Navigator.pop(sheetContext); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BEN’de gönderim için kişi seçme ekranı hazırlanıyor.'))); }),
            ListTile(leading: const Icon(Icons.ios_share_rounded), title: const Text('Diğer uygulamalar'), subtitle: const Text('WhatsApp ve diğer paylaşım seçenekleri'), onTap: () async { Navigator.pop(sheetContext); await SharePlus.instance.share(ShareParams(text: 'BEN’de bir anı: ${item.text}\n${item.place}')); }),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggleRemote(_FeedMemory item, {required bool like}) async {
    final id = int.tryParse(item.id);
    if (id == null) {
      setState(() {
        final set = like ? _liked : _saved;
        if (!set.add(item.id)) set.remove(item.id);
      });
      if (like) await _persistLikes();
      return;
    }
    try {
      await _api.post('memories/$id/${like ? 'like' : 'save'}', body: {'user_id': AuthService.currentUser?.id ?? 1});
      if (!mounted) return;
      setState(() {
        final set = like ? _liked : _saved;
        if (!set.add(item.id)) set.remove(item.id);
      });
      if (like) await _persistLikes();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final set = like ? _liked : _saved;
        if (!set.add(item.id)) set.remove(item.id);
      });
      if (like) await _persistLikes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sunucuya ulaşılamadı; değişiklik bu oturumda gösteriliyor.')));
    }
  }

  void _showStoryViewer(BuildContext context, int initialIndex) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Anlar',
      barrierColor: Colors.black.withValues(alpha: .82),
      pageBuilder: (_, _, _) => _StoryViewer(
        people: _people,
        initialIndex: initialIndex,
      ),
    );
  }



}


class _DemoStory {
  final String text;
  final String place;
  final IconData icon;
  final Memory? memory;
  const _DemoStory(this.text, this.place, this.icon, {this.memory});
}

class _DemoPerson {
  final String name;
  final String time;
  final IconData icon;
  final List<_DemoStory> stories;
  const _DemoPerson(this.name, this.time, this.icon, this.stories);
}

class _StoryViewer extends StatefulWidget {
  final List<_DemoPerson> people;
  final int initialIndex;
  const _StoryViewer({required this.people, required this.initialIndex});

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  late final PageController _peopleController;
  int _personIndex = 0;
  int _storyIndex = 0;

  @override
  void initState() {
    super.initState();
    _personIndex = widget.initialIndex.clamp(0, widget.people.isEmpty ? 0 : widget.people.length - 1);
    _peopleController = PageController(initialPage: _personIndex);
  }

  @override
  void dispose() {
    _peopleController.dispose();
    super.dispose();
  }

  _DemoPerson? get _person => widget.people.isEmpty ? null : widget.people[_personIndex];
  _DemoStory? get _story => (_person == null || _person!.stories.isEmpty)
      ? null
      : _person!.stories[_storyIndex.clamp(0, _person!.stories.length - 1)];

  void _goStory(int direction) {
    final person = _person;
    if (person == null || person.stories.isEmpty) return;
    final next = _storyIndex + direction;
    if (next >= 0 && next < person.stories.length) {
      setState(() => _storyIndex = next);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.people.isEmpty || _person == null || _story == null) {
      return Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              const Center(child: Text('Henüz AN yok.', style: TextStyle(color: Colors.white))),
              Positioned(top: 12, right: 12, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: PageView.builder(
          controller: _peopleController,
          itemCount: widget.people.length,
          onPageChanged: (index) => setState(() {
            _personIndex = index;
            _storyIndex = 0;
          }),
          itemBuilder: (context, index) {
            final person = widget.people[index];
            final storyIndex = index == _personIndex ? _storyIndex : 0;
            final story = person.stories[storyIndex.clamp(0, person.stories.length - 1)];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final width = MediaQuery.sizeOf(context).width;
                if (details.localPosition.dx < width * .35) {
                  _goStory(-1);
                } else if (details.localPosition.dx > width * .65) {
                  _goStory(1);
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF111B2A),
                            Color.lerp(BenTokens.ink, BenTokens.gold, (index + 1) / (widget.people.length + 1))!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: story.memory?.photo != null && story.memory!.photo!.existsSync()
                          ? Image.file(story.memory!.photo!, fit: BoxFit.cover)
                          : story.memory?.hasVideo == true && story.memory!.video != null
                              ? _LocalVideoPreview(path: story.memory!.video!, fallbackColor: const Color(0xFF111B2A), icon: story.icon)
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(story.icon, size: 118, color: Colors.white.withValues(alpha: .12)),
                                    Container(
                                      width: 96,
                                      height: 104,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: BenTokens.gold.withValues(alpha: .55), width: 1.5),
                                        color: Colors.black.withValues(alpha: .16),
                                      ),
                                      child: Icon(story.icon, size: 38, color: Colors.white.withValues(alpha: .62)),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              for (int i = 0; i < person.stories.length; i++)
                                Expanded(
                                  child: Container(
                                    height: 3,
                                    margin: EdgeInsets.only(right: i == person.stories.length - 1 ? 0 : 4),
                                    decoration: BoxDecoration(
                                      color: i <= storyIndex ? BenTokens.gold : Colors.white24,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 22,
                    top: 65,
                    child: Row(
                      children: [
                        Container(width: 42, height: 42, decoration: const BoxDecoration(color: BenTokens.gold, shape: BoxShape.circle), child: Icon(person.icon, color: BenTokens.ink)),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(person.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          Text('${person.time} • AN', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 26,
                    right: 26,
                    bottom: 34,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(story.text, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, height: 1.12)),
                      const SizedBox(height: 9),
                      Row(children: [const Icon(Icons.auto_stories_rounded, color: BenTokens.gold, size: 16), const SizedBox(width: 6), const Text('STORY • 24 SAAT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 11)), const Spacer(), Text('📍 ${story.place}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))]),
                    ]),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.sizeOf(context).width * .18,
                    child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _goStory(-1)),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.sizeOf(context).width * .18,
                    child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _goStory(1)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeedMemory {
  final String id;
  final String user;
  final String avatarUrl;
  final String place;
  final String text;
  final MemoryType kind;
  final IconData visualIcon;
  final Color visualColor;
  final int likes;
  final int comments;
  final int saves;
  final String time;
  final Memory? memory;

  const _FeedMemory({required this.id, required this.user, required this.avatarUrl, required this.place, required this.text, required this.kind, required this.visualIcon, required this.visualColor, required this.likes, required this.comments, required this.saves, required this.time, this.memory});

  factory _FeedMemory.fromReal(Memory memory) => _FeedMemory(id: memory.id, user: memory.ownerUsername ?? AuthService.currentUser?.username ?? 'BEN', avatarUrl: memory.ownerAvatarUrl ?? AuthService.currentUser?.avatarUrl ?? '', place: memory.hasLocation ? 'Konumlu anı' : 'BEN', text: memory.hasText ? memory.text! : 'Yeni bir an bıraktım.', kind: memory.type, visualIcon: switch (memory.type) { MemoryType.photo => Icons.photo_rounded, MemoryType.video => Icons.play_circle_fill_rounded, MemoryType.music => Icons.music_note_rounded, MemoryType.location => Icons.location_on_rounded, MemoryType.text => Icons.notes_rounded }, visualColor: const Color(0xFF27344D), likes: memory.isFavorite ? 1 : 0, comments: 0, saves: memory.isPinned ? 1 : 0, time: _relative(memory.createdAt), memory: memory);

  static String _relative(DateTime value) {
    final d = DateTime.now().difference(value);
    if (d.inMinutes < 1) return 'şimdi';
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} sa önce';
    return '${d.inDays} gün önce';
  }
}

class _LiveMemoryCard extends StatefulWidget {
  final _FeedMemory item;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onOpen;
  final VoidCallback? onOpenMap;
  final VoidCallback onShare;

  const _LiveMemoryCard({super.key, required this.item, required this.liked, required this.saved, required this.onLike, required this.onSave, required this.onComment, required this.onOpen, required this.onShare, this.onOpenMap});

  @override
  State<_LiveMemoryCard> createState() => _LiveMemoryCardState();
}

class _LiveMemoryCardState extends State<_LiveMemoryCard> {
  final TextEditingController _commentController = TextEditingController();
  final ApiClient _api = ApiClient();
  List<_InlineComment> _comments = <_InlineComment>[];
  bool _commentsOpen = false;
  bool _loadingComments = false;
  bool _sending = false;

  String get _key => 'ben_comments_memory_${widget.item.id}';
  String get _name => AuthService.currentUser?.username.trim().isNotEmpty == true ? AuthService.currentUser!.username : 'BEN';

  @override
  void didUpdateWidget(covariant _LiveMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      // PageView may reuse this State for another memory. Never carry the
      // previous memory's inline comments into the newly displayed card.
      _comments = <_InlineComment>[];
      _commentsOpen = false;
      _loadingComments = false;
      _sending = false;
      _commentController.clear();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleComments() async {
    setState(() => _commentsOpen = !_commentsOpen);
    if (_commentsOpen && _comments.isEmpty) await _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = <_InlineComment>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final rawComment in decoded.whereType<Map>()) {
            final comment = _InlineComment.fromJson(Map<String, dynamic>.from(rawComment));
            if (comment.memoryId != widget.item.id) continue;
            if (comment.text.trim().isEmpty) continue;
            list.add(comment);
          }
        }
      } catch (_) {}
    }
    final id = int.tryParse(widget.item.id);
    if (id != null) {
      try {
        final json = await _api.get('memories/$id/comments');
        final rows = json is List ? json : (json is Map && json['data'] is List ? json['data'] as List : const []);
        for (final rawRow in rows.whereType<Map>()) {
          final row = Map<String, dynamic>.from(rawRow);
          final rawMemoryId = row['memory_id'] ?? row['memoryId'];
          if (rawMemoryId == null || '$rawMemoryId' != widget.item.id) continue;
          final c = _InlineComment.fromJson(row);
          if (c.text.trim().isEmpty) continue;
          if (!list.any((x) => x.text == c.text && x.username == c.username && x.createdAt == c.createdAt)) list.add(c);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _comments = list;
      _loadingComments = false;
    });
    await _persistComments();
  }

  Future<void> _persistComments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_comments.map((e) => e.toJson()).toList()));
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;
    final c = _InlineComment(text, memoryId: widget.item.id, username: _name, createdAt: DateTime.now());
    setState(() {
      _comments.add(c);
      _commentController.clear();
      _sending = true;
    });
    await _persistComments();
    final id = int.tryParse(widget.item.id);
    if (id != null) {
      try {
        await _api.post('comments', body: {'memory_id': id, 'user_id': AuthService.currentUser?.id ?? 1, 'body': text});
      } catch (_) {}
    }
    if (mounted) setState(() => _sending = false);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final commentCount = widget.item.comments > _comments.length ? widget.item.comments : _comments.length;
    return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF0C151E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: BenTokens.cyan.withValues(alpha: dark ? .09 : .10)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .34 : .10), blurRadius: 28, offset: const Offset(0, 14))],
        ),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onOpen,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                  if (widget.item.memory?.photo != null && widget.item.memory!.photo!.existsSync())
                    Image.file(widget.item.memory!.photo!, fit: BoxFit.cover)
                  else if (widget.item.memory?.hasVideo == true && widget.item.memory!.video != null)
                    _LocalVideoPreview(path: widget.item.memory!.video!, fallbackColor: widget.item.visualColor, icon: widget.item.visualIcon)
                  else
                    CustomPaint(painter: _MemoryVisualPainter(base: widget.item.visualColor, icon: widget.item.visualIcon)),
                  DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .10), Colors.black.withValues(alpha: .05), Colors.black.withValues(alpha: .72)]))),
                  Positioned(top: 12, left: 13, right: 13, child: Row(children: [_Avatar(name: widget.item.user, avatarUrl: widget.item.avatarUrl), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.item.user, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: -.1)), Text(widget.item.time, style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700))])), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .30), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)), child: Text(_typeLabel(widget.item.kind), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))) ])),
                  Positioned(left: 15, right: 15, bottom: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.place_rounded, color: BenTokens.gold, size: 15), const SizedBox(width: 5), Expanded(child: Text(widget.item.place, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis))]), const SizedBox(height: 5), Text(widget.item.text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -.4), maxLines: 2, overflow: TextOverflow.ellipsis)])),
                  if (widget.item.kind == MemoryType.video) const Center(child: _PlayOrb()),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Row(children: [
                _ActionButton(iconWidget: BENDartIcon(active: widget.liked), label: '${widget.item.likes + (widget.liked ? 1 : 0)}', active: widget.liked, onTap: widget.onLike),
                _ActionButton(iconWidget: const BENFeatherIcon(), label: '$commentCount', onTap: _toggleComments),
                _ActionButton(icon: widget.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: '${widget.item.saves + (widget.saved ? 1 : 0)}', active: widget.saved, onTap: widget.onSave),
                _ActionButton(icon: Icons.ios_share_rounded, label: 'Paylaş', onTap: widget.onShare),
                const Spacer(),
                _MapMemoryButton(onTap: widget.onOpenMap),
              ]),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: _commentsOpen
                  ? Container(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(children: [
                        if (_loadingComments)
                          const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                        else if (_comments.isNotEmpty)
                          ..._comments.reversed.take(2).map((c) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [_Avatar(name: c.username, size: 27), const SizedBox(width: 8), Expanded(child: Text('${c.username}: ${c.text}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)))]))),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                minLines: 1,
                                maxLines: 1,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _submitComment(),
                                decoration: InputDecoration(
                                  hintText: 'Bu ana bir iz bırak…',
                                  isDense: true,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            IconButton.filled(
                              onPressed: _sending ? null : _submitComment,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.arrow_upward_rounded, size: 18),
                            ),
                          ],
                        ),
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
  }

  String _typeLabel(MemoryType type) => switch (type) { MemoryType.photo => 'FOTO', MemoryType.video => 'VİDEO', MemoryType.text => 'YAZI', MemoryType.music => 'MÜZİK', MemoryType.location => 'KONUM' };
}

class _InlineComment {
  final String text;
  final String username;
  final String? memoryId;
  final DateTime createdAt;
  const _InlineComment(this.text, {this.memoryId, required this.username, required this.createdAt});
  Map<String, dynamic> toJson() => {
        'body': text,
        'username': username,
        'created_at': createdAt.toIso8601String(),
        if (memoryId != null) 'memory_id': memoryId,
      };
  factory _InlineComment.fromJson(Map<String, dynamic> json) => _InlineComment(
        '${json['body'] ?? ''}',
        memoryId: '${json['memory_id'] ?? json['memoryId'] ?? ''}'.trim().isEmpty ? null : '${json['memory_id'] ?? json['memoryId']}',
        username: '${json['username'] ?? 'BEN'}',
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      );
}

class _LocalVideoPreview extends StatefulWidget {
  final String path;
  final Color fallbackColor;
  final IconData icon;
  const _LocalVideoPreview({required this.path, required this.fallbackColor, required this.icon});
  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
  VideoPlayerController? _controller;
  @override
  void initState() {
    super.initState();
    _init();
  }
  Future<void> _init() async {
    final file = File(widget.path);
    if (!file.existsSync()) return;
    try {
      final c = VideoPlayerController.file(file);
      await c.initialize();
      await c.setVolume(0);
      if (!mounted) { c.dispose(); return; }
      setState(() => _controller = c);
    } catch (_) {}
  }
  @override
  void dispose() { _controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return CustomPaint(painter: _MemoryVisualPainter(base: widget.fallbackColor, icon: widget.icon));
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
    );
  }
}

class _LiveBackdropPainter extends CustomPainter {
  final double phase;
  final bool dark;
  _LiveBackdropPainter({required this.phase, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final t = phase * math.pi * 2;
    final spots = [
      (Offset(size.width * (.10 + .025 * math.sin(t)), size.height * .18), 105.0, BenTokens.gold.withValues(alpha: dark ? .055 : .09)),
      (Offset(size.width * (.88 + .03 * math.cos(t)), size.height * .48), 145.0, const Color(0xFF5B6DFF).withValues(alpha: dark ? .05 : .045)),
      (Offset(size.width * (.55 + .04 * math.sin(t * .7)), size.height * .86), 120.0, const Color(0xFF35D8A0).withValues(alpha: dark ? .035 : .04)),
    ];
    for (final spot in spots) {
      p.color = spot.$3;
      canvas.drawCircle(spot.$1, spot.$2, p);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveBackdropPainter oldDelegate) => oldDelegate.phase != phase || oldDelegate.dark != dark;
}

class _MemoryVisualPainter extends CustomPainter {
  final Color base;
  final IconData icon;
  _MemoryVisualPainter({required this.base, required this.icon});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base, Color.lerp(base, Colors.black, .65)!]).createShader(rect);
    canvas.drawRect(rect, bg);
    final p = Paint()..style = PaintingStyle.fill;
    p.color = Colors.white.withValues(alpha: .07);
    for (int i = -2; i < 7; i++) {
      final x = size.width * .18 * i;
      canvas.save();
      canvas.translate(x, 0);
      canvas.rotate(-.35);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * .15, size.width * .42, size.height * .9), const Radius.circular(40)), p);
      canvas.restore();
    }
    p.color = BenTokens.gold.withValues(alpha: .17);
    canvas.drawCircle(Offset(size.width * .72, size.height * .34), size.width * .24, p);
    p.color = Colors.white.withValues(alpha: .10);
    canvas.drawCircle(Offset(size.width * .72, size.height * .34), size.width * .13, p);
    final tp = TextPainter(text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 70, color: Colors.white.withValues(alpha: .13))), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(size.width * .12, size.height * .34));
  }

  @override
  bool shouldRepaint(covariant _MemoryVisualPainter oldDelegate) => oldDelegate.base != base || oldDelegate.icon != icon;
}

class _PlayOrb extends StatelessWidget {
  const _PlayOrb();
  @override
  Widget build(BuildContext context) => Container(width: 68, height: 68, decoration: BoxDecoration(color: Colors.black.withValues(alpha: .38), shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 1.5)), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38));
}

class _Avatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double size;
  const _Avatar({required this.name, this.avatarUrl = '', this.size = 39});
  @override
  Widget build(BuildContext context) {
    final safeName = name.trim().isEmpty ? 'B' : name.trim();
    return Container(width: size, height: size, clipBehavior: Clip.antiAlias, decoration: const BoxDecoration(color: BenTokens.gold, shape: BoxShape.circle), child: avatarUrl.startsWith('http') ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(safeName)) : _initials(safeName));
  }
  Widget _initials(String safeName) => Center(child: Text(safeName.substring(0, 1).toUpperCase(), style: TextStyle(color: BenTokens.ink, fontWeight: FontWeight.w900, fontSize: size * .38)));
}

class BENDartIcon extends StatelessWidget {
  final bool active;
  const BENDartIcon({super.key, this.active = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _BENDartPainter(active: active)),
      );
}

class _BENDartPainter extends CustomPainter {
  final bool active;
  const _BENDartPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? BenTokens.gold : const Color(0xFFB8C0CC);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.7;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * .34, paint);
    canvas.drawCircle(center, size.width * .18, paint);
    final dart = Path()..moveTo(size.width * .08, size.height * .80)..lineTo(size.width * .78, size.height * .20);
    canvas.drawPath(dart, paint);
    final tip = Path()..moveTo(size.width * .78, size.height * .20)..lineTo(size.width * .60, size.height * .22)..lineTo(size.width * .76, size.height * .40)..close();
    canvas.drawPath(tip, paint);
  }

  @override
  bool shouldRepaint(covariant _BENDartPainter oldDelegate) => oldDelegate.active != active;
}

class BENFeatherIcon extends StatelessWidget {
  const BENFeatherIcon({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _BENFeatherPainter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .72))),
      );
}

class _BENFeatherPainter extends CustomPainter {
  final Color color;
  const _BENFeatherPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * .22, size.height * .82)
      ..cubicTo(size.width * .34, size.height * .58, size.width * .40, size.height * .20, size.width * .76, size.height * .16)
      ..cubicTo(size.width * .86, size.height * .40, size.width * .74, size.height * .70, size.width * .22, size.height * .82)
      ..moveTo(size.width * .27, size.height * .72)
      ..lineTo(size.width * .70, size.height * .28)
      ..moveTo(size.width * .40, size.height * .57)
      ..lineTo(size.width * .58, size.height * .48)
      ..moveTo(size.width * .33, size.height * .67)
      ..lineTo(size.width * .48, size.height * .63);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BENFeatherPainter oldDelegate) => oldDelegate.color != color;
}

class _MapMemoryButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _MapMemoryButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? BenTokens.cyan.withValues(alpha: .10) : Theme.of(context).colorScheme.onSurface.withValues(alpha: .035),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.map_outlined, size: 22, color: enabled ? BenTokens.cyan : Theme.of(context).colorScheme.onSurface.withValues(alpha: .25)),
          Positioned(right: 6, top: 6, child: Container(width: 12, height: 12, padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: BenTokens.gold, shape: BoxShape.circle), child: Image(image: AssetImage('assets/branding/ben_master_logo.png'), fit: BoxFit.contain))),
        ])),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ActionButton({this.icon, this.iconWidget, required this.label, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) {
    final color = active ? BenTokens.cyan : Theme.of(context).colorScheme.onSurface.withValues(alpha: .60);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [iconWidget ?? Icon(icon, size: 18, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: active ? BenTokens.cyan : null))]),
        ),
      ),
    );
  }
}
