import 'dart:io';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/memory.dart';
import '../core/network/api_client.dart';
import '../services/auth_service.dart';
import 'memory_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final List<Memory> memories;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogout;
  final BenUser? currentUser;
  const ProfileScreen({super.key, required this.memories, required this.themeMode, required this.onThemeChanged, required this.onLogout, this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool following = false;
  int followers = 0;
  int followingCount = 0;
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadSocial();
  }

  Future<void> _loadSocial() async {
    final userId = widget.currentUser?.id;
    if (userId == null || userId <= 0) {
      return;
    }
    try {
      final data = await _api.get('users/$userId', query: {'viewer_id': '$userId'});
      if (!mounted) return;
      setState(() {
        followers = int.tryParse('${data['followers'] ?? 0}') ?? 0;
        followingCount = int.tryParse('${data['following'] ?? 0}') ?? 0;
        following = data['following_me'] == true;
      });
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      physics: const BouncingScrollPhysics(),
      headerSliverBuilder: (context, inner) => [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            memories: widget.memories,
            followers: followers,
            followingCount: followingCount,
            following: following,
            themeMode: widget.themeMode,
            onThemeChanged: widget.onThemeChanged,
            onLogout: widget.onLogout,
            username: widget.currentUser?.username ?? 'Bican',
            email: widget.currentUser?.email ?? '',
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabHeader(_tabs),
        ),
      ],
      body: TabBarView(
        controller: _tabs,
        children: [
          _TreeTab(memories: widget.memories),
          const _BadgesTab(),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final List<Memory> memories;
  final int followers;
  final int followingCount;
  final bool following;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogout;
  final String username;
  final String email;

  const _ProfileHeader({
    required this.memories,
    required this.followers,
    required this.followingCount,
    required this.following,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLogout,
    required this.username,
    required this.email,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  final ApiClient _api = ApiClient();
  final ImagePicker _picker = ImagePicker();
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

  void _syncUser() {
    final user = AuthService.currentUser;
    _name = user?.username ?? widget.username;
    _avatarPath = user?.avatarUrl ?? '';
    _bio = user?.bio ?? 'Anılar biriktikçe büyüyen kendi dünyam. 🌱';
    _bioFont = user?.bioFont ?? 'default';
    _bioColor = user?.bioColor ?? 0xFFB9F7FF;
  }


  TextStyle _bioStyle() {
    final family = switch (_bioFont) {
      'serif' => 'serif',
      'mono' => 'monospace',
      'bold' => null,
      _ => null,
    };
    return TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: _bioFont == 'bold' ? FontWeight.w800 : FontWeight.w500,
      fontFamily: family,
      color: Color(_bioColor),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 88, maxWidth: 1200);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final avatars = Directory('${dir.path}/ben_avatars');
      if (!await avatars.exists()) await avatars.create(recursive: true);
      final target = File('${avatars.path}/avatar_${AuthService.currentUser?.id ?? 0}.jpg');
      await File(picked.path).copy(target.path);
      if (!mounted) return;
      setState(() => _avatarPath = target.path);
      _snack('Profil fotoğrafı hazır. Kaydetmeyi unutma.');
    } catch (e) {
      _snack('Fotoğraf seçilemedi.');
    }
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Profil fotoğrafı', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              const SizedBox(height: 8),
              ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Galeriden seç'), onTap: () { Navigator.pop(sheet); _pickAvatar(ImageSource.gallery); }),
              ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Şimdi fotoğraf çek'), onTap: () { Navigator.pop(sheet); _pickAvatar(ImageSource.camera); }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBioEditor() async {
    if (!mounted) return;

    // Profildeki kullanıcı adı alanı odaktaysa, aynı frame içinde yeni route
    // açmak Flutter'ın Focus/InheritedWidget ağacında _dependents.isEmpty
    // assertion'ına yol açabiliyor. Önce odağı tamamen bırakıp bir frame
    // bekliyoruz; ardından bio editörünü açıyoruz.
    FocusManager.instance.primaryFocus?.unfocus(disposition: UnfocusDisposition.scope);
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
    final nextBio = '${result['bio'] ?? ''}';
    final nextFont = '${result['font'] ?? 'default'}';
    final nextColor = result['color'] is int
        ? result['color'] as int
        : int.tryParse('${result['color']}') ?? _bioColor;

    setState(() {
      _bio = nextBio;
      _bioFont = nextFont;
      _bioColor = nextColor;
    });
  }

  Future<void> _saveProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final username = _name.trim();
    if (username.length < 3) { _snack('Kullanıcı adı en az 3 karakter.'); return; }
    setState(() => _saving = true);
    try {
      var avatarUrl = _avatarPath;
      if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
        final file = File(avatarUrl);
        if (await file.exists()) avatarUrl = await _api.uploadFile(avatarUrl, field: 'avatar', endpoint: 'uploads/avatar');
      }
      final result = await _api.post('users/profile', body: {
        'user_id': user.id,
        'username': username,
        'bio': _bio,
        'avatar_url': avatarUrl,
        'bio_font': _bioFont,
        'bio_color': _bioColor,
      });
      AuthService.currentUser = BenUser.fromJson(Map<String, dynamic>.from(result['user'] as Map));
      _avatarPath = AuthService.currentUser?.avatarUrl ?? avatarUrl;
      await AuthService.persistCurrentUser();
      if (!mounted) return;
      setState(() { _editing = false; _saving = false; });
      _snack('Profil güncellendi.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.toString().replaceFirst('ApiException: ', ''));
    }
  }

  Future<void> _showProfileShareSheet(BuildContext context, String username) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Profili paylaş', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
            const SizedBox(height: 12),
            ListTile(leading: const Icon(Icons.ios_share_rounded), title: const Text('Profili paylaş'), subtitle: Text('@$username'), onTap: () async { Navigator.pop(sheetContext); await SharePlus.instance.share(ShareParams(text: 'BEN profili: @$username\n$_bio')); }),
            ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Kullanıcı adını kopyala'), subtitle: Text('@$username'), onTap: () async { await Clipboard.setData(ClipboardData(text: '@$username')); if (sheetContext.mounted) Navigator.pop(sheetContext); _snack('Kullanıcı adı kopyalandı.'); }),
          ]),
        ),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
  }

  Widget _avatar() {
    final path = _avatarPath;
    ImageProvider? provider;
    if (path.isNotEmpty && path.startsWith('http')) {
      provider = NetworkImage(path);
    } else if (path.isNotEmpty && File(path).existsSync()) {
      provider = FileImage(File(path));
    }
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5DEBFF), width: 2),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF173344), Color(0xFF07111B)]),
        image: provider == null ? null : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: provider == null ? const Icon(Icons.person_rounded, size: 43, color: Color(0xFF8CEEFF)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = AuthService.currentUser;
    final username = current?.username ?? widget.username;
    final locations = widget.memories.where((m) => m.hasLocation).length;
    final years = _yearCount(widget.memories);
    final level = math.max(1, (widget.memories.length ~/ 4) + 1);
    final xp = widget.memories.length * 120;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              GestureDetector(onTap: _editing ? _showPhotoOptions : null, child: _avatar()),
              if (_editing) ...[
                const SizedBox(height: 6),
                GestureDetector(onTap: _showPhotoOptions, child: const Text('Değiştirmek için dokunun', style: TextStyle(fontSize: 10, color: Color(0xFF5DEBFF), fontWeight: FontWeight.w800))),
                const SizedBox(height: 5),
                Row(children: [
                  IconButton(tooltip: 'Galeriden seç', visualDensity: VisualDensity.compact, onPressed: () => _pickAvatar(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined, size: 19)),
                  IconButton(tooltip: 'Fotoğraf çek', visualDensity: VisualDensity.compact, onPressed: () => _pickAvatar(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined, size: 19)),
                ]),
              ],
            ]),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_editing) TextFormField(initialValue: _name, onChanged: (value) => _name = value, decoration: const InputDecoration(labelText: 'Kullanıcı adı', isDense: true, prefixIcon: Icon(Icons.alternate_email_rounded)))
              else Text(username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              if (!_editing) Text('@${username.toLowerCase()}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))),
              const SizedBox(height: 7),
              GestureDetector(
                onTap: _editing ? _showBioEditor : null,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: _editing ? BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF5DEBFF).withValues(alpha: .18)), color: const Color(0xFF0E202A).withValues(alpha: .45)) : null,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(_bio.isEmpty ? 'Bio eklemek için tıkla.' : _bio, maxLines: 4, overflow: TextOverflow.ellipsis, style: _bioStyle())),
                    if (_editing) const Padding(
                      padding: EdgeInsets.only(left: 8, top: 1),
                      child: Text('🪶', style: TextStyle(fontSize: 21)),
                    ),
                  ]),
                ),
              ),
              if (_editing) const Padding(padding: EdgeInsets.only(top: 3, left: 10), child: Text('Bioyu düzenlemek için kuş tüyüne dokun.', style: TextStyle(fontSize: 9, color: Colors.white54))),
            ])),
          ]),
          const SizedBox(height: 13),
          Row(children: [_Stat('${widget.memories.length}', 'Anı'), _Stat('$locations', 'Yer'), _Stat('${widget.followers}', 'Takipçi'), _Stat('${widget.followingCount}', 'Takip'), _Stat('Sv. $level', 'XP $xp')]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: _saving ? null : (_editing ? _saveProfile : () => setState(() => _editing = true)),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5DEBFF), foregroundColor: const Color(0xFF061018)),
              icon: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded),
              label: Text(_editing ? (_saving ? 'Kaydediliyor...' : 'Kaydet') : 'Profili düzenle', style: const TextStyle(fontWeight: FontWeight.w900)),
            )),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _showProfileShareSheet(context, username),
              child: const Icon(Icons.tune_rounded),
            ),
          ]),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF5DEBFF).withValues(alpha: .16)), gradient: const LinearGradient(colors: [Color(0xFF0E202A), Color(0xFF101822)])), child: Row(children: [const Icon(Icons.auto_awesome_rounded, color: Color(0xFF5DEBFF), size: 19), const SizedBox(width: 10), Expanded(child: Text('$years yıl · ${widget.memories.length} anı · $locations konum', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), const Text('Ağacım', style: TextStyle(color: Color(0xFF5DEBFF), fontWeight: FontWeight.w900))])),
        ],
      ),
    );
  }

  static int _yearCount(List<Memory> memories) {
    if (memories.isEmpty) return 1;
    return memories.map((m) => m.createdAt.year).toSet().length;
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
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus(disposition: UnfocusDisposition.scope);
    Navigator.of(context).pop(<String, dynamic>{
      'bio': _bio.trim(),
      'font': _font,
      'color': _color,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = <int>[
      0xFFB9F7FF,
      0xFFFFFFFF,
      0xFF7BE7FF,
      0xFFB7FF9B,
      0xFFFFD36E,
      0xFFFF8FB3,
      0xFFD5B4FF,
    ];

    return Scaffold(
      appBar: AppBar(
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
              decoration: InputDecoration(
                hintText: 'Kendinden biraz bahset...',
                filled: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(Icons.edit_note_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Yazı tipi', style: TextStyle(fontWeight: FontWeight.w900)),
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
            const Text('Renk', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((c) {
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(c),
                      border: Border.all(
                        color: _color == c ? Colors.white : Colors.white24,
                        width: _color == c ? 3 : 1,
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
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Önizleme', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(
                    _bio.isEmpty ? 'BEN dünyam...' : _bio,
                    style: _previewStyle(),
                  ),
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: .48),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabHeader extends SliverPersistentHeaderDelegate {
  final TabController controller;
  _TabHeader(this.controller);

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Ağacım'),
          Tab(text: 'Rozetler'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeader oldDelegate) =>
      oldDelegate.controller != controller;
}

class _TreeTab extends StatefulWidget {
  final List<Memory> memories;
  const _TreeTab({required this.memories});

  @override
  State<_TreeTab> createState() => _TreeTabState();
}

class _TreeTabState extends State<_TreeTab> {
  final TransformationController _transform = TransformationController();
  double _scale = 1.0;
  bool _didInitialFit = false;

  @override
  void didUpdateWidget(covariant _TreeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.memories.map((m) => m.id).join('|');
    final newIds = widget.memories.map((m) => m.id).join('|');
    if (oldIds != newIds) {
      _didInitialFit = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _fitTree(Size viewport) {
    if (_didInitialFit || viewport.width <= 0 || viewport.height <= 0) return;
    final scale = math.min(
      (viewport.width - 24) / _TreeCanvas.size,
      (viewport.height - 24) / _TreeCanvas.size,
    ).clamp(.38, .72).toDouble();
    _didInitialFit = true;
    _scale = scale;
    final dx = (viewport.width - _TreeCanvas.size * scale) / 2;
    final dy = (viewport.height - _TreeCanvas.size * scale) / 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _transform.value = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(scale, scale, scale, 1);
    });
  }

  void _zoom(double delta) {
    final next = (_scale + delta).clamp(.65, 2.4).toDouble();
    setState(() => _scale = next);
    final center = _TreeCanvas.size / 2;
    _transform.value = Matrix4.identity()
      ..translateByDouble(center, center, 0, 1)
      ..scaleByDouble(next, next, next, 1)
      ..translateByDouble(-center, -center, 0, 1);
  }

  void _resetView() {
    setState(() => _scale = .55);
    final center = _TreeCanvas.size / 2;
    _transform.value = Matrix4.identity()
      ..translateByDouble(center, center, 0, 1)
      ..scaleByDouble(.55, .55, .55, 1)
      ..translateByDouble(-center, -center, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final permanent = widget.memories.where((m) => !m.isStory && !m.isExpired).toList();
    final nodes = _PentagonTreeLayout.build(permanent);
    final firstYear = permanent.isEmpty
        ? DateTime.now().year
        : permanent.map((m) => m.createdAt.year).reduce(math.min);
    final lastYear = permanent.isEmpty
        ? DateTime.now().year
        : permanent.map((m) => m.createdAt.year).reduce(math.max);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0C2822),
                      border: Border.all(color: const Color(0xFF5DEBFF).withValues(alpha: .35)),
                      boxShadow: [BoxShadow(color: const Color(0xFF4CFF9A).withValues(alpha: .12), blurRadius: 18)],
                    ),
                    child: const Icon(Icons.eco_rounded, color: Color(0xFF65F7A4), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${AuthService.currentUser?.username ?? 'Bican'}'ın Ağacı", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                        Text('Anılar büyüdükçe hayatın dallanır.', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .52))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF11232C), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .08))),
                    child: Text('$firstYear–$lastYear', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A2528), Color(0xFF061B19), Color(0xFF020908)]),
                  border: Border.all(color: const Color(0xFF5DEBFF).withValues(alpha: .12)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _fitTree(Size(constraints.maxWidth, constraints.maxHeight));
                    return InteractiveViewer(
                      transformationController: _transform,
                      minScale: .38,
                      maxScale: 2.4,
                      boundaryMargin: const EdgeInsets.all(220),
                      panEnabled: true,
                      scaleEnabled: true,
                      constrained: false,
                      child: SizedBox(
                    width: _TreeCanvas.size,
                    height: _TreeCanvas.size,
                    child: Stack(
                      children: [
                        SizedBox(width: _TreeCanvas.size, height: _TreeCanvas.size, child: CustomPaint(painter: _PentagonTreePainter(nodes: nodes))),
                        for (final node in nodes.where((n) => !n.anchor))
                          Positioned(
                            left: node.x - node.radius,
                            top: node.y - node.radius,
                            child: _PentagonMemoryNode(
                              node: node,
                              onTap: node.memory == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: node.memory!))),
                            ),
                          ),
                        Positioned(
                          left: _TreeCanvas.size / 2 - 100,
                          top: _TreeCanvas.size - 112,
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xCC06120F), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF68F5A1).withValues(alpha: .25))),
                            child: Row(children: [
                              const Icon(Icons.eco_rounded, color: Color(0xFF65F7A4), size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${permanent.length} kalıcı anı', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
                              Text('KÖK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: .45))),
                            ]),
                          ),
                        ),
                      ],
                    ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 82,
          child: Column(
            children: [
              _TreeControl(icon: Icons.add_rounded, onTap: () => _zoom(.18)),
              const SizedBox(height: 9),
              _TreeControl(icon: Icons.remove_rounded, onTap: () => _zoom(-.18)),
              const SizedBox(height: 9),
              _TreeControl(icon: Icons.my_location_rounded, onTap: _resetView),
            ],
          ),
        ),
      ],
    );
  }
}

class _TreeControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TreeControl({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6102025),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF5DEBFF).withValues(alpha: .65)), boxShadow: [BoxShadow(color: const Color(0xFF5DEBFF).withValues(alpha: .12), blurRadius: 15)]),
          child: Icon(icon, color: const Color(0xFFB9F7FF), size: 19),
        ),
      ),
    );
  }
}

