class CommunityCommentReply {
  const CommunityCommentReply({
    required this.id,
    required this.commentId,
    required this.author,
    required this.school,
    required this.authorId,
    required this.timeAgo,
    required this.createdAt,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
  });

  final String id;
  final String commentId;
  final String author;
  final String school;
  final String authorId;
  final String timeAgo;
  final String createdAt;
  final String content;
  final int likesCount;
  final bool isLiked;
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.school,
    required this.authorId,
    required this.timeAgo,
    required this.createdAt,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String author;
  final String school;
  final String authorId;
  final String timeAgo;
  final String createdAt;
  final String content;
  final int likesCount;
  final bool isLiked;
  final List<CommunityCommentReply> replies;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.school,
    required this.authorId,
    required this.timeAgo,
    required this.createdAt,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.title,
    required this.content,
    this.mediaUri,
    this.mediaType,
    this.likesCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    this.comments = const [],
  });

  final String id;
  final String author;
  final String school;
  final String authorId;
  final String timeAgo;
  final String createdAt;
  final String tag;
  final String tagColor;
  final String tagBg;
  final String title;
  final String content;
  final String? mediaUri;
  final String? mediaType;
  final int likesCount;
  final bool isLiked;
  final bool isPinned;
  final List<CommunityComment> comments;
}

const Map<String, TagConfig> communityTagConfigs = {
  'SOP Suhu': TagConfig(label: 'SOP Suhu', color: '#B45309', bg: '#FEF3C7'),
  'Rekap Presensi': TagConfig(label: 'Rekap Presensi', color: '#15803D', bg: '#DCFCE7'),
  'Menu Alergi': TagConfig(label: 'Menu Alergi', color: '#7C3AED', bg: '#F3E8FF'),
  'Pindai AI': TagConfig(label: 'Pindai AI', color: '#2563EB', bg: '#DBEAFE'),
  'Distribusi': TagConfig(label: 'Distribusi', color: '#D97706', bg: '#FEF3C7'),
  'Kebersihan': TagConfig(label: 'Kebersihan', color: '#0D9488', bg: '#CCFBF1'),
};

class TagConfig {
  const TagConfig({required this.label, required this.color, required this.bg});
  final String label;
  final String color;
  final String bg;
}

const List<String> availableTags = [
  'SOP Suhu',
  'Rekap Presensi',
  'Menu Alergi',
  'Pindai AI',
  'Distribusi',
  'Kebersihan',
];
