import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/network/api_client.dart';
import '../models/memory.dart';
import '../services/auth_service.dart';
import 'community_screen.dart';
import 'memory_detail_screen.dart';
import 'notifications_screen.dart';

const _night = Color(0xFF07110F);
const _panel = Color(0xFF0E211E);
const _panelRaised = Color(0xFF142D28);
const _line = Color(0xFF205D53);
const _teal = Color(0xFF31D5C3);
const _tealSoft = Color(0xFF85C8BD);
const _gold = Color(0xFFE6C45D);
const _white = Color(0xFFE8F5F1);
const _muted = Color(0xFF9ABBB3);

class ProfileScreen extends StatefulWidget {
  final List<Memory> memories;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogout;
  final BenUser? currentUser;

  const ProfileScreen({
    super.key,
    required this.memories,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLogout,
    this.currentUser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int followers = 0;
  int followingCount = 0;
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadSocial();
  }

  Future<void> _loadSocial() async {
    final userId = widget.currentUser?.id;
    if (userId == null || userId <= 0) return;

    try {
      final data = await _api.get(
        'users/$userId',
        query: {'viewer_id': '$userId'},
      );
      if (!mounted) return;
      setState(() {
        followers = int.tryParse('${data['followers'] ?? 0}') ?? 0;
        followingCount = int.tryParse('${data['following'] ?? 0}') ?? 0;
      });
    } catch (_) {
      // Profil arayüzü çevrimdışıyken de kullanılabilir.
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileExperience(
      memories: widget.memories.where((m) => !m.isExpired).toList(),
      followers: followers,
      followingCount: followingCount,
      themeMode: widget.themeMode,
      onThemeChanged: widget.onThemeChanged,
      onLogout: widget.onLogout,
      username: widget.currentUser?.username ?? 'Bican',
    );
  }
}

class _ProfileExperience extends StatefulWidget {
  final List<Memory> memories;
  final int followers;
  final int followingCount;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogout;
  final String username;

  const _ProfileExperience({
    required this.memories,
    required this.followers,
    required this.followingCount,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLogout,
    required this.username,
  });

  @override
  State<_ProfileExperience> createState() => _ProfileExperienceState();
}

class _ProfileExperienceState extends State<_ProfileExperience> {
  final ApiClient _api = ApiClient();
  final ImagePicker _picker = ImagePicker();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  String _name = '';
  bool _editing = false;
  bool _saving = false;
  String _avatarPath = '';
  String _bio = '';
  String _bioFont = 'default';
  int _bioColor = 0xFFB9F7FF;

  @override
  void initState() {
    super.initState();
    _syncUser();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _syncUser() {
    final user = AuthService.currentUser;
    _name = user?.username ?? widget.username;
    _avatarPath = user?.avatarUrl ?? '';
    _bio = user?.bio ?? 'Anılar biriktikçe büyüyen kendi dünyam. 🌍';
    _bioFont = user?.bioFont ?? 'default';
    _bioColor = user?.bioColor ?? 0xFFB9F7FF;
  }

  List<Memory> get _pins =>
      widget.memories.where((m) => m.hasLocation).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<_RouteGroup> get _routes {
    final groups = <String, List<Memory>>{};
    for (final memory in _pins) {
      final date = memory.createdAt;
      final key = '${date.year}-${date.month}-${date.day}';
      groups.putIfAbsent(key, () => <Memory>[]).add(memory);
    }
    return groups.entries
        .map((entry) => _RouteGroup(dateKey: entry.key, memories: entry.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int get _revisitCount {
    final places = <String, int>{};
    for (final memory in _pins) {
      final key =
          '${memory.latitude!.toStringAsFixed(2)},${memory.longitude!.toStringAsFixed(2)}';
      places.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    return places.values.fold<int>(
      0,
      (sum, count) => sum + (count > 1 ? count - 1 : 0),
    );
  }

  TextStyle _bioStyle({double size = 13}) {
    final family = switch (_bioFont) {
      'serif' => 'serif',
      'mono' => 'monospace',
      _ => null,
    };
    return TextStyle(
      fontSize: size,
      height: 1.35,
      fontWeight: _bioFont == 'bold' ? FontWeight.w800 : FontWeight.w500,
      fontFamily: family,
      color: Color(_bioColor),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1200,
      );
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final avatars = Directory('${dir.path}/ben_avatars');
      if (!await avatars.exists()) {
        await avatars.create(recursive: true);
      }
      final target =
          File('${avatars.path}/avatar_${AuthService.currentUser?.id ?? 0}.jpg');
      await File(picked.path).copy(target.path);
      if (!mounted) return;
      setState(() => _avatarPath = target.path);
      _snack('Profil fotoğrafı hazır. Kaydetmeyi unutma.');
    } catch (_) {
      _snack('Fotoğraf seçilemedi.');
    }
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _panel,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profil fotoğrafı',
                  style: TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _teal),
                title: const Text('Galeriden seç', style: TextStyle(color: _white)),
                onTap: () {
                  Navigator.pop(sheet);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: _teal),
                title: const Text('Şimdi fotoğraf çek', style: TextStyle(color: _white)),
                onTap: () {
                  Navigator.pop(sheet);
                  _pickAvatar(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBioEditor() async {
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _BioEditorPage(
          initialBio: _bio,
          initialFont: _bioFont,
          initialColor: _bioColor,
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _bio = '${result['bio'] ?? ''}';
      _bioFont = '${result['font'] ?? 'default'}';
      _bioColor = result['color'] is int
          ? result['color'] as int
          : int.tryParse('${result['color']}') ?? _bioColor;
    });
  }

  Future<void> _saveProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      _snack('Profil kaydetmek için yeniden giriş yapmalısın.');
      return;
    }
    final username = _name.trim();
    if (username.length < 3) {
      _snack('Kullanıcı adı en az 3 karakter.');
      return;
    }

    setState(() => _saving = true);
    try {
      var avatarUrl = _avatarPath;
      if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
        final file = File(avatarUrl);
        if (await file.exists()) {
          avatarUrl = await _api.uploadFile(
            avatarUrl,
            field: 'avatar',
            endpoint: 'uploads/avatar',
          );
        }
      }
      final result = await _api.post(
        'users/profile',
        body: {
          'user_id': user.id,
          'username': username,
          'bio': _bio,
          'avatar_url': avatarUrl,
          'bio_font': _bioFont,
          'bio_color': _bioColor,
        },
      );
      AuthService.currentUser = BenUser.fromJson(
        Map<String, dynamic>.from(result['user'] as Map),
      );
      _avatarPath = AuthService.currentUser?.avatarUrl ?? avatarUrl;
      await AuthService.persistCurrentUser();
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
        _syncUserFromForm(username, avatarUrl);
      });
      _snack('Profil güncellendi.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.toString().replaceFirst('ApiException: ', ''));
    }
  }

  void _syncUserFromForm(String username, String avatarUrl) {
    _name = username;
    _avatarPath = AuthService.currentUser?.avatarUrl ?? avatarUrl;
    // Keep the just-edited biography visible even if the response omits fields.
  }

  Future<void> _showProfileShareSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _panel,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profili paylaş',
                  style: TextStyle(
                    color: _white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.ios_share_rounded, color: _teal),
                title: const Text('Profili paylaş', style: TextStyle(color: _white)),
                subtitle: Text('@$_name', style: const TextStyle(color: _muted)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await SharePlus.instance.share(
                    ShareParams(text: 'BEN profili: @$_name\n$_bio'),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: _teal),
                title: const Text('Kullanıcı adını kopyala', style: TextStyle(color: _white)),
                subtitle: Text('@$_name', style: const TextStyle(color: _muted)),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: '@$_name'));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  _snack('Kullanıcı adı kopyalandı.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProfileOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _panel,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil ayarları',
                style: TextStyle(
                  color: _white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: _teal),
                title: const Text('Profili düzenle', style: TextStyle(color: _white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _editing = true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_rounded, color: _teal),
                title: const Text('Profili paylaş', style: TextStyle(color: _white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showProfileShareSheet();
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Text(
                  'GÖRÜNÜM',
                  style: TextStyle(
                    color: _tealSoft,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _ThemeChip(
                    label: 'Sistem',
                    selected: widget.themeMode == ThemeMode.system,
                    onTap: () {
                      widget.onThemeChanged(ThemeMode.system);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  _ThemeChip(
                    label: 'Açık',
                    selected: widget.themeMode == ThemeMode.light,
                    onTap: () {
                      widget.onThemeChanged(ThemeMode.light);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  _ThemeChip(
                    label: 'Koyu',
                    selected: widget.themeMode == ThemeMode.dark,
                    onTap: () {
                      widget.onThemeChanged(ThemeMode.dark);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined, color: _gold),
                title: const Text('Rozetlerim', style: TextStyle(color: _white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showBadges();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF8B8B)),
                title: const Text('Çıkış yap', style: TextStyle(color: _white)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: _panel,
                      title: const Text('Çıkış yapılsın mı?', style: TextStyle(color: _white)),
                      content: const Text(
                        'BEN hesabından çıkış yapacaksın.',
                        style: TextStyle(color: _muted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Vazgeç'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Çıkış yap'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) widget.onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBadges() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _panel,
      builder: (_) => const SizedBox(
        height: 560,
        child: _BadgesTab(),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  ImageProvider? _avatarProvider() {
    final path = _avatarPath;
    if (path.isNotEmpty && path.startsWith('http')) {
      return NetworkImage(path);
    }
    if (path.isNotEmpty && File(path).existsSync()) {
      return FileImage(File(path));
    }
    return null;
  }

  Widget _avatar({double size = 46}) {
    final provider = _avatarProvider();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _teal, width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24584F), Color(0xFF07110F)],
        ),
        image: provider == null
            ? null
            : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: provider == null
          ? Icon(Icons.person_rounded, size: size * .55, color: _teal)
          : null,
    );
  }

  void _showMemory(Memory memory) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memory)),
    );
  }

  void _resetPanel() {
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      .50,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  List<_RouteGroup> _makeRoutes() => _routes;

  @override
  Widget build(BuildContext context) {
    final pins = _pins;
    final routes = _makeRoutes();
    final photoCount = widget.memories.where((m) => m.type == MemoryType.photo).length;
    final textCount = widget.memories.where((m) => m.type == MemoryType.text).length;
    final videoCount = widget.memories.where((m) => m.type == MemoryType.video).length;
    final visibleMarkers = pins.take(120).toList();

    return ColoredBox(
      color: _night,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Darkened OSM tiles keep the map real and do not require a map API key.
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(45.5, 15.0),
              initialZoom: 2.65,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.benapp.mobile',
                tileBuilder: (context, tileWidget, _) => ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.02, 0.01, 0.005, 0, 1,
                    0.005, 0.06, 0.015, 0, 3,
                    0.005, 0.025, 0.07, 0, 6,
                    0, 0, 0, 1, 0,
                  ]),
                  child: tileWidget,
                ),
              ),
              MarkerLayer(
                markers: visibleMarkers.map((memory) {
                  return Marker(
                    point: LatLng(memory.latitude!, memory.longitude!),
                    width: 28,
                    height: 34,
                    child: const _ProfileMapPin(),
                  );
                }).toList(),
              ),
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          const _MapAtmosphere(),
          const Positioned(
            left: 12,
            top: 142,
            child: Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                color: Color(0x997FC1B5),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: Row(
                children: [
                  _RoundAction(
                    icon: Icons.home_outlined,
                    tooltip: 'Profil panelini daralt',
                    onTap: _resetPanel,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _editing ? _showPhotoOptions : _showProfileOptions,
                      child: Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xE9081715),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _line.withValues(alpha: .85)),
                        ),
                        child: Row(
                          children: [
                            _avatar(size: 46),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _editing ? 'Profili düzenliyorsun' : _name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '@${_name.toLowerCase()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _tealSoft,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: _gold.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _gold.withValues(alpha: .7)),
                              ),
                              child: const Text(
                                'BEN',
                                style: TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundAction(
                    icon: Icons.groups_2_outlined,
                    tooltip: 'Topluluk',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CommunityScreen()),
                    ),
                  ),
                  const SizedBox(width: 7),
                  _RoundAction(
                    icon: Icons.settings_outlined,
                    tooltip: 'Profil ayarları',
                    onTap: _showProfileOptions,
                  ),
                  const SizedBox(width: 7),
                  _RoundAction(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Bildirimler',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                ],
              ),
          ),
          Positioned(
            left: 46,
            right: 24,
            top: 91,
            child: const _PinDensityLegend(),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: .50,
            minChildSize: .42,
            maxChildSize: .94,
            snap: true,
            snapSizes: const [.50, .72, .94],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _panel.withValues(alpha: .985),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: _line, width: 1.4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(29)),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 11, 15, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: .65),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: GestureDetector(
                            onTap: _editing ? _showBioEditor : null,
                            child: Text(
                              _bio.isEmpty ? '${_name}’in dünyası' : _bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: _bioStyle(size: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 19),
                        if (_editing) ...[
                          _ProfileEditPanel(
                            name: _name,
                            bio: _bio,
                            saving: _saving,
                            onNameChanged: (value) => setState(() => _name = value),
                            onEditBio: _showBioEditor,
                            onPhoto: _showPhotoOptions,
                            onSave: _saveProfile,
                            onCancel: () {
                              setState(() {
                                _editing = false;
                                _syncUser();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        _StatsPanel(
                          items: [
                            _ProfileMetric('${pins.length}', 'PINS'),
                            _ProfileMetric('${routes.length}', 'ROTA GÜNÜ'),
                            _ProfileMetric('${widget.memories.length}', 'ANILAR'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _InfoChip(
                                icon: Icons.verified_user_rounded,
                                value: '${pins.length}',
                                label: 'konumlu',
                              ),
                              const SizedBox(width: 7),
                              _InfoChip(
                                icon: Icons.flight_takeoff_rounded,
                                value: '${routes.length}',
                                label: 'rota günü',
                              ),
                              const SizedBox(width: 7),
                              _InfoChip(
                                icon: Icons.repeat_rounded,
                                value: '$_revisitCount',
                                label: 'tekrar ziyaret',
                                valueColor: _gold,
                              ),
                              const SizedBox(width: 7),
                              _InfoChip(
                                icon: Icons.photo_camera_outlined,
                                value: '$photoCount',
                                label: 'fotoğraf',
                              ),
                              const SizedBox(width: 7),
                              _InfoChip(
                                icon: Icons.people_alt_outlined,
                                value: '${widget.followers}',
                                label: 'takipçi',
                              ),
                              const SizedBox(width: 7),
                              _InfoChip(
                                icon: Icons.person_add_alt_1_outlined,
                                value: '${widget.followingCount}',
                                label: 'takip',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SectionHeading(
                          title: 'Öne çıkan rotalar',
                          icon: Icons.flight_takeoff_rounded,
                          count: '${routes.length}',
                        ),
                        const SizedBox(height: 12),
                        if (routes.isEmpty)
                          const _EmptyFeature(
                            icon: Icons.route_outlined,
                            title: 'Rotan henüz oluşmadı',
                            subtitle: 'Konum eklediğin anılar burada tarihe göre gruplanır.',
                          )
                        else
                          SizedBox(
                            height: 191,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: routes.length > 8 ? 8 : routes.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final route = routes[index];
                                return _RouteCard(
                                  route: route,
                                  onTap: () {
                                    final memory = route.memories.first;
                                    _showMemory(memory);
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 22),
                        _SectionHeading(
                          title: 'Öne çıkan pinler',
                          icon: Icons.location_on_rounded,
                          count: '${pins.length}',
                        ),
                        const SizedBox(height: 12),
                        if (pins.isEmpty)
                          const _EmptyFeature(
                            icon: Icons.location_searching_rounded,
                            title: 'Haritanda henüz pin yok',
                            subtitle: 'Bir anıya konum eklediğinde burada görebileceksin.',
                          )
                        else
                          SizedBox(
                            height: 152,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: pins.length > 10 ? 10 : pins.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final memory = pins[index];
                                return _PinCard(
                                  memory: memory,
                                  onTap: () => _showMemory(memory),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 23),
                        _SectionHeading(
                          title: 'Rozetler',
                          icon: Icons.workspace_premium_rounded,
                          count: 'GÖR',
                          onTap: _showBadges,
                        ),
                        const SizedBox(height: 11),
                        _BadgePreview(onTap: _showBadges),
                        const SizedBox(height: 20),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: _showProfileShareSheet,
                            icon: const Icon(Icons.ios_share_rounded, size: 17),
                            label: const Text('Profili paylaş'),
                            style: TextButton.styleFrom(foregroundColor: _tealSoft),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapAtmosphere extends StatelessWidget {
  const _MapAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _night.withValues(alpha: .42),
              _night.withValues(alpha: .27),
              _night.withValues(alpha: .44),
              _night.withValues(alpha: .68),
            ],
            stops: const [0, .28, .62, 1],
          ),
        ),
      ),
    );
  }
}

class _ProfileMapPin extends StatelessWidget {
  const _ProfileMapPin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _teal.withValues(alpha: .25),
          boxShadow: const [BoxShadow(color: Color(0x5531D5C3), blurRadius: 14)],
          border: Border.all(color: _teal.withValues(alpha: .8), width: 1),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _teal,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE8081715),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _line.withValues(alpha: .9)),
          ),
          child: Icon(icon, color: _teal, size: 20, semanticLabel: tooltip),
        ),
      ),
    );
  }
}

class _PinDensityLegend extends StatelessWidget {
  const _PinDensityLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'PIN DENSITY',
          style: TextStyle(
            color: _tealSoft,
            fontSize: 9,
            letterSpacing: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _DensityEntry(color: Color(0xFF16483F), label: '1'),
              SizedBox(width: 6),
              _DensityEntry(color: Color(0xFF258D7C), label: '2–4'),
              SizedBox(width: 6),
              _DensityEntry(color: Color(0xFF2CC5B2), label: '5–10'),
              SizedBox(width: 6),
              _DensityEntry(color: Color(0xFF61E9D8), label: '11+'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DensityEntry extends StatelessWidget {
  final Color color;
  final String label;
  const _DensityEntry({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProfileMetric {
  final String value;
  final String label;
  const _ProfileMetric(this.value, this.label);
}

class _StatsPanel extends StatelessWidget {
  final List<_ProfileMetric> items;
  const _StatsPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 18, 5, 17),
      decoration: BoxDecoration(
        color: const Color(0xFF102823),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 38, color: _line),
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i].value,
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    items[i].label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _tealSoft,
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color valueColor;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor = _teal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF18352E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: valueColor, size: 14),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final IconData icon;
  final String count;
  final VoidCallback? onTap;

  const _SectionHeading({
    required this.title,
    required this.icon,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, color: _teal, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            count,
            style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, color: _tealSoft, size: 22),
        ],
      ],
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: row,
        ),
      ),
    );
  }
}

class _RouteGroup {
  final String dateKey;
  final List<Memory> memories;
  const _RouteGroup({required this.dateKey, required this.memories});

  DateTime get date {
    final parts = dateKey.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  Memory? get coverMemory {
    for (final memory in memories) {
      if (memory.photo != null && memory.photo!.existsSync()) return memory;
    }
    return null;
  }
}

class _RouteCard extends StatelessWidget {
  final _RouteGroup route;
  final VoidCallback onTap;
  const _RouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cover = route.coverMemory;
    return SizedBox(
      width: 208,
      child: Material(
        color: const Color(0xFF122923),
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _line.withValues(alpha: .9)),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (route.coverMemory?.photo != null &&
                          route.coverMemory!.photo!.existsSync())
                        Image.file(route.coverMemory!.photo!, fit: BoxFit.cover)
                      else
                        const _ScenicFallback(icon: Icons.route_rounded),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x22000000), Color(0x77000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _MiniTag(text: '${route.memories.length} durak'),
                      ),
                      const Positioned(
                        right: 10,
                        top: 10,
                        child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 19),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anı rotası',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(route.date),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
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

class _PinCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  const _PinCard({required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = memory.photo;
    return SizedBox(
      width: 165,
      child: Material(
        color: const Color(0xFF142D28),
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photo != null && photo.existsSync())
                        Image.file(photo, fit: BoxFit.cover)
                      else
                        const _ScenicFallback(icon: Icons.location_on_rounded),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x11000000), Color(0x77000000)],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 9,
                        top: 9,
                        child: Icon(Icons.location_on_rounded, color: _teal, size: 20),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 8, 9),
                  child: Text(
                    _coordinatesLabel(memory),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
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

class _ScenicFallback extends StatelessWidget {
  final IconData icon;
  const _ScenicFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173D36), Color(0xFF07110F), Color(0xFF24584D)],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 35, color: _teal.withValues(alpha: .85)),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xCC07110F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _teal.withValues(alpha: .35)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _white, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 21),
      decoration: BoxDecoration(
        color: const Color(0xFF102823),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 27),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  final VoidCallback onTap;
  const _BadgePreview({required this.onTap});

  static const _badges = [
    ('İlk Anı', Icons.flag_rounded),
    ('Gezgin', Icons.explore_rounded),
    ('Fotoğrafçı', Icons.camera_alt_rounded),
    ('Kaşif', Icons.travel_explore_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF102823),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              for (final badge in _badges) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _panelRaised,
                          border: Border.all(color: _teal.withValues(alpha: .65)),
                        ),
                        child: Icon(badge.$2, color: _teal, size: 19),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        badge.$1,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
              const Icon(Icons.chevron_right_rounded, color: _tealSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditPanel extends StatelessWidget {
  final String name;
  final String bio;
  final bool saving;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onEditBio;
  final VoidCallback onPhoto;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ProfileEditPanel({
    required this.name,
    required this.bio,
    required this.saving,
    required this.onNameChanged,
    required this.onEditBio,
    required this.onPhoto,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF102823),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil bilgilerini düzenle',
            style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: name,
            onChanged: onNameChanged,
            style: const TextStyle(color: _white),
            decoration: const InputDecoration(
              labelText: 'Kullanıcı adı',
              labelStyle: TextStyle(color: _muted),
              prefixIcon: Icon(Icons.alternate_email_rounded, color: _teal),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _line)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _teal)),
            ),
          ),
          const SizedBox(height: 9),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo_camera_outlined, color: _teal),
            title: const Text('Profil fotoğrafını değiştir', style: TextStyle(color: _white, fontSize: 13)),
            onTap: onPhoto,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_note_rounded, color: _teal),
            title: const Text('Bio ve yazı stilini düzenle', style: TextStyle(color: _white, fontSize: 13)),
            subtitle: Text(bio, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
            onTap: onEditBio,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Kaydediliyor' : 'Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _teal.withValues(alpha: .17),
      backgroundColor: const Color(0xFF142D28),
      labelStyle: TextStyle(
        color: selected ? _teal : _white,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: selected ? _teal : _line),
    );
  }
}

class _BioEditorPage extends StatefulWidget {
  final String initialBio;
  final String initialFont;
  final int initialColor;