class _TreeCanvas {
  static const double size = 1100;
}

class _PentagonTreeNode {
  final double x;
  final double y;
  final double radius;
  final Memory? memory;
  final bool root;
  final int level;
  final bool anchor;
  const _PentagonTreeNode({required this.x, required this.y, required this.radius, this.memory, this.root = false, this.level = 0, this.anchor = false});
}

class _PentagonTreeLayout {
  static List<_PentagonTreeNode> build(List<Memory> memories) {
    final nodes = <_PentagonTreeNode>[];
    const cx = _TreeCanvas.size / 2;
    const cy = _TreeCanvas.size - 250;
    if (memories.isEmpty) {
      nodes.add(const _PentagonTreeNode(x: cx, y: cy, radius: 92, root: true));
      return nodes;
    }

    final sorted = [...memories]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final rootMemory = sorted.removeLast();
    nodes.add(_PentagonTreeNode(x: cx, y: cy, radius: 92, root: true, memory: rootMemory));
    final groups = <String, List<Memory>>{};
    for (final m in sorted) {
      final key = '${m.createdAt.year}-${m.createdAt.month}-${m.createdAt.day}';
      groups.putIfAbsent(key, () => []).add(m);
    }

    final groupList = groups.entries.toList();
    final maxGroups = math.min(groupList.length, 14);
    for (var gi = 0; gi < maxGroups; gi++) {
      final group = groupList[gi];
      final ring = 170.0 + (gi % 3) * 118;
      final mainAngle = -math.pi / 2 + (gi * 0.63);
      final anchorX = cx + math.cos(mainAngle) * ring;
      final anchorY = cy + math.sin(mainAngle) * ring * .74;
      final list = group.value;
      final count = math.min(list.length, 5);
      nodes.add(_PentagonTreeNode(x: anchorX, y: anchorY, radius: 1, level: gi + 1, anchor: true));
      for (var i = 0; i < count; i++) {
        final angle = -math.pi / 2 + (i * math.pi * 2 / 5);
        final radius = 82.0;
        final x = anchorX + math.cos(angle) * radius;
        final y = anchorY + math.sin(angle) * radius;
        nodes.add(_PentagonTreeNode(x: x, y: y, radius: 29 + (i == 0 ? 7 : 0), memory: list[i], level: gi + 1));
      }
      if (count == 0) continue;
    }

    return nodes;
  }
}

