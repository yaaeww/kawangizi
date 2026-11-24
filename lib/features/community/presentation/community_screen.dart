import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart'
    show AuthController;
import 'package:kawangizi_mobile/shared/widgets/delete_confirmation_dialog.dart';
import 'package:kawangizi_mobile/shared/widgets/feature_header.dart';
import '../domain/community_models.dart'
    show CommunityPost, communityTagConfigs, TagConfig;
import 'community_controller.dart'
    show CommunityController;
import 'create_post_sheet.dart'
    show CreatePostSheet;

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
  final ScrollController _scrollController = ScrollController();

  static const _filterTags = [
    'Semua',
    'SOP Suhu',
    'Rekap Presensi',
    'Menu Alergi',
    'Pindai AI',
    'Distribusi',
    'Kebersihan',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<CommunityController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<CommunityController>().refresh();
  }

  List<CommunityPost> _filterPosts(List<CommunityPost> posts) {
    var filtered = posts;
    if (_selectedTag != 'Semua') {
      filtered = filtered.where((p) => p.tag == _selectedTag).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.content.toLowerCase().contains(q) ||
            p.author.toLowerCase().contains(q) ||
            p.school.toLowerCase().contains(q);
      }).toList();
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
    final displayPosts = _filterPosts(controller.posts);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top App Bar Header (Exact Title: "Komunitas")
                FeatureHeader(
                  title: 'Komunitas',
                  onOpenProfile: () => context.go('/profile'),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // Header section: Banner, Search bar, Tag chips
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Banner Card (Exact Expo Design: White Card + Badges + Amber Button)
                                _buildBannerCard(),

                                const SizedBox(height: 14),

                                // 2. Search Bar
                                _buildSearchBox(),

                                const SizedBox(height: 12),

                                // 3. Filter Tag Chips
                                _buildFilterChips(),

                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),

                        // Posts List
                        if (controller.loading && displayPosts.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                          )
                        else if (displayPosts.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildEmptyState(),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final post = displayPosts[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _PostCard(
                                    post: post,
                                    currentUserId: auth.user?.id,
                                    onTap: () => context.go('/community/thread/${post.id}'),
                                    onLike: () => context.read<CommunityController>().toggleLikePost(post.id),
                                    onEdit: () => _handleEditPost(post),
                                    onDelete: () => _handleDeletePost(post),
                                  ),
                                );
                              },
                              childCount: displayPosts.length,
                            ),
                          ),

                        if (controller.loadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                          ),

                        // Bottom padding to ensure content scrolls above floating nav bar
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 120),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sheets / Dialogs
          if (_isCreateModalOpen)
            CreatePostSheet(
              onClose: () => setState(() => _isCreateModalOpen = false),
              onSubmit: () => setState(() => _isCreateModalOpen = false),
              editingPost: null,
            ),
          if (_editingPost != null)
            CreatePostSheet(
              onClose: () => setState(() => _editingPost = null),
              onSubmit: () => setState(() => _editingPost = null),
              editingPost: _editingPost,
            ),
          if (_isDeleteModalVisible && _postToDelete != null)
            DeleteConfirmationDialog(
              title: 'Hapus Diskusi',
              message: 'Apakah Anda yakin ingin menghapus postingan "${_postToDelete!.title}"?',
              onConfirm: _confirmDelete,
              onCancel: () => setState(() => _isDeleteModalVisible = false),
              isDeleting: _isDeleting,
            ),
        ],
      ),
    );
  }

  // Banner Card matching Expo 1:1
  Widget _buildBannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, size: 13, color: Color(0xFFD97706)),
                    SizedBox(width: 5),
                    Text(
                      'Forum Guru Validator MBG',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 13, color: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text(
                      '148 Sekolah Terverifikasi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          const Text(
            'Ruang Kolaborasi & Tanya Jawab SOP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Text(
            'Berbagi praktik baik, tips penanganan boks makanan, dan solusi kendala distribusi bersama sesama guru validator.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Action Button: Mulai Diskusi Baru
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _handleCreatePost,
              icon: const Icon(LucideIcons.plusCircle, size: 18, color: Colors.white),
              label: const Text(
                'Mulai Diskusi Baru',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Search Box matching Expo
  Widget _buildSearchBox() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Cari topik diskusi atau nama sekolah...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filter Chips matching Expo
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tag = _filterTags[i];
          final isActive = tag == _selectedTag;
          return InkWell(
            onTap: () => setState(() => _selectedTag = tag),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.messageSquare, size: 36, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada diskusi ditemukan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada diskusi yang cocok dengan "$_searchQuery".'
                : 'Belum ada topik diskusi untuk kategori ini. Jadilah yang pertama memulai!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _handleCreatePost,
            icon: const Icon(LucideIcons.plusCircle, size: 16, color: Colors.white),
            label: const Text('Buat Diskusi Sekarang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// Post Card matching Expo React Native 1:1
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
    final isAuthor = currentUserId == post.authorId ||
        (post.author.contains('Siti Aminah') && (currentUserId == null || currentUserId == 'u-guru-01'));
    final tagCfg = communityTagConfigs[post.tag] ??
        TagConfig(label: post.tag, color: '#D97706', bg: '#FEF3C7');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pinned Banner
              if (post.isPinned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.pin, size: 12, color: Color(0xFFD97706)),
                      SizedBox(width: 5),
                      Text(
                        'Disematkan oleh Fasilitator BGN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Author Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          post.school,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  // Tag & Author Actions (Edit, Delete)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(int.parse(tagCfg.bg.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tagCfg.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(int.parse(tagCfg.color.replaceFirst('#', '0xFF'))),
                          ),
                        ),
                      ),
                      if (isAuthor) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(LucideIcons.edit3, size: 13, color: Color(0xFFD97706)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(LucideIcons.trash2, size: 13, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),

              // Snippet
              Text(
                post.content,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Media Thumbnail (if any)
              if (post.mediaUri != null && post.mediaUri!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        post.mediaUri!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.image, size: 11, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Foto Menu',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Footer Meta Row
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 5),
                  Text(
                    post.timeAgo,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  ),
                  const Spacer(),
                  // Like Button
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 15,
                            color: post.isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: post.isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Comment Count
                  Row(
                    children: [
                      const Icon(LucideIcons.messageSquare, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${post.comments.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
