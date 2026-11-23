import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/core/utils/relative_time.dart';
import 'package:kawangizi_mobile/features/auth/domain/backend_user.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart' show AuthController;
import '../domain/community_models.dart' show CommunityPost, CommunityComment, CommunityCommentReply, communityTagConfigs;
import '../presentation/community_controller.dart' show CommunityController;
import 'create_post_sheet.dart' show CreatePostSheet;

class ThreadDetailScreen extends StatefulWidget {
  const ThreadDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  CommunityComment? _replyingTo;
  bool _isSubmitting = false;
  bool _isEditModalOpen = false;
  bool _isDeleteModalVisible = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  CommunityPost? _getPost(CommunityController controller) {
    return controller.posts.where((p) => p.id == widget.postId).firstOrNull;
  }

  Future<void> _handleDeletePost(CommunityController controller) async {
    setState(() => _isDeleting = true);
    try {
      await controller.deletePost(widget.postId);
      if (mounted) context.go('/community');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _handleSubmitComment(CommunityController controller, BackendUser user) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (_replyingTo != null) {
        await controller.addReply(widget.postId, _replyingTo!.id, text, user);
      } else {
        await controller.addComment(widget.postId, text, user);
      }
      _commentController.clear();
      setState(() => _replyingTo = null);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _startReplying(CommunityComment comment) {
    setState(() => _replyingTo = comment);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _handleDeletePostConfirm(CommunityController controller) {
    setState(() => _isDeleting = true);
    controller.deletePost(widget.postId).then((_) {
      if (mounted) context.go('/community');
    });
  }

  void _handleEditPost(CommunityPost post) {
    // Open edit modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostSheet(editingPost: _getPost(context.read<CommunityController>())!),
    );
  }

  void _handleDeletePost(CommunityController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Diskusi'),
        content: const Text('Apakah Anda yakin ingin menghapus diskusi ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: () => _handleDeletePostConfirm(controller), child: const Text('Hapus')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CommunityController>();
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final post = _getPost(controller);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diskusi')),
        body: const Center(child: Text('Diskusi tidak ditemukan')),
      );
    }

    final currentUserId = auth.user?.id;
    final isOwner = currentUserId == post.authorId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Diskusi'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: isOwner
            ? [
                IconButton(icon: const Icon(LucideIcons.edit2), onPressed: () => _handleEditPost(post)),
                IconButton(icon: const Icon(LucideIcons.trash2), onPressed: () => _handleDeletePost(context.read<CommunityController>())),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {},
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post header
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 18, backgroundColor: AppColors.primarySoft, child: Text(getInitials(post.author), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 13))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                                    Text('${post.school} • ${post.timeAgo}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (post.isPinned) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)), child: const Text('PIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Color(int.parse(communityTagConfigs[post.tag]!.bg.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(8)),
                            child: Text(communityTagConfigs[post.tag]!.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(int.parse(communityTagConfigs[post.tag]!.color.replaceFirst('#', '0xFF'))))),
                          ),
                          const SizedBox(height: 8),
                          Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 4),
                          Text(post.content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                          if (post.mediaUri != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(post.mediaUri!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _ThreadActionButton(icon: post.isLiked ? LucideIcons.heart : LucideIcons.heart, count: post.likesCount, active: post.isLiked, onTap: () => context.read<CommunityController>().toggleLikePost(post.id)),
                              const SizedBox(width: 16),
                              _ThreadActionButton(icon: LucideIcons.messageSquare, count: post.comments.length, active: false, onTap: () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Comments
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Komentar (${post.comments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: post.comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _CommentTile(
                        comment: post.comments[i],
                        postId: widget.postId,
                        currentUserId: context.read<AuthController>().user?.id,
                        onReply: _startReplying,
                        onLike: () => context.read<CommunityController>().toggleLikeComment(widget.postId, post.comments[i].id),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          // Comment input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      onSubmitted: (_) => _handleSubmitComment(context.read<CommunityController>(), context.read<AuthController>().user!),
                      decoration: InputDecoration(
                        hintText: _replyingTo != null ? 'Balas ke ${_replyingTo!.author}...' : 'Tulis komentar...',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: _replyingTo != null
                            ? IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => setState(() => _replyingTo = null))
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSubmitting ? null : () => _handleSubmitComment(context.read<CommunityController>(), context.read<AuthController>().user!),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadActionButton extends StatelessWidget {
  const _ThreadActionButton({required this.icon, required this.count, required this.active, required this.onTap});
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.postId,
    required this.currentUserId,
    required this.onReply,
    required this.onLike,
  });

  final CommunityComment comment;
  final String postId;
  final String? currentUserId;
  final ValueChanged<CommunityComment> onReply;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId == comment.authorId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: AppColors.primarySoft, child: Text(getInitials(comment.author), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 11))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.author, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                    Text('${comment.school} • ${comment.timeAgo}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {},
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'reply', child: Row(children: [Icon(LucideIcons.reply, size: 18), SizedBox(width: 8), Text('Balas')])),
                  if (isOwner) const PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, size: 18, color: AppColors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppColors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.content, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              _CommentAction(icon: comment.isLiked ? LucideIcons.heart : LucideIcons.heart, count: comment.likesCount, active: comment.isLiked, onTap: () => context.read<CommunityController>().toggleLikeComment(postId, comment.id)),
              const SizedBox(width: 16),
              _CommentAction(icon: LucideIcons.reply, count: comment.replies.length, active: false, onTap: () => onReply(comment)),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.replies.map((r) => _ReplyTile(reply: r, postId: postId, onLike: () => context.read<CommunityController>().toggleLikeComment(postId, comment.id))),
          ],
        ],
      );
    }
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply, required this.postId, required this.onLike});
  final CommunityCommentReply reply;
  final String postId;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 48, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: AppColors.primarySoft, child: Text(getInitials(reply.author), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 10))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(reply.author, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)), Text('${reply.school} • ${reply.timeAgo}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary))])),
            ],
          ),
          const SizedBox(height: 4),
          Text(reply.content, style: const TextStyle(fontSize: 12, color: AppColors.text)),
          const SizedBox(height: 4),
          _CommentAction(icon: reply.isLiked ? LucideIcons.heart : LucideIcons.heart, count: reply.likesCount, active: reply.isLiked, onTap: onLike),
        ],
      );
    }
  }
}

class _CommentAction extends StatelessWidget {
  const _CommentAction({required this.icon, required this.count, required this.active, required this.onTap});
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
