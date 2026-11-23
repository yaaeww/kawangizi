import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/features/auth/domain/backend_user.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart' show AuthController;
import '../domain/community_models.dart' show CommunityPost, availableTags, communityTagConfigs;
import '../presentation/community_controller.dart' show CommunityController;

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({
    super.key,
    required this.onClose,
    required this.onSubmit,
    this.editingPost,
  });

  final VoidCallback onClose;
  final VoidCallback onSubmit;
  final CommunityPost? editingPost;

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedTag = availableTags[0];
  String? _mediaUri;
  String _mediaType = 'image';
  bool _submitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.editingPost != null) {
      _titleController.text = widget.editingPost!.title;
      _contentController.text = widget.editingPost!.content;
      _selectedTag = widget.editingPost!.tag;
      _mediaUri = widget.editingPost!.mediaUri;
      _mediaType = widget.editingPost!.mediaType ?? 'image';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.editingPost != null;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                  Text(isEditing ? 'Edit Diskusi' : 'Buat Diskusi Baru', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 22), onPressed: widget.onClose),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                controller: ScrollController(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag selector
                    const Text('Tag', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableTags.map((tag) {
                        final cfg = communityTagConfigs[tag]!;
                        final selected = tag == _selectedTag;
                        return ChoiceChip(
                          label: Text(cfg.label, style: TextStyle(color: selected ? Colors.white : Color(int.parse(cfg.color.replaceFirst('#', '0xFF'))), fontWeight: FontWeight.w600, fontSize: 12)),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedTag = tag),
                          selectedColor: Color(int.parse(cfg.color.replaceFirst('#', '0xFF'))),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: selected ? Color(int.parse(cfg.color.replaceFirst('#', '0xFF'))) : AppColors.border),
                          labelStyle: TextStyle(color: selected ? Colors.white : Color(int.parse(cfg.color.replaceFirst('#', '0xFF'))), fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    const Text('Judul', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: 'Judul diskusi', hintStyle: TextStyle(color: AppColors.textMuted), border: OutlineInputBorder()),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),
                    // Content
                    const Text('Konten', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(hintText: 'Tulis konten diskusi...', hintStyle: TextStyle(color: AppColors.textMuted), border: OutlineInputBorder(), alignLabelWithHint: true),
                      maxLines: 6,
                      minLines: 4,
                    ),
                    const SizedBox(height: 16),
                    // Media (placeholder)
                    const Text('Media (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.image, size: 20),
                      label: _mediaUri == null ? const Text('Tambah Foto/Video') : Text('Media: ${_mediaUri!.split('/').last}'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMsg!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.text,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(isEditing ? 'Simpan Perubahan' : 'Terbitkan', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Judul dan konten wajib diisi.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    try {
      final controller = context.read<CommunityController>();
      final auth = context.read<AuthController>();
      if (auth.user == null) throw Exception('User not authenticated');

      if (isEditing) {
        await controller.updatePost(
          id: widget.editingPost!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tag: _selectedTag,
          mediaUri: _mediaUri,
          mediaType: _mediaType,
        );
      } else {
        await controller.createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tag: _selectedTag,
          mediaUri: _mediaUri,
          mediaType: _mediaType,
          user: auth.user!,
        );
      }
      if (!mounted) return;
      widget.onSubmit();
      widget.onClose();
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