  const _BioEditorPage({
    required this.initialBio,
    required this.initialFont,
    required this.initialColor,
  });

  @override
  State<_BioEditorPage> createState() => _BioEditorPageState();
}

class _BioEditorPageState extends State<_BioEditorPage> {
  late String _bio;
  late String _font;
  late int _color;

  @override
  void initState() {
    super.initState();
    _bio = widget.initialBio;
    _font = widget.initialFont;
    _color = widget.initialColor;
  }

  TextStyle _previewStyle() {
    return TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: _font == 'bold' ? FontWeight.w800 : FontWeight.w500,
      fontFamily: _font == 'serif'
          ? 'serif'
          : _font == 'mono'
              ? 'monospace'
              : null,
      color: Color(_color),
    );
  }

  Widget _fontChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _font == value,
      onSelected: (_) => setState(() => _font = value),
    );
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    Navigator.of(context).pop(<String, dynamic>{
      'bio': _bio.trim(),
      'font': _font,
      'color': _color,
    });
  }

  @override
  Widget build(BuildContext context) {
    const colors = <int>[
      0xFFB9F7FF,
      0xFFFFFFFF,
      0xFF7BE7FF,
      0xFFB7FF9B,
      0xFFFFD36E,
      0xFFFF8FB3,
      0xFFD5B4FF,
    ];

    return Scaffold(
      backgroundColor: _night,
      appBar: AppBar(
        backgroundColor: _panel,
        foregroundColor: _white,
        title: const Text('Bio düzenle'),
        leading: IconButton(
          tooltip: 'Kapat',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            TextFormField(
              initialValue: _bio,
              onChanged: (value) => setState(() => _bio = value),
              minLines: 4,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(color: _white),
              decoration: InputDecoration(
                hintText: 'Kendinden biraz bahset...',
                hintStyle: const TextStyle(color: _muted),
                filled: true,
                fillColor: _panel,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(Icons.edit_note_rounded, color: _teal),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Yazı tipi', style: TextStyle(color: _white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _fontChip('Standart', 'default'),
                _fontChip('Serif', 'serif'),
                _fontChip('Mono', 'mono'),
                _fontChip('Kalın', 'bold'),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Renk', style: TextStyle(color: _white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(color),
                      border: Border.all(
                        color: _color == color ? _teal : Colors.white24,
                        width: _color == color ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _panel,
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Önizleme', style: TextStyle(color: _white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(_bio.isEmpty ? 'BEN dünyam...' : _bio, style: _previewStyle()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Bioyu kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    const badges = [
      ('İlk Anı', Icons.flag_rounded),
      ('Gezgin', Icons.explore_rounded),
      ('Fotoğrafçı', Icons.camera_alt_rounded),
      ('Sosyal', Icons.people_alt_rounded),
      ('Müzik Ruhu', Icons.music_note_rounded),
      ('Gece Kuşu', Icons.nightlight_rounded),
      ('Kaşif', Icons.travel_explore_rounded),
      ('Yaratıcı', Icons.auto_awesome_rounded),
    ];
    return Material(
      color: _panel,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        children: [
          const Text(
            'Rozetlerim',
            style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF142D28),
              border: Border.all(color: _line),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _teal,
                  child: Text(
                    'BEN',
                    style: TextStyle(color: _night, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keşif yolculuğun', style: TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Rozetler ilerlemeni ve katılımını gösterir.', style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: .8,
            ),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF142D28),
                      border: Border.all(color: _teal.withValues(alpha: .65)),
                    ),
                    child: Icon(badge.$2, color: _teal),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.$1,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _coordinatesLabel(Memory memory) {
  final latitude = memory.latitude;
  final longitude = memory.longitude;
  if (latitude == null || longitude == null) return 'Konum pini';
  final latDirection = latitude >= 0 ? 'K' : 'G';
  final lonDirection = longitude >= 0 ? 'D' : 'B';
  return '${latitude.abs().toStringAsFixed(2)}°$latDirection · '
      '${longitude.abs().toStringAsFixed(2)}°$lonDirection';
}