class _PentagonMemoryNode extends StatelessWidget {
  final _PentagonTreeNode node;
  final VoidCallback? onTap;
  const _PentagonMemoryNode({required this.node, required this.onTap});

  ImageProvider? _image() {
    final file = node.memory?.photo;
    if (file != null && file.existsSync()) return FileImage(file);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image();
    final memory = node.memory;
    final border = memory == null ? const Color(0xFF68F5A1) : _categoryColor(memory);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: Duration(milliseconds: 420 + node.level * 55),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => GestureDetector(
        onTap: onTap,
        child: Transform.scale(scale: value, child: child),
      ),
      child: Container(
        width: node.radius * 2,
        height: node.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0B1918),
          border: Border.all(color: border, width: node.root ? 4 : 2.2),
          boxShadow: [BoxShadow(color: border.withValues(alpha: .45), blurRadius: node.root ? 30 : 18), BoxShadow(color: const Color(0xFF63F5A0).withValues(alpha: .12), blurRadius: 28)],
          image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
        ),
        child: image == null
            ? Icon(node.root ? Icons.eco_rounded : _iconForMemory(memory!.type), color: border, size: node.root ? 42 : 19)
            : null,
      ),
    );
  }

  IconData _iconForMemory(MemoryType type) {
    switch (type) {
      case MemoryType.photo:
        return Icons.photo_camera_rounded;
      case MemoryType.video:
        return Icons.videocam_rounded;
      case MemoryType.text:
        return Icons.notes_rounded;
      case MemoryType.music:
        return Icons.music_note_rounded;
      case MemoryType.location:
        return Icons.location_on_rounded;
    }
  }

  Color _categoryColor(Memory memory) {
    switch (memory.type) {
      case MemoryType.photo: return const Color(0xFF5DEBFF);
      case MemoryType.video: return const Color(0xFFBDA7FF);
      case MemoryType.text: return const Color(0xFFFFD36E);
      case MemoryType.music: return const Color(0xFFFF8FB3);
      case MemoryType.location: return const Color(0xFF72F5A2);
    }
  }
}

