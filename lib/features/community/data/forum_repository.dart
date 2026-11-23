import 'dart:convert';

import 'package:kawangizi_mobile/features/community/domain/community_models.dart';
import 'package:kawangizi_mobile/features/community/data/community_seed.dart';

class ForumRepository {
  ForumRepository({required LocalStore localStore}) : _localStore = localStore;

  final LocalStore _localStore;

  static const _forumKey = 'forum_posts';
  static const _legacyKey = '@kawangizi_community_posts';

  Future<List<CommunityPost>> getPosts() async {
    try {
      var raw = await _localStore.getString(_forumKey);
      if (raw == null) raw = await _localStore.getString(_legacyKey);

      if (raw != null && raw.isNotEmpty) {
        final parsed = jsonDecode(raw) as List;
        if (parsed.isNotEmpty) {
          return parsed.map((e) => _postFromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (_) {
      // fallback to seed
    }

    // Initialize with seed
    await savePosts(CommunitySeed.posts);
    return CommunitySeed.posts;
  }

  Future<void> savePosts(List<CommunityPost> posts) async {
    final raw = jsonEncode(posts.map(_postToJson).toList());
    await _localStore.setString(_forumKey, raw);
    await _localStore.setString(_legacyKey, raw);
  }

  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String tag,
    String? mediaUri,
    String? mediaType,
    required String author,
    required String school,
    required String authorId,
  }) async {
    final posts = await getPosts();
    final tagCfg = communityTagConfigs[tag] ?? _TagConfig(label: tag, color: '#2563EB', bg: '#DBEAFE');

    final newPost = CommunityPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      author: author,
      school: school,
      authorId: authorId,
      timeAgo: 'Baru saja',
      createdAt: DateTime.now().toIso8601String(),
      tag: tag,
      tagColor: tagCfg.color,
      tagBg: tagCfg.bg,
      title: title.trim(),
      content: content.trim(),
      mediaUri: mediaUri,
      mediaType: mediaType ?? 'image',
      likesCount: 0,
      isLiked: false,
      comments: [],
    );

    final updated = [newPost, ...posts];
    await savePosts(updated);
    return newPost;
  }

  Future<CommunityPost> updatePost({
    required String id,
    required String title,
    required String content,
    required String tag,
    String? mediaUri,
    String? mediaType,
  }) async {
    final posts = await getPosts();
    final tagCfg = communityTagConfigs[tag] ?? _TagConfig(label: tag, color: '#2563EB', bg: '#DBEAFE');

    CommunityPost? updatedPost;
    final updated = posts.map((post) {
      if (post.id == id) {
        updatedPost = CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: tag,
          tagColor: tagCfg.color,
          tagBg: tagCfg.bg,
          title: title.trim(),
          content: content.trim(),
          mediaUri: mediaUri ?? post.mediaUri,
          mediaType: mediaType ?? post.mediaType,
          likesCount: post.likesCount,
          isLiked: post.isLiked,
          isPinned: post.isPinned,
          comments: post.comments,
        );
        return updatedPost!;
      }
      return post;
    }).toList();

    if (updatedPost == null) throw Exception('Postingan tidak ditemukan');
    await savePosts(updated);
    return updatedPost!;
  }

  Future<void> deletePost(String postId) async {
    final posts = await getPosts();
    final updated = posts.where((p) => p.id != postId).toList();
    await savePosts(updated);
  }

