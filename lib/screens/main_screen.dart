import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../core/theme/app_tokens.dart';
import '../core/network/api_client.dart';
import '../features/memories/data/php_memory_repository.dart';
import '../features/messages/presentation/messages_screen.dart';

import '../models/memory.dart';
import '../services/auth_service.dart';
import '../services/memory_repository.dart';
import '../widgets/memory_menu.dart';
import '../widgets/ben_nav_icons.dart';
import '../widgets/ben_brand_header.dart';
import 'create_memory_screen.dart';
import 'home_screen.dart';
import 'ben_3d_map_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'live_screen.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogout;
  final BenUser? currentUser;

  const MainScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLogout,
    this.currentUser,
  });

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState
    extends State<MainScreen> {
  final MemoryRepository _repository =
      MemoryRepository();
  final PhpMemoryRepository _phpRepository = PhpMemoryRepository(ApiClient());

  int _selectedIndex = 0;

  List<Memory> _memories = [];
  List<Memory> _connectionMemories = [];
  Memory? _mapFocusMemory;

  bool _loadingMemories = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMemories() async {
    try {
      final remote = await _phpRepository.list(userId: widget.currentUser?.id ?? 1, scope: 'discover');
      final connections = await _phpRepository.list(userId: widget.currentUser?.id ?? 1, scope: 'following');
      if (!mounted) return;
      setState(() {
        _memories = remote.where((m) => !m.isExpired).toList();
        _connectionMemories = connections.where((m) => !m.isExpired).toList();
        _loadingMemories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _memories = const []; _connectionMemories = const []; _loadingMemories = false; });
      _showMessage('BEN sunucusuna bağlanılamadı. İnternet ve sunucu bağlantısını kontrol et.');
    }
  }

  Future<void> _refreshMemories() async {
    try {
      final remote = await _phpRepository.list(userId: widget.currentUser?.id ?? 1, scope: 'discover');
      final connections = await _phpRepository.list(userId: widget.currentUser?.id ?? 1, scope: 'following');
      if (!mounted) return;
      setState(() {
        _memories = remote.where((m) => !m.isExpired).toList();
        _connectionMemories = connections.where((m) => !m.isExpired).toList();
      });
    } catch (_) {
      if (mounted) _showMessage('BEN sunucusuna bağlanılamadı.');
    }
  }

  Future<void> _handleMemoryAction(MemoryAction action) async {
    if (action == MemoryAction.live) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveScreen()));
      return;
    }
    if (action == MemoryAction.music) {
      _showMessage('Müzik anısı için ses dosyası seçimi yakında eklenecek.');
      return;
    }
    final type = switch (action) {
      MemoryAction.text => MemoryActionType.text,
      MemoryAction.photo => MemoryActionType.photo,
      MemoryAction.video => MemoryActionType.video,
      MemoryAction.location => MemoryActionType.location,
      MemoryAction.music => MemoryActionType.text,
      MemoryAction.live => MemoryActionType.text,
    };
    final memory = await Navigator.push<Memory>(context, MaterialPageRoute(builder: (_) => CreateMemoryScreen(initialType: type)));
    if (memory == null || !mounted) return;
    if (memory.type == MemoryType.location && !memory.hasLocation) {
      _showMessage('Konum alınamadı. Konum hizmetini açıp tekrar dene.');
      return;
    }
    setState(() {});
    Memory storedMemory = memory;
    try {
      var remoteMemory = memory;
      if (memory.photo != null && await memory.photo!.exists()) {
        final url = await ApiClient().uploadFile(memory.photo!.path, field: 'media', endpoint: 'uploads/media');
        remoteMemory = memory.copyWith(mediaUrl: url);
      } else if (memory.video != null) {
        final file = File(memory.video!);
        if (await file.exists()) {
          final url = await ApiClient().uploadFile(file.path, field: 'media', endpoint: 'uploads/media');
          remoteMemory = memory.copyWith(mediaUrl: url);
        }
      }
      final remoteId = await _phpRepository.create(remoteMemory, userId: widget.currentUser?.id ?? 1);
      if (remoteId == null) throw const ApiException('Sunucu anı için bir kayıt kimliği döndürmedi.');
      storedMemory = memory.copyWith(id: remoteId.toString(), mediaUrl: remoteMemory.mediaUrl);
      await _repository.remove(memory.id);
      await _repository.add(storedMemory);
    } catch (e) {
      if (mounted) _showMessage('Anı sunucuya kaydedilemedi. Tekrar deneyebilirsin.');
      return;
    }
    if (!mounted) return;
    setState(() {
      // Sunucu ID'si varsa yerel anıyla birlikte saklıyoruz. Böylece yorumlar
      // aynı anının kalıcı API kaydına bağlanabilir.
      if (!_memories.any((existing) => existing.id == storedMemory.id)) {
        _memories = [storedMemory, ..._memories];
      }
      _selectedIndex = storedMemory.type == MemoryType.location ? 1 : 0;
    });
    _showMessage('Anın BEN dünyasına bırakıldı.');
  }

  Future<void> _deleteMemory(
    Memory memory,
  ) async {
    await _repository.remove(
      memory.id,
    );

    await _refreshMemories();

    if (!mounted) return;

    _showMessage(
      'Anı silindi.',
    );
  }

  Future<void> _openMemoryMenu() async {
    await MemoryMenu.show(
      context,
      onSelected:
          _handleMemoryAction,
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final pages = <Widget>[
      HomeScreen(
        key: const PageStorageKey('ben-home'),
        memories: _memories,
        connectionMemories: _connectionMemories,
        currentUser: widget.currentUser,
        onDelete: _deleteMemory,
        onCreate: _openMemoryMenu,
        onOpenLive: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveScreen())),
        onOpenMap: (memory) => setState(() { _mapFocusMemory = memory; _selectedIndex = 1; }),
      ),
      // MapLibre is a native platform view. Keep it lazy so iOS does not
      // instantiate the native map while the BEN home page is still active.
      // It is created only when the map tab is actually selected.
      _selectedIndex == 1
          ? Ben3DMapScreen(
              key: const PageStorageKey('ben-world-map'),
              memories: _memories,
              embedded: true,
              focusMemory: _mapFocusMemory,
            )
          : const SizedBox.shrink(key: PageStorageKey('ben-world-map-placeholder')),
      const SizedBox.shrink(key: PageStorageKey('ben-create-placeholder')),
      const MessagesScreen(key: PageStorageKey('ben-messages')),
      ProfileScreen(
        key: const PageStorageKey('ben-profile'),
        memories: _memories,
        currentUser: widget.currentUser,
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _globalTopBar(context),
            Expanded(
              child: _loadingMemories
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.secondary,
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        IndexedStack(
                          index: _selectedIndex,
                          children: pages,
                        )
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? const [Color(0xF00E1C27), Color(0xE807121A)]
                      : const [Color(0xF9FFFFFF), Color(0xF0EEF5F6)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: BenTokens.cyan.withValues(alpha: .16)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .34 : .10), blurRadius: 36, offset: const Offset(0, 12))],
              ),
              child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navigationItem(BENNavIconType.ben, 'BEN', 0),
            _navigationItem(BENNavIconType.map, 'Harita', 1),
            _createNavigationItem(),
            _navigationItem(BENNavIconType.messages, 'Mesajlar', 3),
            _navigationItem(BENNavIconType.profile, 'Profil', 4),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _globalTopBar(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final showSearch = _selectedIndex == 0 || _selectedIndex == 3;
    final showNotifications = _selectedIndex == 0;
    final showMenu = _selectedIndex == 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: dark ? const Color(0xAA0B1721) : const Color(0xEFFFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BenTokens.cyan.withValues(alpha: .14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .18 : .06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                const BENBrandHeader(subtitle: 'insan • zaman • yer • anı'),
                const Spacer(),
                if (showNotifications)
                  _topAction(
                    Icons.notifications_none_rounded,
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                if (showSearch)
                  _topAction(Icons.search_rounded, () => _showGlobalSearch(context)),
                if (showMenu)
                  _topAction(Icons.more_horiz_rounded, () => _showGlobalMenu(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topAction(IconData icon, VoidCallback onTap) {
    return IconButton(
      tooltip: 'Menü',
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon),
    );
  }

  void _showGlobalSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Ara...',
            ),
          ),
        ),
      ),
    );
  }

  void _showGlobalMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Ayarlar'), onTap: () { Navigator.pop(sheetContext); Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged))); }),
            ListTile(leading: const Icon(Icons.lock_outline_rounded), title: const Text('Gizlilik ve güvenlik'), onTap: () => Navigator.pop(sheetContext)),
            ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Çıkış yap'), onTap: () { Navigator.pop(sheetContext); widget.onLogout(); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _createNavigationItem() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: _openMemoryMenu,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BenTokens.cyanBright, BenTokens.cyan],
              ),
              boxShadow: [
                BoxShadow(
                  color: BenTokens.cyan.withValues(alpha: dark ? .34 : .22),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: BenTokens.ink,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationItem(BENNavIconType type, String label, int index) {
    final selected = _selectedIndex == index;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = dark ? BenTokens.cyan : const Color(0xFF0E1014);
    final mutedColor = dark
        ? Colors.white.withValues(alpha: .48)
        : Colors.black.withValues(alpha: .42);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (type == BENNavIconType.create) {
            _openMemoryMenu();
            return;
          }
          if (_selectedIndex == index) return;
          if (!mounted) return;
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 48 : 42,
                height: 31,
                decoration: BoxDecoration(
                  color: selected
                      ? BenTokens.cyan.withValues(alpha: dark ? .16 : .14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: BENNavIcon(type: type, selected: selected, size: 24),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: selected ? selectedColor : mutedColor,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
