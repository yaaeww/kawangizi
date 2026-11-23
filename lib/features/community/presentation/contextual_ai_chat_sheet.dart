import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';

class ContextualAiChatSheet extends StatefulWidget {
  const ContextualAiChatSheet({super.key});

  @override
  State<ContextualAiChatSheet> createState() => _ContextualAiChatSheetState();
}

class _ContextualAiChatSheetState extends State<ContextualAiChatSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(text: 'Halo! Saya asisten KawanGizi. Ada yang bisa saya bantu terkait hasil scan ini?', isUser: false),
  ];
  bool _isTyping = false;

  static const _quickPrompts = [
    'Jelaskan skor kesegaran ini',
    'Apa artinya status waspada?',
    'Bagaimana rekomendasi untuk menu ini?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _inputController.clear();
      _isTyping = true;
    });
    _scrollToBottom();
    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final response = _generateResponse(_messages.last.text);
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  String _generateResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('skor') || lower.contains('kesegaran')) {
      return 'Skor kesegaran dihitung dari deteksi visual YOLOv8 dan data suhu. Skor ≥95 = Layak, 80-94 = Waspada, <80 = Ditolak. Skor Anda menunjukkan kondisi yang baik.';
    }
    if (lower.contains('waspada') || lower.contains('status')) {
      return 'Status Waspada berarti makanan masih aman dikonsumsi namun harus segera dibagikan. Jangan ditahan lama. Pastikan suhu holding ≥60°C dan sisa waktu aman >45 menit.';
    }
    if (lower.contains('rekomendasi') || lower.contains('menu')) {
      return 'Rekomendasi: Setujui porsi dan lanjutkan distribusi ke kelas. Pastikan BAST ditandatangani sebelum jam aman habis.';
    }
    return 'Saya asisten berbasis aturan. Untuk pertanyaan teknis detail, silakan hubungi tim teknis KawanGizi.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Asisten AI KawanGizi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 22), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Quick prompts
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(_quickPrompts[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () => _handleQuickPrompt(_quickPrompts[i]),
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
              ),
            ),
            // Typing indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    SizedBox(width: 40, child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.border)),
                  ],
                ),
              ),
            // Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan ke AI...',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sendMessage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(LucideIcons.send, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickPrompt(String prompt) {
    _inputController.text = prompt;
    _sendMessage();
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final boolean isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
          ),
        ),
        child: Text(message.text, style: TextStyle(color: message.isUser ? Colors.white : AppColors.text, fontSize: 14)),
      ),
    );
  }
}
