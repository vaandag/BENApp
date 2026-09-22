import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor:
          const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFAFAF8),
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
                  color: Color(0xFF172033),
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
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade200,
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
                    Colors.grey.shade400,
                fontSize: 19,
              ),
              border:
                  InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 19,
              height: 1.55,
              color:
                  Color(0xFF172033),
            ),
          ),
        ),
      ),
    );
  }
}