class _PentagonTreePainter extends CustomPainter {
  final List<_PentagonTreeNode> nodes;
  const _PentagonTreePainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = _TreeCanvas.size / 2;
    final rootY = _TreeCanvas.size - 250;
    final trunk = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 20..color = const Color(0xFFB68A52).withValues(alpha: .78);
    final trunkGlow = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 52..color = const Color(0xFF62F3A1).withValues(alpha: .055)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    final branch = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 5..color = const Color(0xFF72F5A2).withValues(alpha: .72);
    final branchGlow = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 20..color = const Color(0xFF62F3A1).withValues(alpha: .08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final trunkPath = Path()..moveTo(cx, rootY + 95)..cubicTo(cx - 55, rootY + 10, cx + 42, rootY - 150, cx, rootY - 310)..cubicTo(cx - 28, rootY - 430, cx + 25, rootY - 520, cx - 4, rootY - 610);
    canvas.drawPath(trunkPath, trunkGlow);
    canvas.drawPath(trunkPath, trunk);

    final anchors = nodes.where((n) => n.anchor).toList();
    final memories = nodes.where((n) => n.memory != null).toList();
    for (final anchor in anchors) {
      final rootAngle = math.atan2(anchor.y - rootY, anchor.x - cx);
      final sx = cx + math.cos(rootAngle) * 54;
      final sy = rootY + math.sin(rootAngle) * 62;
      final path = Path()..moveTo(sx, sy);
      final bend = (anchor.x - cx) * .22;
      path.cubicTo(cx + bend, rootY - 180 - anchor.level * 10, anchor.x - bend * .18, anchor.y + 100, anchor.x, anchor.y);
      canvas.drawPath(path, branchGlow);
      canvas.drawPath(path, branch);

      final cluster = memories.where((m) => (m.x - anchor.x).abs() < 90 && (m.y - anchor.y).abs() < 90 && m.level == anchor.level).toList();
      for (final n in cluster) {
        final p = Path()..moveTo(anchor.x, anchor.y)..lineTo(n.x, n.y);
        canvas.drawPath(p, branchGlow);
        canvas.drawPath(p, branch);
      }

      if (cluster.length >= 3) {
        final pent = Path();
        for (var i = 0; i < cluster.length; i++) {
          final n = cluster[i];
          if (i == 0) {
            pent.moveTo(n.x, n.y);
          } else {
            pent.lineTo(n.x, n.y);
          }
        }
        pent.close();
        final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFF8AFFB5).withValues(alpha: .16);
        canvas.drawPath(pent, ring);
      }
    }

