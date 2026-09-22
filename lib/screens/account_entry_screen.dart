import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_tokens.dart';
import '../services/auth_service.dart';
import '../widgets/ben_logo.dart';

class AccountEntryScreen extends StatefulWidget {
  final Future<void> Function(BenUser user) onAuthenticated;
  const AccountEntryScreen({super.key, required this.onAuthenticated});

  @override
  State<AccountEntryScreen> createState() => _AccountEntryScreenState();
}

class _AccountEntryScreenState extends State<AccountEntryScreen> {
  bool _showForm = false;
  bool _register = false;
  bool _busy = false;

  final _auth = AuthService(ApiClient());
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _username = '';

  void _openForm({required bool register}) {
    if (_busy) return;
    setState(() {
      _register = register;
      _showForm = true;
      _email = '';
      _password = '';
      _username = '';
    });
  }

  void _closeForm() {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _showForm = false);
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);

    try {
      final user = _register
          ? await _auth.register(
              username: _username.trim(),
              email: _email.trim(),
              password: _password,
            )
          : await _auth.login(
              email: _email.trim(),
              password: _password,
            );

      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus(disposition: UnfocusDisposition.scope);
      // TextFormField'ın dahili controller/focus ağacı, ana ekranla değişmeden önce
      // güvenli biçimde ayrılsın. Bu, _dependents.isEmpty / controller disposed
      // kırmızı ekranlarının oluşmasını engeller.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      await widget.onAuthenticated(user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: _showForm
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _closeForm,
              ),
              title: Text(
                _register ? 'Üye Ol' : 'Giriş Yap',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: SafeArea(
        child: _showForm ? _form() : _entry(),
      ),
    );
  }

  Widget _entry() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
        child: Column(
          children: [
            const BENLogo(size: 108),
            const SizedBox(height: 18),
            const Text('BEN', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('İnsan • Zaman • Yer • Anı', style: TextStyle(color: Colors.white.withValues(alpha: .62), fontWeight: FontWeight.w600)),
            const SizedBox(height: 34),
            _EntryCard(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Üye Ol / Kayıt Aç',
              subtitle: 'Gerçek BEN hesabını oluştur.',
              onTap: () => _openForm(register: true),
            ),
            const SizedBox(height: 12),
            _EntryCard(
              icon: Icons.login_rounded,
              title: 'Giriş Yap',
              subtitle: 'Mevcut hesabınla devam et.',
              onTap: () => _openForm(register: false),
            ),
            const SizedBox(height: 24),
            Text(
              'BEN’e katılmak için hesap oluştur veya mevcut hesabınla giriş et.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final title = _register ? "BEN'e katıl" : "BEN'e giriş yap";
    final subtitle = _register ? 'Gerçek BEN hesabını oluştur.' : 'Hesabınla BEN dünyasına dön.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            if (_register) ...[
              TextFormField(
                onChanged: (value) => _username = value,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Kullanıcı adı', prefixIcon: Icon(Icons.alternate_email_rounded)),
                validator: (v) => (v == null || v.trim().length < 3) ? 'En az 3 karakter' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              onChanged: (value) => _email = value,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta gir' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (value) => _password = value,
              obscureText: true,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock_outline_rounded)),
              validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_register ? Icons.person_add_alt_1_rounded : Icons.login_rounded),
                label: Text(_busy ? 'Bağlanıyor...' : _register ? 'Üye ol' : 'Giriş yap'),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: BenTokens.cyan, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Bilgilerin BEN hesabında saklanır.', style: TextStyle(color: Colors.white.withValues(alpha: .48), fontSize: 11))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF151C2A),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(width: 50, height: 50, decoration: const BoxDecoration(color: BenTokens.gold, shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF0E1014), size: 25)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              ],
            ),
          ),
        ),
      );
}