  Future<void> toggleLikePost(String postId) async {
    final posts = await getPosts();
    final updated = posts.map((post) {
      if (post.id == postId) {
        final liked = !post.isLiked;
        return CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: post.tag,
          tagColor: post.tagColor,
          tagBg: post.tagBg,
          title: post.title,
          content: post.content,
          mediaUri: post.mediaUri,
          mediaType: post.mediaType,
          likesCount: post.likesCount + (liked ? 1 : -1),
          isLiked: liked,
          isPinned: post.isPinned,
          comments: post.comments,
        );
      }
      return post;
    }).toList();
    await savePosts(updated);
  }

  Future<void> addComment(String postId, String content, String author, String school, String authorId) async {
    if (content.trim().isEmpty) return;
    final posts = await getPosts();
    final newComment = CommunityComment(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      author: author,
      school: school,
      authorId: authorId,
      timeAgo: 'Baru saja',
      createdAt: DateTime.now().toIso8601String(),
      content: content.trim(),
      likesCount: 0,
      isLiked: false,
      replies: [],
    );

    final updated = posts.map((post) {
      if (post.id == postId) {
        return CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: post.tag,
          tagColor: post.tagColor,
          tagBg: post.tagBg,
          title: post.title,
          content: post.content,
          mediaUri: post.mediaUri,
          mediaType: post.mediaType,
          likesCount: post.likesCount,
          isLiked: post.isLiked,
          isPinned: post.isPinned,
          comments: [...post.comments, newComment],
        );
      }
      return post;
    }).toList();

    await savePosts(updated);
  }

  Future<void> addReply(String postId, String commentId, String content, String author, String school, String authorId) async {
    if (content.trim().isEmpty) return;
    final posts = await getPosts();
    final newReply = CommunityCommentReply(
      id: 'r-${DateTime.now().millisecondsSinceEpoch}',
      commentId: commentId,
      author: author,
      school: school,
      authorId: authorId,
      timeAgo: 'Baru saja',
      createdAt: DateTime.now().toIso8601String(),
      content: content.trim(),
      likesCount: 0,
      isLiked: false,
    );

    final updated = posts.map((post) {
      if (post.id == postId) {
        final updatedComments = post.comments.map((comment) {
          if (comment.id == commentId) {
            return CommunityComment(
              id: comment.id,
              postId: comment.postId,
              author: comment.author,
              school: comment.school,
              authorId: comment.authorId,
              timeAgo: comment.timeAgo,
              createdAt: comment.createdAt,
              content: comment.content,
              likesCount: comment.likesCount,
              isLiked: comment.isLiked,
              replies: [...comment.replies, newReply],
            );
          }
          return comment;
        }).toList();
        return CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: post.tag,
          tagColor: post.tagColor,
          tagBg: post.tagBg,
          title: post.title,
          content: post.content,
          mediaUri: post.mediaUri,
          mediaType: post.mediaType,
          likesCount: post.likesCount,
          isLiked: post.isLiked,
          isPinned: post.isPinned,
          comments: updatedComments,
        );
      }
      return post;
    }).toList();

    await savePosts(updated);
  }

  CommunityPost _postFromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      author: json['author'] as String,
      school: json['school'] as String,
      authorId: json['authorId'] as String,
      timeAgo: json['timeAgo'] as String,
      createdAt: json['createdAt'] as String,
      tag: json['tag'] as String,
      tagColor: json['tagColor'] as String,
      tagBg: json['tagBg'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      mediaUri: json['mediaUri'] as String?,
      mediaType: json['mediaType'] as String?,
      likesCount: json['likesCount'] as int,
      isLiked: json['isLiked'] as bool,
      isPinned: json['isPinned'] as bool? ?? false,
      comments: (json['comments'] as List).map((c) => _commentFromJson(Map<String, dynamic>.from(c))).toList(),
    );
  }

  Map<String, dynamic> _postToJson(CommunityPost post) {
    return {
      'id': post.id,
      'author': post.author,
      'school': post.school,
      'authorId': post.authorId,
      'timeAgo': post.timeAgo,
      'createdAt': post.createdAt,
      'tag': post.tag,
      'tagColor': post.tagColor,
      'tagBg': post.tagBg,
      'title': post.title,
      'content': post.content,
      'mediaUri': post.mediaUri,
      'mediaType': post.mediaType,
      'likesCount': post.likesCount,
      'isLiked': post.isLiked,
      'isPinned': post.isPinned,
      'comments': post.comments.map(_commentToJson).toList(),
    };
  }

  CommunityComment _commentFromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      author: json['author'] as String,
      school: json['school'] as String,
      authorId: json['authorId'] as String,
      timeAgo: json['timeAgo'] as String,
      createdAt: json['createdAt'] as String,
      content: json['content'] as String,
      likesCount: json['likesCount'] as int,
      isLiked: json['isLiked'] as bool,
      replies: (json['replies'] as List).map((r) => _replyFromJson(Map<String, dynamic>.from(r))).toList(),
    );
  }

  Map<String, dynamic> _commentToJson(CommunityComment comment) {
    return {
      'id': comment.id,
      'postId': comment.postId,
      'author': comment.author,
      'school': comment.school,
      'authorId': comment.authorId,
      'timeAgo': comment.timeAgo,
      'createdAt': comment.createdAt,
      'content': comment.content,
      'likesCount': comment.likesCount,
      'isLiked': comment.isLiked,
      'replies': comment.replies.map(_replyToJson).toList(),
    };
  }

  CommunityCommentReply _replyFromJson(Map<String, dynamic> json) {
    return CommunityCommentReply(
      id: json['id'] as String,
      commentId: json['commentId'] as String,
      author: json['author'] as String,
      school: json['school'] as String,
      authorId: json['authorId'] as String,
      timeAgo: json['timeAgo'] as String,
      createdAt: json['createdAt'] as String,
      content: json['content'] as String,
      likesCount: json['likesCount'] as int,
      isLiked: json['isLiked'] as bool,
    );
  }

  Map<String, dynamic> _replyToJson(CommunityCommentReply reply) {
    return {
      'id': reply.id,
      'commentId': reply.commentId,
      'author': reply.author,
      'school': reply.school,
      'authorId': reply.authorId,
      'timeAgo': reply.timeAgo,
      'createdAt': reply.createdAt,
      'content': reply.content,
      'likesCount': reply.likesCount,
      'isLiked': reply.isLiked,
    };
  }
}