    // Leaves and floating particles.
    final leaf = Paint()..color = const Color(0xFF69F5A4).withValues(alpha: .38);
    for (var i = 0; i < 34; i++) {
      final x = 80 + ((i * 137) % 930).toDouble();
      final y = 70 + ((i * 83) % 720).toDouble();
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i % 7) * .35);
      canvas.drawOval(const Rect.fromLTWH(-4, -9, 8, 18), leaf);
      canvas.restore();
    }

    final soil = Paint()..color = const Color(0xFF0B2018);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, rootY + 102), width: 430, height: 90), soil);
  }

  @override
  bool shouldRepaint(covariant _PentagonTreePainter oldDelegate) => oldDelegate.nodes != nodes;
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0E202A), Color(0xFF111A24)],
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF5DEBFF),
                child: Text(
                  '24',
                  style: TextStyle(
                    color: Color(0xFF061018),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seviye 24',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text('1.200 / 1.500 XP'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rozetlerim',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
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
                    color: const Color(0xFF0E202A),
                    border: Border.all(
                      color: const Color(0xFF5DEBFF).withValues(alpha: .65),
                    ),
                  ),
                  child: Icon(badge.$2, color: const Color(0xFF5DEBFF)),
                ),
                const SizedBox(height: 6),
                Text(
                  badge.$1,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
