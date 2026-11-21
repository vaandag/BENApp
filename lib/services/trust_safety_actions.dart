import 'package:flutter/material.dart';

import '../core/network/api_client.dart';

class TrustSafetyActions {
  static const _reasons = <String, String>{
    'spam': 'Spam veya yanıltıcı içerik',
    'harassment': 'Taciz veya zorbalık',
    'hate': 'Nefret söylemi',
    'nudity': 'Çıplaklık veya cinsel içerik',
    'violence': 'Şiddet veya tehlikeli içerik',
    'self_harm': 'Kendine zarar verme',
    'false_information': 'Yanlış bilgi',
    'copyright': 'Telif hakkı ihlali',
    'other': 'Diğer',
  };

  static Future<void> report(
    BuildContext context, {
    required String targetType,
    required int targetId,
  }) async {
    if (targetId <= 0) return;
    var reason = 'other';
    final details = TextEditingController();
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Şikâyet et'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Bu içeriği neden bildiriyorsun?'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: reason,
                  isExpanded: true,
                  items: _reasons.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => reason = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: details,
                  maxLength: 2000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'İstersen ayrıntı ekle (isteğe bağlı)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, reason),
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) {
      details.dispose();
      return;
    }
    try {
      await ApiClient().post('reports', body: {
        'target_type': targetType,
        'target_id': targetId,
        'reason': selected,
        'details': details.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şikâyetin alındı. Teşekkür ederiz.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şikâyet gönderilemedi: $error')),
        );
      }
    } finally {
      details.dispose();
    }
  }

  static Future<void> block(
    BuildContext context, {
    required int userId,
    required String username,
  }) async {
    if (userId <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kullanıcıyı engelle?'),
        content: Text(
          '@$username engellendiğinde karşılıklı takip kaldırılır ve içerikleri akışında gösterilmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ApiClient().post('users/$userId/block');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('@$username engellendi.')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Engelleme başarısız: $error')),
        );
      }
    }
  }
}
