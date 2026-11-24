import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:kawangizi_mobile/core/network/api_client.dart';
import 'package:kawangizi_mobile/core/storage/local_store.dart';
import 'package:kawangizi_mobile/features/community/domain/community_models.dart';
import 'package:kawangizi_mobile/features/community/data/community_seed.dart';

class ForumRepository {
  ForumRepository({
    ApiClient? api,
    required LocalStore localStore,
  })  : _api = api,
        _localStore = localStore;

  final ApiClient? _api;
  final LocalStore _localStore;

  static const _forumKey = 'forum_posts';
  static const _legacyKey = '@kawangizi_community_posts';

  /// Mengambil daftar postingan dengan dukungan paginasi (default 10 item per page)
  Future<List<CommunityPost>> getPosts({
    int page = 1,
    int limit = 10,
    String? tag,
    String? search,
  }) async {
    // 1. Coba ambil data riil dari backend VPS
    if (_api != null) {
      try {
        final queryParams = <String, dynamic>{
          'page': page,
          'limit': limit,
        };
        if (tag != null && tag.isNotEmpty && tag != 'Semua') {
          queryParams['tag'] = tag;
        }
        if (search != null && search.trim().isNotEmpty) {
          queryParams['search'] = search.trim();
        }

        final res = await _api.get('/api/v1/posts', query: queryParams);
        final body = res.data;
        if (body is Map && body['data'] != null) {
          final dataObj = body['data'];
          final List postList = dataObj is Map && dataObj['posts'] is List
              ? dataObj['posts']
              : (dataObj is List ? dataObj : []);

          final posts = postList
              .map((e) => _postFromJson(Map<String, dynamic>.from(e as Map)))
              .toList();

          if (posts.isNotEmpty) {
            if (page == 1) {
              await savePosts(posts);
            }
            return posts;
          }
        }
      } catch (err) {
        debugPrint('[ForumRepository] Error fetching posts from VPS: $err. Falling back to local cache.');
      }
    }

    // 2. Fallback ke penyimpanan lokal / cache
    try {
      var raw = await _localStore.getString(_forumKey);
      raw ??= await _localStore.getString(_legacyKey);

      if (raw != null && raw.isNotEmpty) {
        final parsed = jsonDecode(raw) as List;
        if (parsed.isNotEmpty) {
          return parsed.map((e) => _postFromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (_) {
      // fallback to seed
    }

    // Inisialisasi dengan seed jika kosong
    await savePosts(CommunitySeed.posts);
    return CommunitySeed.posts;
  }

  Future<void> savePosts(List<CommunityPost> posts) async {
    final raw = jsonEncode(posts.map(_postToJson).toList());
    await _localStore.setString(_forumKey, raw);
    await _localStore.setString(_legacyKey, raw);
  }

  /// Membuat postingan baru ke backend VPS dan sinkronisasi ke storage lokal
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
    final tagCfg = communityTagConfigs[tag] ??
        const TagConfig(label: 'Umum', color: '#2563EB', bg: '#DBEAFE');

    CommunityPost newPost = CommunityPost(
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

    if (_api != null) {
      try {
        final res = await _api.post('/api/v1/posts', data: {
          'title': title.trim(),
          'content': content.trim(),
          'tag': tag,
          'mediaUri': mediaUri ?? '',
          'mediaType': mediaType ?? 'image',
        });
        if (res.data is Map && res.data['data'] is Map) {
          newPost = _postFromJson(Map<String, dynamic>.from(res.data['data']));
        }
      } catch (err) {
        debugPrint('[ForumRepository] Error creating post on VPS: $err');
      }
    }

    // Update local cache
    final localPosts = await getPosts();
    final updated = [newPost, ...localPosts.where((p) => p.id != newPost.id)];
    await savePosts(updated);
    return newPost;
  }

  /// Memperbarui postingan di server VPS dan cache lokal
  Future<CommunityPost> updatePost({
    required String id,
    required String title,
    required String content,
    required String tag,
    String? mediaUri,
    String? mediaType,
  }) async {
    final cfg = communityTagConfigs[tag] ??
        const TagConfig(label: 'Umum', color: '#10B981', bg: '#D1FAE5');

    if (_api != null) {
      try {
        await _api.put('/api/v1/posts/$id', data: {
          'title': title,
          'content': content,
          'tag': tag,
          if (mediaUri != null) 'mediaUri': mediaUri,
          if (mediaType != null) 'mediaType': mediaType,
        });
      } catch (err) {
        debugPrint('[ForumRepository] Error updating post on VPS: $err');
      }
    }

    final posts = await getPosts();
    final existing = posts.firstWhere(
      (p) => p.id == id,
      orElse: () => CommunityPost(
        id: id,
        author: 'User',
        school: '',
        authorId: '',
        timeAgo: 'Baru saja',
        createdAt: DateTime.now().toIso8601String(),
        tag: tag,
        tagColor: cfg.color,
        tagBg: cfg.bg,
        title: title,
        content: content,
        likesCount: 0,
        isLiked: false,
        comments: [],
      ),
    );

    final updatedPost = CommunityPost(
      id: existing.id,
      author: existing.author,
      school: existing.school,
      authorId: existing.authorId,
      timeAgo: existing.timeAgo,
      createdAt: existing.createdAt,
      tag: tag,
      tagColor: cfg.color,
      tagBg: cfg.bg,
      title: title,
      content: content,
      mediaUri: mediaUri ?? existing.mediaUri,
      mediaType: mediaType ?? existing.mediaType,
      likesCount: existing.likesCount,
      isLiked: existing.isLiked,
      isPinned: existing.isPinned,
      comments: existing.comments,
    );

    final updatedList = posts.map((p) => p.id == id ? updatedPost : p).toList();
    await savePosts(updatedList);
    return updatedPost;
  }

  /// Menghapus postingan di server VPS dan cache lokal
  Future<void> deletePost(String postId) async {
    if (_api != null) {
      try {
        await _api.delete('/api/v1/posts/$postId');
      } catch (err) {
        debugPrint('[ForumRepository] Error deleting post on VPS: $err');
      }
    }

    final posts = await getPosts();
    final updated = posts.where((p) => p.id != postId).toList();
    await savePosts(updated);
  }

  /// Suka / Batal Suka postingan di backend VPS
  Future<void> toggleLikePost(String postId) async {
    if (_api != null) {
      try {
        await _api.post('/api/v1/posts/$postId/like');
      } catch (err) {
        debugPrint('[ForumRepository] Error toggling like on VPS: $err');
      }
    }

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

  /// Menambahkan komentar baru
  Future<void> addComment(
    String postId,
    String content,
    String author,
    String school,
    String authorId, {
    String? parentId,
  }) async {
    if (content.trim().isEmpty) return;

    if (_api != null) {
      try {
        await _api.post('/api/v1/posts/$postId/comments', data: {
          'content': content.trim(),
          if (parentId != null) 'parentId': parentId,
        });
      } catch (err) {
        debugPrint('[ForumRepository] Error adding comment to VPS: $err');
      }
    }

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

    final posts = await getPosts();
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

  /// Menambahkan balasan berjenjang (nested comment reply)
  Future<void> addReply(
    String postId,
    String commentId,
    String content,
    String author,
    String school,
    String authorId,
  ) async {
    await addComment(postId, content, author, school, authorId, parentId: commentId);
  }

  CommunityPost _postFromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Pengguna',
      school: json['school']?.toString() ?? 'Sekolah',
      authorId: json['authorId']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? 'Baru saja',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      tag: json['tag']?.toString() ?? 'Umum',
      tagColor: json['tagColor']?.toString() ?? '#2563EB',
      tagBg: json['tagBg']?.toString() ?? '#DBEAFE',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      mediaUri: json['mediaUri']?.toString(),
      mediaType: json['mediaType']?.toString() ?? 'image',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      comments: (json['comments'] as List?)
              ?.map((c) => _commentFromJson(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [],
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
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Pengguna',
      school: json['school']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? 'Baru saja',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      content: json['content']?.toString() ?? '',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      replies: (json['replies'] as List?)
              ?.map((r) => _replyFromJson(Map<String, dynamic>.from(r as Map)))
              .toList() ??
          [],
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
      id: json['id']?.toString() ?? '',
      commentId: json['commentId']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Pengguna',
      school: json['school']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? 'Baru saja',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      content: json['content']?.toString() ?? '',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
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
