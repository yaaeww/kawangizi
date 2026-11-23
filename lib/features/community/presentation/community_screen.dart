import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/core/utils/relative_time.dart';
import 'package:kawangizi_mobile/features/auth/domain/backend_user.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart'
    show AuthController;
import '../domain/community_models.dart'
    show CommunityPost, CommunityComment, availableTags, communityTagConfigs;
import 'community_controller.dart'
    show CommunityController;
import 'thread_detail_screen.dart'
    show ThreadDetailScreen;
import 'create_post_sheet.dart'
    show CreatePostSheet;
import 'contextual_ai_chat_sheet.dart'
    show ContextualAiChatSheet;

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedTag = 'Semua';
  String _searchQuery = '';
  bool _isCreateModalOpen = false;
  CommunityPost? _editingPost;
  bool _isDeleteModalVisible = false;
  CommunityPost? _postToDelete;
  bool _isDeleting = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isRefreshing = false;

  static const _pageSize = 10;
  static const _filterTags = ['Semua', 'SOP Suhu', 'Rekap Presensi', 'Menu Alergi', 'Pindai AI', 'Distribusi', 'Kebersihan'];

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _isRefreshing = true;
      });
    } else if (!_hasMoreData || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    // Simulate pagination delay
    await Future.delayed(const Duration(milliseconds: 300));

    final controller = context.read<CommunityController>();
    final allPosts = controller.posts;
    final filtered = _filterPosts(allPosts);
    final total = filtered.length;
    final start = (refresh ? 0 : _currentPage - 1) * 10;
    final end = (start + 10).clamp(0, total);

    if (refresh) {
      // In a real app, you'd fetch from server. Here we just use local data.
    }

    setState(() {
      _currentPage = refresh ? 1 : _currentPage + 1;
      _hasMoreData = end < total;
      _isLoadingMore = false;
      _isRefreshing = false;
    });
  }

  List<CommunityPost> _filterPosts(List<CommunityPost> posts) {
    var filtered = posts;
    if (_selectedTag != 'Semua') {
      filtered = filtered.where((p) => p.tag == _selectedTag).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => p.title.toLowerCase().contains(q) || p.content.toLowerCase().contains(q)).toList();
    }
    return filtered;
  }

  void _handleCreatePost() => setState(() => _isCreateModalOpen = true);
  void _handleEditPost(CommunityPost post) => setState(() => _editingPost = post);
  void _handleDeletePost(CommunityPost post) {
    setState(() {
      _postToDelete = post;
      _isDeleteModalVisible = true;
    });
  }

  Future<void> _confirmDelete() async {
    if (_postToDelete == null || _isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      await context.read<CommunityController>().deletePost(_postToDelete!.id);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleteModalVisible = false;
          _isDeleting = false;
          _postToDelete = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<CommunityController>();
    final user = auth.user;

    final filteredPosts = _filterPosts(controller.posts);
    final displayPosts = filteredPosts.take(_currentPage * 10).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FeatureHeader(
              title: 'Komunitas',
              onOpenProfile: () => context.go('/profile'),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadMore(refresh: true),
                child: CustomScrollView(
                  slivers: [
                    // Filter tags
                    SliverToBoxAdapter(
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filterTags.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final tag = _filterTags[i];
                            final selected = tag == _selectedTag;
                            return FilterChip(
                              label: Text(tag, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedTag = tag),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            );
                          },
                        ),
                      ),
                    ),
                    // Search
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Cari diskusi...',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    // Create button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleCreatePost,
                            icon: const Icon(LucideIcons.plus, size: 20),
                            label: const Text('Buat Diskusi Baru'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Posts list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= displayPosts.length) {
                            if (_hasMoreData && !_isLoadingMore) {
                              Future.microtask(_loadMore);
                              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                            }
                            return const SizedBox.shrink();
                          }
                          final post = displayPosts[index];
                          return _PostCard(
                            post: post,
                            currentUserId: auth.user?.id,
                            onTap: () => context.go('/community/thread/${post.id}'),
                            onLike: () => context.read<CommunityController>().toggleLikePost(post.id),
                            onEdit: () => setState(() => _editingPost = displayPosts[index]),
                            onDelete: () => _handleDeletePost(displayPosts[index]),
                          );
                        },
                        childCount: displayPosts.length + (_hasMoreData ? 1 : 0),
                      ),
                    ),
                    if (_isLoadingMore)
                      const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Modals
      child: Stack(
        children: [
          if (_isCreateModalOpen) CreatePostSheet(onClose: () => setState(() => _isCreateModalOpen = false), onSubmit: () => setState(() => _isCreateModalOpen = false), editingPost: null),
          if (_editingPost != null) CreatePostSheet(onClose: () => setState(() => _editingPost = null), onSubmit: () => setState(() => _editingPost = null), editingPost: _editingPost),
          if (_isDeleteModalVisible) _DeleteConfirmationModal(post: _postToDelete!, onConfirm: _confirmDelete, onCancel: () => setState(() => _isDeleteModalVisible = false), isDeleting: _isDeleting),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onTap,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  final CommunityPost post;
  final String? currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId == post.authorId;
    final tagCfg = communityTagConfigs[post.tag] ?? _TagConfig(label: post.tag, color: '#2563EB', bg: '#DBEAFE');

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(getInitials(post.author), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
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
                  if (post.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                      child: const Text('PIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Color(int.parse(tagCfg.bg.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  tagCfg.label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(int.parse(tagCfg.color.replaceFirst('#', '0xFF')))),
                ),
              ),
              const SizedBox(height: 8),
              Text(post.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 4),
              Text(post.content, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              if (post.mediaUri != null) ...[
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(post.mediaUri!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionIcon(icon: post.isLiked ? LucideIcons.heart : LucideIcons.heart, count: post.likesCount, active: post.isLiked, onTap: () => context.read<CommunityController>().toggleLikePost(post.id)),
                  const SizedBox(width: 16),
                  _ActionIcon(icon: LucideIcons.messageSquare, count: post.comments.length, active: false, onTap: () {}),
                  const Spacer(),
                  if (post.isPinned) ...[
                    _ActionIcon(icon: LucideIcons.flag, count: 0, active: true, onTap: () {}),
                    const SizedBox(width: 8),
                  ],
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        // handled by parent
                      } else if (value == 'delete') {
                        // handled by parent
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(LucideIcons.edit2, size: 18), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, size: 18, color: AppColors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppColors.red))])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.count, required this.active, required this.onTap});
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
