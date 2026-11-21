import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

class CreateTextMemoryScreen
    extends StatefulWidget {
  const CreateTextMemoryScreen({
    super.key,
  });

  @override
  State<CreateTextMemoryScreen> createState() =>
      _CreateTextMemoryScreenState();
}

class _CreateTextMemoryScreenState
    extends State<CreateTextMemoryScreen> {
  final TextEditingController _controller =
      TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text =
        _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(
            'Önce bir şeyler yazmalısın.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Yazı anısı',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: TextButton(
              onPressed: _save,
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  color: BenTokens.gold,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          22,
          18,
          22,
          24,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical:
                TextAlignVertical.top,
            decoration:
                InputDecoration(
              hintText:
                  'Bu anıyı yaz...',
              hintStyle: TextStyle(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: .38),
                fontSize: 19,
              ),
              border:
                  InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 19,
              height: 1.55,
              color:
                  theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}